#!/bin/bash
set -euo pipefail

# Compute content hash based on build_context folder
# This represents the actual build inputs that affect image content

if [[ ! -d "build_context" ]]; then
    echo "error: build_context directory not found" >&2
    exit 1
fi

# Compute hash of all files in build_context (sorted for consistency)
CONTENT_HASH=$(find build_context -type f -exec sha256sum {} \; | sort | sha256sum | head -c 8)

echo "$CONTENT_HASH"
