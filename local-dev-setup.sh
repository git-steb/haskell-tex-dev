#!/bin/bash

# Local Development Setup for haskell-tex-dev containers
# This script builds all containers locally and provides development tools

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
LOCAL_IMAGE_NAME="haskell-tex-dev"

# Container tags
BASE_TAG="local-base"
TEX_TAG="local-tex"
HASKELL_TAG="local-haskell"
HASKELL_NO_HLS_TAG="local-haskell-no-hls"
FULL_TAG="local-full"

# Function to print colored output
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

# Function to check if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    print_success "Docker is running"
}

# Function to build base container
build_base() {
    print_status "Building base container..."
    docker build -f Dockerfile.base -t ${LOCAL_IMAGE_NAME}:${BASE_TAG} .
    print_success "Base container built successfully"
}

# Function to build TeX container
build_tex() {
    print_status "Building TeX container..."
    docker build -f Dockerfile.tex --build-arg BASE_IMAGE=${LOCAL_IMAGE_NAME}:${BASE_TAG} -t ${LOCAL_IMAGE_NAME}:${TEX_TAG} .
    print_success "TeX container built successfully"
}

# Function to build Haskell container
build_haskell() {
    print_status "Building Haskell container..."
    docker build -f Dockerfile.haskell --build-arg BASE_IMAGE=${LOCAL_IMAGE_NAME}:${BASE_TAG} -t ${LOCAL_IMAGE_NAME}:${HASKELL_TAG} .
    print_success "Haskell container built successfully"
}

# Function to build Haskell (no HLS) container
build_haskell_no_hls() {
    print_status "Building Haskell (no HLS) container..."
    docker build -f Dockerfile.haskell.no-hls --build-arg BASE_IMAGE=${LOCAL_IMAGE_NAME}:${BASE_TAG} -t ${LOCAL_IMAGE_NAME}:${HASKELL_NO_HLS_TAG} .
    print_success "Haskell (no HLS) container built successfully"
}

# Function to build full container
build_full() {
    print_status "Building full container (Haskell + TeX)..."
    docker build -f Dockerfile.full --build-arg HASKELL_IMAGE=${LOCAL_IMAGE_NAME}:${HASKELL_TAG} --build-arg TEX_IMAGE=${LOCAL_IMAGE_NAME}:${TEX_TAG} -t ${LOCAL_IMAGE_NAME}:${FULL_TAG} .
    print_success "Full container built successfully"
}

# Function to build all containers
build_all() {
    print_status "Building all containers..."
    build_base
    build_tex
    build_haskell
    build_haskell_no_hls
    build_full
    print_success "All containers built successfully!"
}

# Function to test containers
test_containers() {
    print_status "Testing containers..."
    
    # Test base container
    print_status "Testing base container..."
    docker run --rm ${LOCAL_IMAGE_NAME}:${BASE_TAG} whoami
    
    # Test TeX container
    print_status "Testing TeX container..."
    docker run --rm ${LOCAL_IMAGE_NAME}:${TEX_TAG} pdflatex --version
    
    # Test Haskell container
    print_status "Testing Haskell container..."
    docker run --rm ${LOCAL_IMAGE_NAME}:${HASKELL_TAG} ghc --version
    
    # Test Haskell (no HLS) container
    print_status "Testing Haskell (no HLS) container..."
    docker run --rm ${LOCAL_IMAGE_NAME}:${HASKELL_NO_HLS_TAG} ghc --version
    
    # Test full container
    print_status "Testing full container..."
    docker run --rm ${LOCAL_IMAGE_NAME}:${FULL_TAG} bash -c "ghc --version && pdflatex --version"
    
    print_success "All containers tested successfully!"
}

