# Tekton CI — Durable Black-Box CI Stack

A lean Tekton setup on bare Kubernetes with durable metadata and log storage.
Run a pipeline, delete everything, and still query the full history.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Kubernetes Cluster                     │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  tekton-pipelines namespace                          │   │
│  │                                                      │   │
│  │  tekton-pipelines-controller  ──► runs pipelines     │   │
│  │  tekton-pipelines-webhook     ──► validates objects  │   │
│  │  tekton-dashboard             ──► web UI             │   │
│  │  tekton-results-api           ──► archives metadata  │   │
│  │  tekton-results-watcher       ──► watches runs       │   │
│  │  tekton-results-postgres-0    ──► stores metadata    │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  logging namespace                                   │   │
│  │                                                      │   │
│  │  loki-0        ──► stores pod logs (31 days)         │   │
│  │  promtail-*    ──► tails /var/log/pods on each node  │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                             │
│  Pipeline pods run in: default namespace                    │
│  Logs flow:  pod → promtail → loki                          │
│  Metadata:   TaskRun/PipelineRun → tekton-results → postgres│
└─────────────────────────────────────────────────────────────┘
```

---

## What's installed

| Component            | Version   | Purpose                              |
|----------------------|-----------|--------------------------------------|
| Tekton Pipelines     | v1.12.0   | CI/CD engine (LTS until 2027-05-04)  |
| Tekton Dashboard     | v0.67.0   | Web UI for runs                      |
| Tekton Results       | v0.18.0   | Archives run metadata to PostgreSQL  |
| PostgreSQL           | bundled   | Durable metadata store               |
| Grafana Loki         | 3.0.0     | Durable log storage (31 day default) |
| Promtail             | 3.0.0     | DaemonSet log collector              |

---

## Prerequisites

- `kubectl` configured against your cluster
- A default StorageClass (kind, k3s, GKE, EKS all provide one)
- `openssl` installed locally

---

## Install

```bash
git clone <this-repo> && cd tekton-ci
chmod +x deploy.sh scripts/*.sh
./deploy.sh
```

Takes ~3 minutes on a fresh cluster.

---

## Usage

### Run a pipeline

```bash
scripts/run-pipeline.sh my-run-001

# With custom params:
scripts/run-pipeline.sh my-run-002 https://github.com/myorg/myapp main myapp
```

Watch it complete in the terminal. Metadata is written to PostgreSQL and
logs are shipped to Loki in real time as each step runs.

### Delete everything from the cluster

```bash
scripts/teardown.sh my-run-001
```

This removes the PipelineRun, pods, and PVCs.
**Nothing is lost** — metadata and logs are already in durable storage.

### Query from durable storage

```bash
# List all stored runs
scripts/query-run.sh --list

# Full report: metadata + logs
scripts/query-run.sh my-run-001

# Metadata only (PostgreSQL)
scripts/query-run.sh my-run-001 --meta

# Logs only (Loki)
scripts/query-run.sh my-run-001 --logs
```

---

## File layout

```
tekton-ci/
├── deploy.sh                         # Full stack installer
├── manifests/
│   ├── 00-namespaces.yaml
│   ├── loki/
│   │   └── loki.yaml                 # ConfigMap + PVC + StatefulSet + Services
│   └── promtail/
│       └── promtail.yaml             # RBAC + ConfigMap + DaemonSet
├── pipeline/
│   └── sample-pipeline.yaml          # Tasks + Pipeline + example PipelineRun
└── scripts/
    ├── run-pipeline.sh               # Trigger a named run and watch it
    ├── teardown.sh                   # Delete run + pods + PVCs cleanly
    └── query-run.sh                  # Query postgres + loki for any past run
```

---

## Querying manually

### PostgreSQL — run metadata

```bash
kubectl exec -it -n tekton-pipelines tekton-results-postgres-0 -- \
  env PGPASSWORD=tekton-results-secret \
  psql -U tekton -d tekton-results

# Inside psql:
\dt

SELECT name, type, created_time
FROM records
ORDER BY created_time DESC
LIMIT 20;

SELECT name, created_time FROM results ORDER BY created_time DESC LIMIT 10;

\q
```

### Loki — step logs

```bash
# Port-forward Loki
kubectl port-forward svc/loki 3100:3100 -n logging &

# Query by pipeline run name
curl -s "http://localhost:3100/loki/api/v1/query_range" \
  --data-urlencode 'query={pipelinerun="my-run-001"}' \
  --data-urlencode 'limit=200' \
  | python3 -c "
import sys,json,datetime
d=json.load(sys.stdin)
for s in d['data']['result']:
  print(f\"--- {s['stream'].get('pod','?')} / {s['stream'].get('container','?')} ---\")
  for ts,line in s['values']:
    t=datetime.datetime.utcfromtimestamp(int(ts)/1e9).strftime('%H:%M:%S')
    print(f'  {t}  {line}')
"
```

---

## Tekton Dashboard

```bash
kubectl port-forward svc/tekton-dashboard 9097:9097 -n tekton-pipelines
# → http://localhost:9097
```

---

## Lessons learned (bugs fixed vs naive setup)

| # | Issue | Fix |
|---|-------|-----|
| 1 | `gcr.io` returns 403 pulling Tekton images | Images moved to `ghcr.io` — use `infra.tekton.dev` release URLs |
| 2 | `storage.googleapis.com` returns 404 for v1.x releases | New release URL: `infra.tekton.dev/tekton-releases/...` |
| 3 | Tekton Results: `secret "tekton-results-postgres" not found` | Results hardcodes this name in `tekton-pipelines` ns — created by `deploy.sh` |
| 4 | Loki crashes: `invalid compactor config` | Add `delete_request_store: filesystem` when `retention_enabled: true` |
| 5 | Promtail stuck `0/1 Running`, readiness probe times out | Set `readOnlyRootFilesystem: false` — `true` blocks port 9080 binding |
| 6 | Loki returns HTTP 400, drops all Tekton logs | Tekton pods exceed default 15-label limit — set `max_label_names_per_series: 30` |
| 7 | postgres auth fails: `database "tekton_results" does not exist` | Actual DB name uses a hyphen: `tekton-results` |
| 8 | postgres auth fails for user `result` or `postgres` | Bundled credentials: user=`tekton` pass=`tekton-results-secret` db=`tekton-results` |

---

## Adjusting log retention

Edit `manifests/loki/loki.yaml`, find `limits_config`, change `retention_period`:

```yaml
limits_config:
  retention_period: 744h   # 31 days — change to e.g. 2160h for 90 days
```

Then apply:
```bash
kubectl apply -f manifests/loki/loki.yaml
kubectl rollout restart statefulset/loki -n logging
```


ginger-infra install-tekton-crd \
  --image gingersociety/remote-task-controller:latest \
  --executor-url https://api.gingersociety.org/external-executor/run-job \
  --runner-image gingersociety/external-executor-runner:latest


