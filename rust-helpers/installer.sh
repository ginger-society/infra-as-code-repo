#!/bin/bash

# Check if both arguments (binary name and version) are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <binary_name> <version>"
    exit 1
fi

# Binary name and version from arguments
binary_name=$1
version=$2

# Function to detect the operating system
detect_os() {
    case "$(uname -s)" in
        Darwin)
            echo "apple-darwin"
            ;;
        Linux)
            echo "unknown-linux-gnu"
            ;;
        CYGWIN*|MINGW32*|MSYS*|MINGW*)
            echo "pc-windows-gnu"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Function to detect CPU architecture
detect_arch() {
    case "$(uname -m)" in
        x86_64)
            echo "x86_64"
            ;;
        arm64)
            echo "aarch64"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Detect the architecture and OS
arch=$(detect_arch)
os=$(detect_os)

# Check for unsupported configurations
if [ "$arch" == "unknown" ] || [ "$os" == "unknown" ]; then
    echo "Unsupported system: arch=$arch, os=$os"
    exit 1
fi

# Format the URL
url="https://$binary_name-binaries.s3.ap-south-1.amazonaws.com/$version/$arch-$os/$binary_name"

# Output the formatted URL
echo "Download URL: $url"

# Set the destination directory based on the OS
case "$os" in
    "apple-darwin")
        dest_dir="/usr/local/bin"
        ;;
    "unknown-linux-gnu")
        dest_dir="/usr/local/bin"
        ;;
    "pc-windows-gnu")
        dest_dir="/c/Program Files"
        ;;
    *)
        echo "Unsupported operating system."
        exit 1
        ;;
esac

# Check if the destination directory exists and is writable
if [ ! -d "$dest_dir" ] || [ ! -w "$dest_dir" ]; then
    echo "Destination directory $dest_dir is not writable or does not exist."
    exit 1
fi

# Download the binary using curl or wget
echo "Downloading the binary..."
curl -L "$url" -o "$dest_dir/$binary_name" --fail

# Make the binary executable (skip this for Windows)
if [ "$os" != "pc-windows-gnu" ]; then
    chmod +x "$dest_dir/$binary_name"
fi

# Confirm download and installation
if [ -f "$dest_dir/$binary_name" ]; then
    echo "Binary successfully downloaded and installed to $dest_dir/$binary_name"
else
    echo "Failed to download the binary."
    exit 1
fi