# Function to show container usage
show_usage() {
    echo ""
    echo "🎯 Container Usage Examples:"
    echo ""
    echo "📦 Base Container (Ubuntu with basic tools):"
    echo "  docker run -it --rm ${LOCAL_IMAGE_NAME}:${BASE_TAG} bash"
    echo ""
    echo "📄 TeX Container (TeX Live with LuaTeX):"
    echo "  docker run -it --rm -v \$(pwd):/workspace ${LOCAL_IMAGE_NAME}:${TEX_TAG} bash"
    echo ""
    echo "⚡ Haskell Container (GHC 9.12.2, Cabal, Stack):"
    echo "  docker run -it --rm -v \$(pwd):/workspace ${LOCAL_IMAGE_NAME}:${HASKELL_TAG} bash"
    echo ""
    echo "🚀 Haskell (No HLS) Container (Leaner version):"
    echo "  docker run -it --rm -v \$(pwd):/workspace ${LOCAL_IMAGE_NAME}:${HASKELL_NO_HLS_TAG} bash"
    echo ""
    echo "🎯 Full Container (Haskell + TeX for HASM):"
    echo "  docker run -it --rm -v \$(pwd):/workspace ${LOCAL_IMAGE_NAME}:${FULL_TAG} bash"
    echo ""
}

# Function to create development aliases
create_aliases() {
    print_status "Creating development aliases..."
    
    # Create aliases file
    cat > .dev-aliases.sh << 'ALIASES_EOF'
#!/bin/bash
# Development aliases for haskell-tex-dev containers

# Base container
alias dev-base='docker run -it --rm haskell-tex-dev:local-base bash'

# TeX container
alias dev-tex='docker run -it --rm -v $(pwd):/workspace haskell-tex-dev:local-tex bash'

# Haskell container
alias dev-haskell='docker run -it --rm -v $(pwd):/workspace haskell-tex-dev:local-haskell bash'

# Haskell (no HLS) container
alias dev-haskell-lean='docker run -it --rm -v $(pwd):/workspace haskell-tex-dev:local-haskell-no-hls bash'

# Full container
alias dev-full='docker run -it --rm -v $(pwd):/workspace haskell-tex-dev:local-full bash'

# Quick commands
alias haskell-test='docker run --rm -v $(pwd):/workspace haskell-tex-dev:local-haskell bash -c "ghc --version && cabal --version"'
alias tex-test='docker run --rm -v $(pwd):/workspace haskell-tex-dev:local-tex bash -c "pdflatex --version && tlmgr --version"'
alias full-test='docker run --rm -v $(pwd):/workspace haskell-tex-dev:local-full bash -c "ghc --version && pdflatex --version"'

echo "Development aliases loaded. Use:"
echo "  dev-base      - Base container"
echo "  dev-tex       - TeX container"
echo "  dev-haskell   - Haskell container"
echo "  dev-haskell-lean - Haskell (no HLS) container"
echo "  dev-full      - Full container"
echo "  haskell-test  - Quick Haskell test"
echo "  tex-test      - Quick TeX test"
echo "  full-test     - Quick full test"
ALIASES_EOF

    chmod +x .dev-aliases.sh
    print_success "Development aliases created in .dev-aliases.sh"
    print_status "To use aliases, run: source .dev-aliases.sh"
}

