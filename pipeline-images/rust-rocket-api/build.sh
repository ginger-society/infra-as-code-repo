#!/bin/bash

docker build . -t gingersociety/rust-rocket-api-builder -f Dockerfile.builder --platform=linux/amd64

docker push gingersociety/rust-rocket-api-builder

docker build . -t gingersociety/rust-rocket-api-runner -f Dockerfile.runner --platform=linux/amd64

docker push gingersociety/rust-rocket-api-runner