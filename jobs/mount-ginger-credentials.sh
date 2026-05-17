#!/bin/bash
set -e

# Restore ginger-society auth for ginger-connector
mkdir -p ~/.ginger-society
cp /workspace/creds/ginger-society/auth.json ~/.ginger-society/auth.json