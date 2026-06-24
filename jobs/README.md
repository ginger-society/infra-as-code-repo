



docker build -t gingersociety/tekton-task-ginger:latest --platform=linux/amd64 -f ginger.Dockerfile .
docker push gingersociety/tekton-task-ginger:latest


docker build -t gingersociety/tekton-task-buildah:latest --platform=linux/amd64 -f enhanced-buildah.Dockerfile . --no-cache
docker push gingersociety/tekton-task-buildah:latest

docker build -t gingersociety/tekton-task-gitter:latest --platform=linux/amd64 -f gitter.Dockerfile .
docker push gingersociety/tekton-task-gitter:latest


docker build -t gingersociety/enhanced-rust-builder:latest --platform=linux/amd64 -f enhanced-rust-builder.Dockerfile .
docker push gingersociety/enhanced-rust-builder:latest


docker build -t gingersociety/enhanced-node-builder:latest --platform=linux/amd64 -f enhanced-node-builder.Dockerfile .
docker push gingersociety/enhanced-node-builder:latest




