#!/bin/bash
set -euo pipefail

# Debug WASM installation locally
# Usage: ./scripts/debug-wasm.sh

VERSION=$(cat VERSION | tr -d '\n')
LOCAL_TAG="test/haskell-tex-dev"

echo "🔍 Debugging WASM installation (version: $VERSION)"
echo ""

# Build with detailed output and capture logs
echo "🏗️  Building Haskell layer with detailed output..."
sudo docker build \
    --file build_context/Dockerfile.haskell \
    --build-arg VERSION="$VERSION" \
    --tag "${LOCAL_TAG}:haskell-debug" \
    . 2>&1 | tee /tmp/haskell-debug.log

echo ""
echo "📋 Full build log saved to: /tmp/haskell-debug.log"
echo ""

# If build succeeded, test the container
if sudo docker images | grep -q "${LOCAL_TAG}:haskell-debug"; then
    echo "✅ Build succeeded, testing container..."
    
    # Check what's actually installed
    echo "🔍 Checking installed tools..."
    sudo docker run --rm "${LOCAL_TAG}:haskell-debug" bash -c "
        echo '=== GHC Versions ==='
        ghc --version 2>/dev/null || echo 'GHC not found'
        echo ''
        echo '=== Cabal Version ==='
        cabal --version 2>/dev/null || echo 'Cabal not found'
        echo ''
        echo '=== WASM Tools ==='
        which wasm32-wasi-ghc 2>/dev/null || echo 'WASM GHC not found'
        which wasm-ld 2>/dev/null || echo 'WASM linker not found'
        echo ''
        echo '=== GHCup Logs ==='
        ls -la /home/dev/.ghcup/logs/ 2>/dev/null || echo 'No logs directory'
        echo ''
        echo '=== Recent Log Content ==='
        find /home/dev/.ghcup/logs/ -name '*.log' -type f -exec tail -20 {} \; 2>/dev/null | head -50 || echo 'No log content'
    "
    
    echo "🧹 Cleaning up debug image..."
    sudo docker rmi "${LOCAL_TAG}:haskell-debug" > /dev/null 2>&1 || true
else
    echo "❌ Build failed"
    echo "📋 Check /tmp/haskell-debug.log for details"
fi

echo ""
echo "🔍 Debug complete!"
