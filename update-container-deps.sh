#!/bin/bash
# Update Container Dependencies Script
# This script helps update the haskell-tex-dev container to include all project dependencies
# Run this in the haskell-tex-dev repository to update the container

set -e

echo "🔧 Container Dependency Update Script"
echo "====================================="

# Check if we're in the haskell-tex-dev repository
if [ ! -f "Dockerfile" ]; then
    echo "❌ This script should be run in the haskell-tex-dev repository"
    echo "📁 Current directory: $(pwd)"
    echo "🔗 Please navigate to the haskell-tex-dev repository and run this script"
    exit 1
fi

echo "✅ Found Dockerfile in haskell-tex-dev repository"

# Check if requirements.txt exists
if [ ! -f "requirements.txt" ]; then
    echo "❌ requirements.txt not found in haskell-tex-dev repository"
    exit 1
fi

echo "📋 Current requirements.txt:"
cat requirements.txt

echo ""
echo "🔍 Checking project requirements..."
if [ -f "../homeomorphosis/contracts/scripts/requirements.txt" ]; then
    echo "📦 Project requirements found:"
    cat ../homeomorphosis/contracts/scripts/requirements.txt
    
    echo ""
    echo "🔧 Updating container requirements.txt..."
    
    # Create backup
    cp requirements.txt requirements.txt.backup
    
    # Merge requirements (avoid duplicates)
    cat requirements.txt ../homeomorphosis/contracts/scripts/requirements.txt | sort -u > requirements.txt.new
    
    # Remove duplicates while preserving order
    awk '!seen[$0]++' requirements.txt.new > requirements.txt
    
    echo "✅ Updated requirements.txt:"
    cat requirements.txt
    
    echo ""
    echo "📊 Summary of changes:"
    echo "Original packages: $(wc -l < requirements.txt.backup)"
    echo "Updated packages: $(wc -l < requirements.txt)"
    
    echo ""
    echo "🚀 Next steps:"
    echo "1. Review the updated requirements.txt"
    echo "2. Build the updated container:"
    echo "   docker build -t ghcr.io/git-steb/haskell-tex-dev:sha-$(git rev-parse --short HEAD) ."
    echo "3. Push the updated container:"
    echo "   docker push ghcr.io/git-steb/haskell-tex-dev:sha-$(git rev-parse --short HEAD)"
    echo "4. Update the SHA reference in homeomorphosis workflows"
    
else
    echo "⚠️  Project requirements not found at ../homeomorphosis/contracts/scripts/requirements.txt"
    echo "📋 Current container requirements are sufficient"
fi

echo ""
echo "🎯 Container Optimization Recommendations:"
echo "1. Consider pre-installing common Haskell packages in the container"
echo "2. Add more TeX packages if needed for the project"
echo "3. Consider using multi-stage builds for smaller final image"
echo "4. Add health checks for all major tools (GHC, Cabal, Python, TeX)"
