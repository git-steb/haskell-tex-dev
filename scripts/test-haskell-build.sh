#!/bin/bash
set -euo pipefail

# Test Haskell layer build locally
# Usage: ./scripts/test-haskell-build.sh

VERSION=$(cat VERSION | tr -d '\n')
LOCAL_TAG="test/haskell-tex-dev"

echo "🧪 Testing Haskell layer build (version: $VERSION)"
echo ""

# Test Haskell layer build
echo "🏗️  Testing Haskell layer build..."
if sudo docker build \
    --file build_context/Dockerfile.haskell \
    --build-arg VERSION="$VERSION" \
    --tag "${LOCAL_TAG}:haskell-test" \
    . > /tmp/haskell-build.log 2>&1; then
    echo "✅ Haskell layer build successful"

    # Test that GHC is available
    echo "🔍 Testing GHC availability..."
    if sudo docker run --rm "${LOCAL_TAG}:haskell-test" ghc --version > /dev/null 2>&1; then
        echo "✅ GHC is available"
    else
        echo "❌ GHC is missing"
        exit 1
    fi

    # Test that cabal is available
    echo "🔍 Testing cabal availability..."
    if sudo docker run --rm "${LOCAL_TAG}:haskell-test" cabal --version > /dev/null 2>&1; then
        echo "✅ cabal is available"
    else
        echo "❌ cabal is missing"
        exit 1
    fi

    # Test WASM tools if available
    echo "🔍 Testing WASM tools..."
    if sudo docker run --rm "${LOCAL_TAG}:haskell-test" bash -c "which wasm32-wasi-ghc" > /dev/null 2>&1; then
        echo "✅ WASM GHC is available"
    else
        echo "⚠️  WASM GHC is not available (this is expected if installation failed)"
    fi

    if sudo docker run --rm "${LOCAL_TAG}:haskell-test" bash -c "which wasm-ld" > /dev/null 2>&1; then
        echo "✅ WASM linker is available"
    else
        echo "⚠️  WASM linker is not available"
    fi

    echo "🧹 Cleaning up test image..."
    sudo docker rmi "${LOCAL_TAG}:haskell-test" > /dev/null 2>&1 || true

else
    echo "❌ Haskell layer build failed"
    echo "📋 Build log:"
    cat /tmp/haskell-build.log
    echo ""
    echo "🔍 To debug further, run:"
    echo "   sudo docker build --file build_context/Dockerfile.haskell --build-arg VERSION=\"$VERSION\" --tag test:haskell ."
    exit 1
fi

echo ""
echo "🎉 Haskell layer test completed!"
