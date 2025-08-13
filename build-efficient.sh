#!/bin/bash

# Efficient Docker build script with cache optimization and CI-ready features
# Uses Docker's cache mount and parallel building features

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration with environment variable overrides
LOCAL_IMAGE_NAME="haskell-tex-dev"
CACHE_DIR="${DOCKER_CACHE_DIR:-${HOME}/.docker-cache}"
VERBOSE="${VERBOSE:-0}"
DRYRUN="${DRYRUN:-0}"

# Dynamic version detection (priority: .version file > git tag > env var > default)
if [ -f ".version" ]; then
    VERSION=$(cat .version)
elif command -v git >/dev/null 2>&1 && git rev-parse --git-dir >/dev/null 2>&1; then
    VERSION=$(git describe --tags --always 2>/dev/null || echo "v1.2.0")
else
    VERSION="${VERSION:-v1.2.0}"
fi

# Create cache directories
mkdir -p "${CACHE_DIR}/apt"
mkdir -p "${CACHE_DIR}/ghcup"
mkdir -p "${CACHE_DIR}/cabal"

print_status "Using cache directory: ${CACHE_DIR}"
print_status "Building version: ${VERSION}"
print_status "Verbose mode: ${VERBOSE}"
print_status "Dry run mode: ${DRYRUN}"

# Helper function to run or echo commands
run_or_echo() {
    if [ "$DRYRUN" = "1" ]; then
        echo "DRY RUN: $*"
    else
        if [ "$VERBOSE" = "1" ]; then
            echo "RUNNING: $*"
        fi
        "$@"
    fi
}

# Check if Docker is available
check_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        print_error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker daemon is not running or user not in docker group"
        exit 1
    fi
}

# Check GHCR authentication
check_ghcr_auth() {
    if ! docker info 2>/dev/null | grep -q "ghcr.io"; then
        print_warning "Not logged in to GHCR"
        print_warning "Run: echo \$GHCR_PAT | docker login ghcr.io -u \$GITHUB_USERNAME --password-stdin"
        return 1
    fi
    return 0
}

# Check if Dockerfile exists
check_dockerfile() {
    local dockerfile="$1"
    if [ ! -f "$dockerfile" ]; then
        print_warning "Missing $dockerfile - skipping"
        return 1
    fi
    return 0
}

# Function to build with cache optimization
build_with_cache() {
    local dockerfile="$1"
    local tag="$2"
    local build_args="$3"
    
    if ! check_dockerfile "$dockerfile"; then
        return 1
    fi
    
    print_status "Building ${tag} with cache optimization..."
    
    # Build with cache mount and parallel optimization
    run_or_echo sudo docker build \
        --file "${dockerfile}" \
        --tag "${LOCAL_IMAGE_NAME}:${tag}" \
        --build-arg BUILDKIT_INLINE_CACHE=1 \
        --cache-from "${LOCAL_IMAGE_NAME}:${tag}" \
        --mount=type=cache,target=/var/cache/apt,sharing=locked,mode=0777,id=apt-cache \
        --mount=type=cache,target=/home/dev/.ghcup,sharing=locked,mode=0777,id=ghcup-cache \
        --mount=type=cache,target=/home/dev/.cabal,sharing=locked,mode=0777,id=cabal-cache \
        --mount=type=cache,target=/home/dev/.cache,sharing=locked,mode=0777,id=general-cache \
        --progress=plain \
        ${build_args} \
        .
    
    if [ "$DRYRUN" = "0" ]; then
        print_success "Built ${tag}"
    fi
}

# Build base container (no cache needed)
build_base() {
    print_status "Building base container..."
    if ! check_dockerfile "Dockerfile.base"; then
        return 1
    fi
    
    run_or_echo sudo docker build \
        --file Dockerfile.base \
        --tag "${LOCAL_IMAGE_NAME}:local-base" \
        --progress=plain \
        .
    
    if [ "$DRYRUN" = "0" ]; then
        print_success "Base container built"
    fi
}

