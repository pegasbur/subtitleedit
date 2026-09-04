#!/bin/bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if (( $# != 0 )); then
  echo "Usage: ./build.sh" >&2
  echo "Only the stable Subtitle Edit channel is built." >&2
  exit 2
fi

# shellcheck disable=SC1091
source "${repo_dir}/versions.env"

image_name="${IMAGE_NAME:-pegasbur/subtitleedit}"
channel_tag="${CHANNEL_TAG:-latest}"
version_tag="${SUBTITLE_EDIT_STABLE_VERSION}-r${SUBTITLE_EDIT_JLESAGE_REVISION}"
build_date="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
vcs_ref="$(git -C "${repo_dir}" rev-parse HEAD 2>/dev/null || printf 'local')"

for image in "${DOTNET_SDK_IMAGE}" "${JLESAGE_IMAGE}"; do
  if [[ ! "${image}" =~ @sha256:[0-9a-f]{64}$ ]]; then
    echo "Image is not pinned by digest: ${image}" >&2
    exit 1
  fi
done

for commit in "${SUBTITLE_EDIT_STABLE_COMMIT}" "${AVALONIA_COMMIT}"; do
  if [[ ! "${commit}" =~ ^[0-9a-f]{40}$ ]]; then
    echo "Invalid Git commit: ${commit}" >&2
    exit 1
  fi
done

if [[ ! "${AVALONIA_X11_NUPKG_SHA256}" =~ ^[0-9a-f]{64}$ ]]; then
  echo "Invalid Avalonia.X11 package SHA-256." >&2
  exit 1
fi

docker build \
  --pull \
  --file "${repo_dir}/container/Dockerfile" \
  --build-arg "DOTNET_SDK_IMAGE=${DOTNET_SDK_IMAGE}" \
  --build-arg "BASE_IMAGE=${JLESAGE_IMAGE}" \
  --build-arg "BUILD_DATE=${build_date}" \
  --build-arg "VCS_REF=${vcs_ref}" \
  --build-arg "IMAGE_REVISION=${SUBTITLE_EDIT_JLESAGE_REVISION}" \
  --build-arg "SUBTITLE_EDIT_VERSION=${SUBTITLE_EDIT_STABLE_VERSION}" \
  --build-arg "SUBTITLE_EDIT_COMMIT=${SUBTITLE_EDIT_STABLE_COMMIT}" \
  --build-arg "AVALONIA_VERSION=${AVALONIA_VERSION}" \
  --build-arg "AVALONIA_COMMIT=${AVALONIA_COMMIT}" \
  --build-arg "AVALONIA_X11_PACKAGE_VERSION=${AVALONIA_X11_PACKAGE_VERSION}" \
  --build-arg "AVALONIA_X11_NUPKG_SHA256=${AVALONIA_X11_NUPKG_SHA256}" \
  --tag "${image_name}:${version_tag}" \
  --tag "${image_name}:${channel_tag}" \
  "${repo_dir}"

echo
echo "Built ${image_name}:${version_tag}"
echo "Built ${image_name}:${channel_tag}"
