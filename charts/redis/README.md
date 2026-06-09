# Redis Helm Chart

## Install

```bash
helm install my-redis . \
  --set redis.auth.password=mypass
```

## Get the secret

```bash
kubectl get secret my-redis-redis-auth -o yaml
```

## Get the Redis URL (for apps)

```bash
kubectl get secret my-redis-redis-auth -o jsonpath="{.data.url}" | base64 -d
```
