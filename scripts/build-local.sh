#!/bin/bash
set -euo pipefail

# Local Docker Image Builder
# Usage: ./scripts/build-local.sh [version]
# Example: ./scripts/build-local.sh 1.2.6

VERSION="${1:-$(cat VERSION 2>/dev/null || echo '1.2.6')}"
LOCAL_TAG="local/haskell-tex-dev"

echo "🔨 Building Docker images locally (version: $VERSION)"
echo "📋 This will build: base -> haskell -> tex (layered approach)"
echo ""

# Check if we're in the right directory
if [[ ! -f "build_context/Dockerfile.base" ]] || [[ ! -f "build_context/Dockerfile.haskell" ]] || [[ ! -f "build_context/Dockerfile.tex" ]]; then
    echo "❌ Error: Missing Dockerfiles. Make sure you're in the haskell-tex-dev repository root."
    exit 1
fi

# Build base layer
echo "🏗️  Building base layer..."
sudo docker build \
    --file build_context/Dockerfile.base \
    --build-arg VERSION="$VERSION" \
    --tag "${LOCAL_TAG}:base-${VERSION}" \
    --tag "${LOCAL_TAG}:base-latest" \
    .

if [[ $? -eq 0 ]]; then
    echo "✅ Base layer built successfully"
else
    echo "❌ Base layer build failed"
    exit 1
fi

# Build haskell layer (depends on base)
echo ""
echo "🏗️  Building haskell layer..."
sudo docker build \
    --file build_context/Dockerfile.haskell \
    --build-arg BASE_IMAGE="${LOCAL_TAG}:base-${VERSION}" \
    --build-arg VERSION="$VERSION" \
    --tag "${LOCAL_TAG}:haskell-${VERSION}" \
    --tag "${LOCAL_TAG}:haskell-latest" \
    .

if [[ $? -eq 0 ]]; then
    echo "✅ Haskell layer built successfully"
else
    echo "❌ Haskell layer build failed"
    exit 1
fi

# Build tex layer (depends on haskell)
echo ""
echo "🏗️  Building tex layer..."
sudo docker build \
    --file build_context/Dockerfile.tex \
    --build-arg BASE_IMAGE="${LOCAL_TAG}:haskell-${VERSION}" \
    --build-arg VERSION="$VERSION" \
    --tag "${LOCAL_TAG}:tex-${VERSION}" \
    --tag "${LOCAL_TAG}:tex-latest" \
    --tag "${LOCAL_TAG}:latest" \
    .

if [[ $? -eq 0 ]]; then
    echo "✅ Tex layer built successfully"
else
    echo "❌ Tex layer build failed"
    exit 1
fi

echo ""
echo "🎉 All layers built successfully!"
echo ""
echo "📋 Available local images:"
echo "  ${LOCAL_TAG}:base-${VERSION}     (base layer)"
echo "  ${LOCAL_TAG}:haskell-${VERSION}  (haskell layer)"
echo "  ${LOCAL_TAG}:tex-${VERSION}      (tex layer)"
echo "  ${LOCAL_TAG}:latest              (full image)"
echo ""
echo "🧪 Test the images:"
echo "  docker run --rm ${LOCAL_TAG}:base-${VERSION} jq --version"
echo "  docker run --rm ${LOCAL_TAG}:haskell-${VERSION} ghc --version"
echo "  docker run --rm ${LOCAL_TAG}:latest latexmk -v"
echo ""
echo "💡 To clean up local images:"
echo "  docker rmi ${LOCAL_TAG}:base-${VERSION} ${LOCAL_TAG}:haskell-${VERSION} ${LOCAL_TAG}:tex-${VERSION} ${LOCAL_TAG}:latest"
