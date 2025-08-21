#!/bin/bash
set -euo pipefail

# Quick local build test
# Usage: ./scripts/test-build.sh

VERSION=$(cat VERSION | tr -d '\n')
LOCAL_TAG="test/haskell-tex-dev"

echo "🧪 Quick local build test (version: $VERSION)"
echo ""

# Test base layer only (fastest test)
echo "🏗️  Testing base layer build..."
if sudo docker build \
    --file build_context/Dockerfile.base \
    --build-arg VERSION="$VERSION" \
    --tag "${LOCAL_TAG}:base-test" \
    . > /tmp/base-build.log 2>&1; then
    echo "✅ Base layer build successful"
    
    # Test that unzip and unzstd are available
    echo "🔍 Testing required tools..."
    if sudo docker run --rm "${LOCAL_TAG}:base-test" unzip -v > /dev/null 2>&1; then
        echo "✅ unzip is available"
    else
        echo "❌ unzip is missing"
        exit 1
    fi
    
    if sudo docker run --rm "${LOCAL_TAG}:base-test" unzstd -V > /dev/null 2>&1; then
        echo "✅ unzstd is available"
    else
        echo "❌ unzstd is missing"
        exit 1
    fi
    
    echo "🧹 Cleaning up test image..."
    sudo docker rmi "${LOCAL_TAG}:base-test" > /dev/null 2>&1 || true
    
else
    echo "❌ Base layer build failed"
    echo "📋 Build log:"
    cat /tmp/base-build.log
    exit 1
fi

echo ""
echo "🎉 Base layer test passed! Ready for full build."
