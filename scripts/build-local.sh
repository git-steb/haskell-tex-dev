#!/usr/bin/env bash
set -euo pipefail

# Local Docker Image Builder
# Usage: ./scripts/build-local.sh [version]
# Example: ./scripts/build-local.sh 1.3.0

VERSION="${1:-$(cat VERSION 2>/dev/null || echo '1.3.0')}"
LOCAL_TAG="local/haskell-tex-dev"
# Published images are currently Linux x86_64. Pin the same platform locally
# so Apple Silicon uses Docker Desktop emulation instead of trying to execute
# the amd64-only fixuid and TeX assets as native arm64 binaries.
DOCKER_PLATFORM="${DOCKER_PLATFORM:-linux/amd64}"

docker_bin() {
  if ! command -v docker >/dev/null 2>&1; then
    echo "❌ Error: docker is not installed or not on PATH." >&2
    if [[ "$(uname -s)" = "Darwin" ]]; then
      echo "Start/install Docker Desktop, then re-run this command." >&2
    fi
    exit 1
  fi
  if docker info >/dev/null 2>&1; then
    docker "$@"
  elif [[ "$(uname -s)" = "Darwin" ]]; then
    echo "❌ Error: Docker Desktop is not running or its context is unavailable." >&2
    exit 1
  else
    sudo docker "$@"
  fi
}

echo "🔨 Building Docker images locally (version: $VERSION)"
echo "🖥️  Target platform: $DOCKER_PLATFORM"
echo "📋 This will build: base -> haskell -> tex (layered approach)"
echo ""

# Check if we're in the right directory
if [[ ! -f "build_context/Dockerfile.base" ]] || [[ ! -f "build_context/Dockerfile.haskell" ]] || [[ ! -f "build_context/Dockerfile.tex" ]]; then
    echo "❌ Error: Missing Dockerfiles. Make sure you're in the haskell-tex-dev repository root."
    exit 1
fi

# Build base layer
echo "🏗️  Building base layer..."
if docker_bin build \
    --platform "$DOCKER_PLATFORM" \
    --file build_context/Dockerfile.base \
    --build-arg VERSION="$VERSION" \
    --tag "${LOCAL_TAG}:base-${VERSION}" \
    --tag "${LOCAL_TAG}:base-latest" \
    .; then
    echo "✅ Base layer built successfully"
else
    echo "❌ Base layer build failed"
    exit 1
fi

# Build haskell layer (depends on base)
echo ""
echo "🏗️  Building haskell layer..."
if docker_bin build \
    --platform "$DOCKER_PLATFORM" \
    --file build_context/Dockerfile.haskell \
    --build-arg BASE_IMAGE="${LOCAL_TAG}:base-${VERSION}" \
    --build-arg VERSION="$VERSION" \
    --tag "${LOCAL_TAG}:haskell-${VERSION}" \
    --tag "${LOCAL_TAG}:haskell-latest" \
    .; then
    echo "✅ Haskell layer built successfully"
else
    echo "❌ Haskell layer build failed"
    exit 1
fi

# Build tex layer (depends on haskell)
echo ""
echo "🏗️  Building tex layer..."
if docker_bin build \
    --platform "$DOCKER_PLATFORM" \
    --file build_context/Dockerfile.tex \
    --build-arg BASE_IMAGE="${LOCAL_TAG}:haskell-${VERSION}" \
    --build-arg VERSION="$VERSION" \
    --tag "${LOCAL_TAG}:tex-${VERSION}" \
    --tag "${LOCAL_TAG}:tex-latest" \
    --tag "${LOCAL_TAG}:latest" \
    .; then
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
