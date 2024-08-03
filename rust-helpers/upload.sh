#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Function to display usage information
usage() {
  echo "Usage: $0"
  exit 1
}

# Extract version from Cargo.toml
VERSION=$(grep '^version' Cargo.toml | awk -F '= ' '{print $2}' | tr -d '"')
NAME=$(grep '^name' Cargo.toml | awk -F '= ' '{print $2}' | tr -d '"')


if [ -z "$VERSION" ]; then
  echo "Version not found in Cargo.toml."
  exit 1
fi

# Load environment variables from .env file
export $(grep -v '^#' .env | xargs)

# Check if necessary environment variables are set
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ] || [ -z "$AWS_DEFAULT_REGION" ]; then
  echo "AWS environment variables are not set."
  exit 1
fi

# Define the S3 bucket path
S3_BUCKET_PATH="s3://${NAME}-binaries/$VERSION"

# Check if the bin directory exists
if [ ! -d "bin" ]; then
  echo "bin directory does not exist in the current working directory."
  exit 1
fi

# Upload the contents of the bin folder to the specified S3 bucket path, excluding .DS_Store files
aws s3 cp bin/ $S3_BUCKET_PATH/ --recursive --exclude "*.DS_Store"

echo "Upload to $S3_BUCKET_PATH completed successfully."
