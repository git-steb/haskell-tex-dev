#!/bin/bash
set -euo pipefail

# Quick test for GHC installation with fixed version loading
# Usage: ./scripts/test-ghc-install.sh

VERSION=$(cat VERSION | tr -d '\n')
GHC_EXPECT=$(grep '^GHC_VERSION=' build_context/versions.env | cut -d= -f2)
LOCAL_TAG="test/ghc-install"

echo "🔍 Testing GHC installation (image VERSION=$VERSION, expected GHC=$GHC_EXPECT)"
echo ""

# Requires a local base image tag (build Dockerfile.base first) or pass BASE_IMAGE
BASE_IMG="${BASE_IMAGE:-test/haskell-tex-dev-base:latest}"
echo "🏗️  Building Haskell layer (BASE_IMAGE=$BASE_IMG)..."
sudo docker build \
    --file build_context/Dockerfile.haskell \
    --build-arg VERSION="$VERSION" \
    --build-arg BASE_IMAGE="$BASE_IMG" \
    --tag "${LOCAL_TAG}:test" \
    . 2>&1 | tee /tmp/ghc-install-test.log

echo ""
echo "📋 Test log saved to: /tmp/ghc-install-test.log"

# Check if build succeeded and test the container
if sudo docker images | grep -q "${LOCAL_TAG}:test"; then
    echo "✅ Build succeeded, testing GHC version..."
    
    # Check GHC version
    sudo docker run --rm -e "GHC_EXPECT=${GHC_EXPECT}" "${LOCAL_TAG}:test" bash -c '
        echo "=== GHC Version ==="
        ghc --version
        echo ""
        echo "=== GHCup List ==="
        ghcup list -t ghc | grep "✔"
        echo ""
        echo "=== Expected Version ==="
        echo "Expected: ${GHC_EXPECT}"
    '
    
    echo "🧹 Cleaning up test image..."
    sudo docker rmi "${LOCAL_TAG}:test" > /dev/null 2>&1 || true
else
    echo "❌ Build failed"
    echo "📋 Check /tmp/ghc-install-test.log for details"
fi

echo ""
echo "🔍 Test complete!"
