#!/bin/bash
set -euo pipefail

# Quick test for GHC installation with fixed version loading
# Usage: ./scripts/test-ghc-install.sh

VERSION=$(cat VERSION | tr -d '\n')
LOCAL_TAG="test/ghc-install"

echo "🔍 Testing GHC installation (version: $VERSION)"
echo ""

# Build just the GHC installation part
echo "🏗️  Building GHC installation test..."
sudo docker build \
    --file build_context/Dockerfile.haskell \
    --build-arg VERSION="$VERSION" \
    --build-arg BASE_IMAGE="test/haskell-tex-dev-base:latest" \
    --target stage-0 \
    --tag "${LOCAL_TAG}:test" \
    . 2>&1 | tee /tmp/ghc-install-test.log

echo ""
echo "📋 Test log saved to: /tmp/ghc-install-test.log"

# Check if build succeeded and test the container
if sudo docker images | grep -q "${LOCAL_TAG}:test"; then
    echo "✅ Build succeeded, testing GHC version..."
    
    # Check GHC version
    sudo docker run --rm "${LOCAL_TAG}:test" bash -c "
        echo '=== GHC Version ==='
        ghc --version
        echo ''
        echo '=== GHCup List ==='
        ghcup list -t ghc | grep '✔'
        echo ''
        echo '=== Expected Version ==='
        echo 'Expected: 9.12.2'
    "
    
    echo "🧹 Cleaning up test image..."
    sudo docker rmi "${LOCAL_TAG}:test" > /dev/null 2>&1 || true
else
    echo "❌ Build failed"
    echo "📋 Check /tmp/ghc-install-test.log for details"
fi

echo ""
echo "🔍 Test complete!"
