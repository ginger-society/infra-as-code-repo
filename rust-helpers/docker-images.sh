# Run this on M series macbooks

docker build -t gingersociety/rust-cli-builder:latest-arm64 --platform=linux/arm64 .
docker push gingersociety/rust-cli-builder:latest-arm64

docker build -t gingersociety/rust-cli-builder:latest-amd64 --platform=linux/amd64 .
docker push gingersociety/rust-cli-builder:latest-amd64




docker manifest create --amend gingersociety/rust-cli-builder:latest \
    gingersociety/rust-cli-builder:latest-amd64 \
    gingersociety/rust-cli-builder:latest-arm64

docker manifest push gingersociety/rust-cli-builder:latest