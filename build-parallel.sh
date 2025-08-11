#!/bin/bash
# Build and publish parallel layer architecture to GHCR
# This creates modular layers that can be combined as needed

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="ghcr.io/git-steb/haskell-tex-dev"
COMMIT_SHA=$(git rev-parse HEAD)
TAG="sha-${COMMIT_SHA}"

echo -e "${BLUE}🚀 Building parallel layer architecture for GHCR${NC}"
echo -e "${BLUE}📦 Image: ${IMAGE_NAME}:${TAG}${NC}"
echo -e "${BLUE}🔗 Commit: ${COMMIT_SHA}${NC}"
echo -e "${BLUE}🏗️  Architecture: Ubuntu Base → Haskell/TeX Parallel → Full Combined${NC}"
echo ""

# Check if we're logged into GHCR
if ! docker info | grep -q "Username"; then
    echo -e "${YELLOW}⚠️  Not logged into Docker registry. Please run:${NC}"
    echo -e "${YELLOW}   echo \$GITHUB_TOKEN | docker login ghcr.io -u \$GITHUB_USERNAME --password-stdin${NC}"
    exit 1
fi

# Function to build and push a layer
build_and_push_layer() {
    local layer_name=$1
    local dockerfile=$2
    local description=$3
    
    echo -e "${YELLOW}🔨 Building ${layer_name} layer...${NC}"
    echo -e "${YELLOW}   ${description}${NC}"
    
    if docker build -f "$dockerfile" -t "${IMAGE_NAME}:${layer_name}-${TAG}" .; then
        echo -e "${GREEN}✅ ${layer_name} layer built successfully${NC}"
        
        # Tag as latest
        docker tag "${IMAGE_NAME}:${layer_name}-${TAG}" "${IMAGE_NAME}:${layer_name}-latest"
        echo -e "${GREEN}✅ Tagged ${layer_name} as latest${NC}"
        
        # Push to GHCR
        echo -e "${YELLOW}📤 Pushing ${layer_name} layer...${NC}"
        if docker push "${IMAGE_NAME}:${layer_name}-${TAG}"; then
            echo -e "${GREEN}✅ Pushed ${layer_name} SHA tag${NC}"
        else
            echo -e "${RED}❌ Failed to push ${layer_name} SHA tag${NC}"
            exit 1
        fi
        
        if docker push "${IMAGE_NAME}:${layer_name}-latest"; then
            echo -e "${GREEN}✅ Pushed ${layer_name} latest tag${NC}"
        else
            echo -e "${RED}❌ Failed to push ${layer_name} latest tag${NC}"
            exit 1
        fi
    else
        echo -e "${RED}❌ Failed to build ${layer_name} layer${NC}"
        exit 1
    fi
    echo ""
}

# Build layers in dependency order
echo -e "${BLUE}📋 Building layers in dependency order:${NC}"
echo ""

# 1. Base layer (Ubuntu foundation)
build_and_push_layer "base" "Dockerfile.base" "Ubuntu foundation for parallel layers"

# 2. Haskell layer (parallel to TeX)
build_and_push_layer "haskell" "Dockerfile.haskell" "GHC 9.12.2 with native WASM support"

# 3. TeX layer (parallel to Haskell)
build_and_push_layer "tex" "Dockerfile.tex" "TeX Live with LuaTeX for Unicode support"

# 4. Full layer (Haskell + TeX combined)
build_and_push_layer "full" "Dockerfile.full" "Complete environment for HASM applications"

echo -e "${GREEN}🎉 All parallel layers built and published successfully!${NC}"
echo ""
echo -e "${BLUE}📋 Available images:${NC}"
echo -e "  ${IMAGE_NAME}:base-${TAG}     (Ubuntu foundation)"
echo -e "  ${IMAGE_NAME}:haskell-${TAG}  (GHC + WASM support)"
echo -e "  ${IMAGE_NAME}:tex-${TAG}      (TeX Live + LuaTeX)"
echo -e "  ${IMAGE_NAME}:full-${TAG}     (Complete HASM environment)"
echo ""
echo -e "${BLUE}🔗 Usage examples:${NC}"
echo -e "  # Haskell only (no TeX):"
echo -e "  docker run -it --rm -v \$(pwd):/workspace ${IMAGE_NAME}:haskell-latest"
echo -e ""
echo -e "  # TeX only (no Haskell):"
echo -e "  docker run -it --rm -v \$(pwd):/workspace ${IMAGE_NAME}:tex-latest"
echo -e ""
echo -e "  # Full environment (HASM applications):"
echo -e "  docker run -it --rm -v \$(pwd):/workspace ${IMAGE_NAME}:full-latest"
echo ""
echo -e "${BLUE}⚡ Benefits of parallel architecture:${NC}"
echo -e "  - Independent layer updates (Haskell vs TeX)"
echo -e "  - Smaller images when only one toolchain needed"
echo -e "  - Better caching (shared base layer)"
echo -e "  - Flexible deployment (choose what you need)"
echo ""
echo -e "${BLUE}🚀 Next steps:${NC}"
echo -e "  1. Update CI workflows to use appropriate layers"
echo -e "  2. Test each layer independently"
echo -e "  3. Verify HASM applications work with full layer"
echo -e "  4. Monitor cache performance improvements"