# Function to create docker-compose for easy development
create_docker_compose() {
    print_status "Creating docker-compose.yml for development..."
    
    cat > docker-compose.dev.yml << 'COMPOSE_EOF'
version: '3.8'

services:
  base:
    build:
      context: .
      dockerfile: Dockerfile.base
    image: haskell-tex-dev:local-base
    container_name: haskell-tex-dev-base
    volumes:
      - .:/workspace
    working_dir: /workspace
    tty: true

  tex:
    build:
      context: .
      dockerfile: Dockerfile.tex
      args:
        BASE_IMAGE: haskell-tex-dev:local-base
    image: haskell-tex-dev:local-tex
    container_name: haskell-tex-dev-tex
    volumes:
      - .:/workspace
    working_dir: /workspace
    tty: true

  haskell:
    build:
      context: .
      dockerfile: Dockerfile.haskell
      args:
        BASE_IMAGE: haskell-tex-dev:local-base
    image: haskell-tex-dev:local-haskell
    container_name: haskell-tex-dev-haskell
    volumes:
      - .:/workspace
    working_dir: /workspace
    tty: true

  haskell-lean:
    build:
      context: .
      dockerfile: Dockerfile.haskell.no-hls
      args:
        BASE_IMAGE: haskell-tex-dev:local-base
    image: haskell-tex-dev:local-haskell-no-hls
    container_name: haskell-tex-dev-haskell-lean
    volumes:
      - .:/workspace
    working_dir: /workspace
    tty: true

  full:
    build:
      context: .
      dockerfile: Dockerfile.full
      args:
        HASKELL_IMAGE: haskell-tex-dev:local-haskell
        TEX_IMAGE: haskell-tex-dev:local-tex
    image: haskell-tex-dev:local-full
    container_name: haskell-tex-dev-full
    volumes:
      - .:/workspace
    working_dir: /workspace
    tty: true
COMPOSE_EOF

    print_success "docker-compose.dev.yml created"
    print_status "To use docker-compose:"
    print_status "  docker-compose -f docker-compose.dev.yml up -d <service>"
    print_status "  docker-compose -f docker-compose.dev.yml exec <service> bash"
}

# Function to clean up containers
cleanup() {
    print_status "Cleaning up containers..."
    docker rmi ${LOCAL_IMAGE_NAME}:${BASE_TAG} 2>/dev/null || true
    docker rmi ${LOCAL_IMAGE_NAME}:${TEX_TAG} 2>/dev/null || true
    docker rmi ${LOCAL_IMAGE_NAME}:${HASKELL_TAG} 2>/dev/null || true
    docker rmi ${LOCAL_IMAGE_NAME}:${HASKELL_NO_HLS_TAG} 2>/dev/null || true
    docker rmi ${LOCAL_IMAGE_NAME}:${FULL_TAG} 2>/dev/null || true
    print_success "Cleanup completed"
}

# Function to show container status
status() {
    print_status "Container Status:"
    echo ""
    docker images | grep ${LOCAL_IMAGE_NAME} || echo "No local containers found"
    echo ""
    print_status "Available containers:"
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | grep ${LOCAL_IMAGE_NAME} || echo "None"
}

# Main script logic
main() {
    case "${1:-help}" in
        "build-base")
            check_docker
            build_base
            ;;
        "build-tex")
            check_docker
            build_tex
            ;;
        "build-haskell")
            check_docker
            build_haskell
            ;;
        "build-haskell-no-hls")
            check_docker
            build_haskell_no_hls
            ;;
        "build-full")
            check_docker
            build_full
            ;;
        "build-all")
            check_docker
            build_all
            ;;
        "test")
            check_docker
            test_containers
            ;;
        "aliases")
            create_aliases
            ;;
        "compose")
            create_docker_compose
            ;;
        "cleanup")
            cleanup
            ;;
        "status")
            status
            ;;
        "setup")
            check_docker
            build_all
            test_containers
            create_aliases
            create_docker_compose
            print_success "Local development setup complete!"
            show_usage
            ;;
        "help"|*)
            echo "🚀 Local Development Setup for haskell-tex-dev"
            echo ""
            echo "Usage: $0 [command]"
            echo ""
            echo "Commands:"
            echo "  build-base          - Build base container"
            echo "  build-tex           - Build TeX container"
            echo "  build-haskell       - Build Haskell container"
            echo "  build-haskell-no-hls - Build Haskell (no HLS) container"
            echo "  build-full          - Build full container"
            echo "  build-all           - Build all containers"
            echo "  test                - Test all containers"
            echo "  aliases             - Create development aliases"
            echo "  compose             - Create docker-compose file"
            echo "  cleanup             - Remove all local containers"
            echo "  status              - Show container status"
            echo "  setup               - Complete setup (build + test + aliases + compose)"
            echo "  help                - Show this help"
            echo ""
            show_usage
            ;;
    esac
}

# Run main function
main "$@"