# Build all containers efficiently (with parallel option)
build_all() {
    print_status "Building all containers with cache optimization..."
    
    # Build base first
    build_base
    
    # Check if we can build in parallel
    if command -v parallel >/dev/null 2>&1 && [ "$DRYRUN" = "0" ]; then
        print_status "Building Haskell and TeX layers in parallel..."
        
        # Build Haskell and TeX in parallel
        parallel --bar --jobs 2 ::: \
            "build_with_cache Dockerfile.haskell local-haskell --build-arg BASE_IMAGE=${LOCAL_IMAGE_NAME}:local-base" \
            "build_with_cache Dockerfile.tex local-tex --build-arg BASE_IMAGE=${LOCAL_IMAGE_NAME}:local-base"
        
        # Build Haskell (no HLS) container
        build_with_cache \
            "Dockerfile.haskell.no-hls" \
            "local-haskell-no-hls" \
            "--build-arg BASE_IMAGE=${LOCAL_IMAGE_NAME}:local-base"
    else
        print_status "Building layers sequentially..."
        
        # Build TeX container
        build_with_cache \
            "Dockerfile.tex" \
            "local-tex" \
            "--build-arg BASE_IMAGE=${LOCAL_IMAGE_NAME}:local-base"
        
        # Build Haskell container
        build_with_cache \
            "Dockerfile.haskell" \
            "local-haskell" \
            "--build-arg BASE_IMAGE=${LOCAL_IMAGE_NAME}:local-base"
        
        # Build Haskell (no HLS) container
        build_with_cache \
            "Dockerfile.haskell.no-hls" \
            "local-haskell-no-hls" \
            "--build-arg BASE_IMAGE=${LOCAL_IMAGE_NAME}:local-base"
    fi
    
    # Build full container (comprehensive Haskell + TeX)
    build_with_cache \
        "Dockerfile.full" \
        "local-full" \
        "--build-arg HASKELL_IMAGE=${LOCAL_IMAGE_NAME}:local-haskell --build-arg TEX_IMAGE=${LOCAL_IMAGE_NAME}:local-tex"
    
    if [ "$DRYRUN" = "0" ]; then
        print_success "All containers built with cache optimization!"
    fi
}

# Function to tag and push to GHCR
tag_and_push() {
    local local_tag="$1"
    local remote_tag="$2"
    local description="$3"
    
    if [ "$DRYRUN" = "1" ]; then
        print_status "DRY RUN: Would tag ${local_tag} as ${remote_tag}"
        print_status "DRY RUN: Would push ${remote_tag} to GHCR"
        return
    fi
    
    print_status "Tagging ${local_tag} as ${remote_tag}..."
    run_or_echo sudo docker tag "${LOCAL_IMAGE_NAME}:${local_tag}" "ghcr.io/git-steb/haskell-tex-dev:${remote_tag}"
    
    print_status "Pushing ${remote_tag} to GHCR..."
    run_or_echo sudo docker push "ghcr.io/git-steb/haskell-tex-dev:${remote_tag}"
    
    print_success "Pushed ${remote_tag} - ${description}"
}

# Function to publish all images
publish_all() {
    print_status "Publishing all images to GHCR..."
    
    # Check GHCR authentication
    if ! check_ghcr_auth; then
        print_error "Cannot publish without GHCR authentication"
        exit 1
    fi
    
    # Tag and push base
    tag_and_push "local-base" "base-${VERSION}" "Base Ubuntu 24.04 foundation"
    tag_and_push "local-base" "base-latest" "Base Ubuntu 24.04 foundation (latest)"
    
    # Tag and push Haskell
    tag_and_push "local-haskell" "haskell-${VERSION}" "Haskell toolchain with GHC 9.12.2 and WASM"
    tag_and_push "local-haskell" "haskell-latest" "Haskell toolchain (latest)"
    
    # Tag and push TeX
    tag_and_push "local-tex" "tex-${VERSION}" "Complete TeX Live with LuaTeX and comprehensive packages"
    tag_and_push "local-tex" "tex-latest" "TeX Live environment (latest)"
    
    # Tag and push full (comprehensive)
    tag_and_push "local-full" "${VERSION}" "Complete Haskell + TeX environment for HASM applications"
    tag_and_push "local-full" "full-${VERSION}" "Complete Haskell + TeX environment (versioned)"
    tag_and_push "local-full" "full-latest" "Complete Haskell + TeX environment (latest)"
    tag_and_push "local-full" "latest" "Default complete environment"
    
    print_success "All images published to GHCR!"
}

