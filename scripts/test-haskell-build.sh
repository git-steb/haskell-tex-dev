#!/bin/bash
set -euo pipefail

# Test Haskell layer build locally
# Usage: ./scripts/test-haskell-build.sh

VERSION=$(cat VERSION | tr -d '\n')
LOCAL_TAG="test/haskell-tex-dev"
LOCAL_BASE_TAG="test/haskell-tex-dev-base"

echo "🧪 Testing Haskell layer build (version: $VERSION)"
echo ""

# First, build the base layer locally
echo "🏗️  Building base layer locally..."
if sudo docker build \
    --file build_context/Dockerfile.base \
    --build-arg VERSION="$VERSION" \
    --tag "${LOCAL_BASE_TAG}:latest" \
    . 2>&1 | tee /tmp/base-build.log; then
    echo "✅ Base layer build successful"
else
    echo "❌ Base layer build failed"
    echo "📋 Full build log saved to: /tmp/base-build.log"
    exit 1
fi

# Test Haskell layer build using local base image
echo "🏗️  Testing Haskell layer build with local base image..."
if sudo docker build \
    --file build_context/Dockerfile.haskell \
    --build-arg VERSION="$VERSION" \
    --build-arg BASE_IMAGE="${LOCAL_BASE_TAG}:latest" \
    --tag "${LOCAL_TAG}:haskell-test" \
    . 2>&1 | tee /tmp/haskell-build.log; then
    echo "✅ Haskell layer build successful"

    # Test that GHC is available
    echo "🔍 Testing GHC availability..."
    if sudo docker run --rm "${LOCAL_TAG}:haskell-test" ghc --version; then
        echo "✅ GHC is available"
    else
        echo "❌ GHC is missing"
        exit 1
    fi

    # Test that cabal is available
    echo "🔍 Testing cabal availability..."
    if sudo docker run --rm "${LOCAL_TAG}:haskell-test" cabal --version; then
        echo "✅ cabal is available"
    else
        echo "❌ cabal is missing"
        exit 1
    fi

    # Test WASM tools if available
    echo "🔍 Testing WASM tools..."
    if sudo docker run --rm "${LOCAL_TAG}:haskell-test" bash -c "which wasm32-wasi-ghc"; then
        echo "✅ WASM GHC is available"
    else
        echo "⚠️  WASM GHC is not available (this is expected if installation failed)"
    fi

    if sudo docker run --rm "${LOCAL_TAG}:haskell-test" bash -c "which wasm-ld"; then
        echo "✅ WASM linker is available"
    else
        echo "⚠️  WASM linker is not available"
    fi

    echo "🧹 Cleaning up test images..."
    sudo docker rmi "${LOCAL_TAG}:haskell-test" > /dev/null 2>&1 || true
    sudo docker rmi "${LOCAL_BASE_TAG}:latest" > /dev/null 2>&1 || true

else
    echo "❌ Haskell layer build failed"
    echo "📋 Full build log saved to: /tmp/haskell-build.log"
    echo ""
    echo "🔍 To debug further, run:"
    echo "   sudo docker build --file build_context/Dockerfile.haskell --build-arg VERSION=\"$VERSION\" --build-arg BASE_IMAGE=\"${LOCAL_BASE_TAG}:latest\" --tag test:haskell ."
    exit 1
fi

echo ""
echo "🎉 Haskell layer test completed!"
