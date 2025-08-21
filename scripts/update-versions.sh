#!/bin/bash
set -euo pipefail

# Update versions.env from VERSION file
# Usage: ./scripts/update-versions.sh

VERSION_FILE="VERSION"
VERSIONS_ENV_FILE="build_context/versions.env"

echo "🔄 Updating versions.env from VERSION file..."

# Read current version
if [ ! -f "$VERSION_FILE" ]; then
    echo "❌ VERSION file not found: $VERSION_FILE"
    exit 1
fi

CURRENT_VERSION=$(cat "$VERSION_FILE" | tr -d '\n')
echo "📋 Current version: $CURRENT_VERSION"

# Update versions.env
if [ ! -f "$VERSIONS_ENV_FILE" ]; then
    echo "❌ versions.env file not found: $VERSIONS_ENV_FILE"
    exit 1
fi

# Create backup
cp "$VERSIONS_ENV_FILE" "$VERSIONS_ENV_FILE.backup"

# Update VERSION line in versions.env
sed -i "s/^VERSION=.*/VERSION=$CURRENT_VERSION/" "$VERSIONS_ENV_FILE"

echo "✅ Updated VERSION=$CURRENT_VERSION in $VERSIONS_ENV_FILE"
echo "💾 Backup saved as $VERSIONS_ENV_FILE.backup"

# Show the change
echo ""
echo "📋 Updated versions.env:"
grep "^VERSION=" "$VERSIONS_ENV_FILE"