# Function to show cache usage
show_cache_info() {
    print_status "Cache Information:"
    echo "  Cache directory: ${CACHE_DIR}"
    echo "  APT cache: ${CACHE_DIR}/apt"
    echo "  GHCup cache: ${CACHE_DIR}/ghcup"
    echo "  Cabal cache: ${CACHE_DIR}/cabal"
    echo ""
    print_status "Cache sizes:"
    du -sh "${CACHE_DIR}"/* 2>/dev/null || echo "No cache data yet"
}

# Function to clean cache
clean_cache() {
    print_status "Cleaning cache..."
    run_or_echo sudo rm -rf "${CACHE_DIR}"/*
    print_success "Cache cleaned"
}

# Function to show container sizes
show_sizes() {
    print_status "Container sizes:"
    run_or_echo sudo docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | grep "${LOCAL_IMAGE_NAME}" || echo "No containers found"
}

# Function to test the full environment
test_full() {
    print_status "Testing full environment..."
    
    if [ "$DRYRUN" = "1" ]; then
        print_status "DRY RUN: Would test full environment"
        return
    fi
    
    # Test Haskell
    run_or_echo sudo docker run --rm "${LOCAL_IMAGE_NAME}:local-full" ghc --version
    run_or_echo sudo docker run --rm "${LOCAL_IMAGE_NAME}:local-full" cabal --version
    
    # Test TeX
    run_or_echo sudo docker run --rm "${LOCAL_IMAGE_NAME}:local-full" pdflatex --version
    run_or_echo sudo docker run --rm "${LOCAL_IMAGE_NAME}:local-full" lualatex --version
    run_or_echo sudo docker run --rm "${LOCAL_IMAGE_NAME}:local-full" tlmgr --version
    
    # Test combined environment
    run_or_echo sudo docker run --rm "${LOCAL_IMAGE_NAME}:local-full" show-all-versions
    
    print_success "Full environment test passed!"
}

# Function to show version information
show_version() {
    print_status "Version Information:"
    echo "  Current version: ${VERSION}"
    echo "  Version source: $([ -f ".version" ] && echo ".version file" || echo "git tag")"
    echo "  Git commit: $(git rev-parse --short HEAD 2>/dev/null || echo "not available")"
    echo "  Build date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
}

# Function to validate environment
validate_environment() {
    print_status "Validating build environment..."
    
    check_docker
    
    # Check required Dockerfiles
    local required_files=("Dockerfile.base" "Dockerfile.haskell" "Dockerfile.tex" "Dockerfile.full")
    local missing_files=()
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            missing_files+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -gt 0 ]; then
        print_error "Missing required files: ${missing_files[*]}"
        exit 1
    fi
    
    print_success "Environment validation passed!"
}

# Main script logic
case "${1:-help}" in
    "build-base")
        validate_environment
        build_base
        ;;
    "build-all")
        validate_environment
        build_all
        ;;
    "publish")
        validate_environment
        publish_all
        ;;
    "build-and-publish")
        validate_environment
        build_all
        publish_all
        ;;
    "test-full")
        validate_environment
        test_full
        ;;
    "validate")
        validate_environment
        ;;
    "version")
        show_version
        ;;
    "cache-info")
        show_cache_info
        ;;
    "clean-cache")
        clean_cache
        ;;
    "sizes")
        show_sizes
        ;;
    "help"|*)
        echo "🚀 Efficient Docker Build Script - v${VERSION}"
        echo ""
        echo "Usage: $0 [command] [options]"
        echo ""
        echo "Commands:"
        echo "  build-base         - Build base container"
        echo "  build-all          - Build all containers with cache optimization"
        echo "  publish            - Tag and push all images to GHCR"
        echo "  build-and-publish  - Build all containers and publish to GHCR"
        echo "  test-full          - Test the full environment"
        echo "  validate           - Validate build environment"
        echo "  version            - Show version information"
        echo "  cache-info         - Show cache information"
        echo "  clean-cache        - Clean build cache"
        echo "  sizes              - Show container sizes"
        echo "  help               - Show this help"
        echo ""
        echo "Options:"
        echo "  VERBOSE=1          - Enable verbose output"
        echo "  DRYRUN=1           - Show commands without executing"
        echo "  DOCKER_CACHE_DIR   - Override cache directory"
        echo "  VERSION            - Override version detection"
        echo ""
        echo "Version: ${VERSION} - First comprehensive full layer"
        echo ""
        echo "Cache Features:"
        echo "  - APT package cache"
        echo "  - GHCup toolchain cache"
        echo "  - Cabal package cache"
        echo "  - General build cache"
        echo "  - Parallel builds (when GNU parallel available)"
        echo ""
        echo "Published Tags:"
        echo "  - ghcr.io/git-steb/haskell-tex-dev:${VERSION} (full environment)"
        echo "  - ghcr.io/git-steb/haskell-tex-dev:latest (default)"
        echo "  - ghcr.io/git-steb/haskell-tex-dev:full-${VERSION} (versioned full)"
        echo "  - ghcr.io/git-steb/haskell-tex-dev:full-latest (latest full)"
        echo "  - ghcr.io/git-steb/haskell-tex-dev:haskell-${VERSION} (Haskell only)"
        echo "  - ghcr.io/git-steb/haskell-tex-dev:tex-${VERSION} (TeX only)"
        echo ""
        echo "Examples:"
        echo "  $0 build-all                    # Build all images"
        echo "  VERBOSE=1 $0 build-all          # Build with verbose output"
        echo "  DRYRUN=1 $0 build-and-publish   # Show what would be built/published"
        echo "  DOCKER_CACHE_DIR=/tmp/cache $0 build-all  # Use custom cache"
        ;;
esac
