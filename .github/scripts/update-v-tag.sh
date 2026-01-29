#!/usr/bin/env bash
set -euo pipefail

VERSION="$1"

# Extract breaking version (2.1.1 -> 2)
BREAKING_VERSION=$(echo "${VERSION}" | cut -d. -f1)
V_TAG="v${BREAKING_VERSION}"

# Delete local v tag if it exists
git tag -d "${V_TAG}" 2>/dev/null || true

# Delete remote v tag if it exists
git push origin ":refs/tags/${V_TAG}" || true

# Recreate v tag pointing to the release commit
git tag $V_TAG -m "${VERSION}"

# Push tag
git push origin $V_TAG

echo "Successfully updated v tag ${V_TAG} -> ${VERSION}"
