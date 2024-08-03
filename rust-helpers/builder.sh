#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Delete the bin directory if it exists
if [ -d "bin" ]; then
    echo "Deleting existing bin directory..."
    rm -rf bin
fi

# The name of the executable to build
# Extract the executable name from Cargo.toml
executable_name=$(grep '^name' Cargo.toml | awk -F '= ' '{print $2}' | tr -d '"')

if [ -z "$executable_name" ]; then
    echo "Please provide the executable name as the first argument."
    exit 1
fi

# List of all target platforms
targets=(
    "x86_64-apple-darwin"
    "x86_64-unknown-linux-gnu"
    "x86_64-pc-windows-gnu"
    "aarch64-unknown-linux-gnu"
    "aarch64-apple-darwin"
)

# Function to build for a specific target
build_target() {
    local target=$1
    echo "Building for $target..."

    local output_name="$executable_name"
    if [ "$target" == "x86_64-pc-windows-gnu" ]; then
        output_name="$executable_name.exe"
    fi

    case "$target" in
        "x86_64-unknown-linux-gnu")
            docker run --rm --platform linux/amd64 -v "$(pwd)":/workspace -w /workspace gingersociety/rust-cli-builder \
                bash -c "cargo build --release --target $target && \
                mkdir -p ./bin/$target && \
                cp target/$target/release/$output_name ./bin/$target/"
            ;;
        "x86_64-pc-windows-gnu"|"aarch64-unknown-linux-gnu")
            docker run --rm --platform linux/arm64 -v "$(pwd)":/workspace -w /workspace gingersociety/rust-cli-builder \
                bash -c "cargo build --release --target $target && \
                mkdir -p ./bin/$target && \
                cp target/$target/release/$output_name ./bin/$target/"
            ;;
        "aarch64-apple-darwin"|"x86_64-apple-darwin")
            cargo build --release --target "$target"
            mkdir -p "./bin/$target"
            cp "target/$target/release/$output_name" "./bin/$target/"
            ;;
        *)
            echo "Unsupported target: $target"
            exit 1
            ;;
    esac
}

# Loop over all targets and build
for target in "${targets[@]}"; do
    build_target "$target"
done
