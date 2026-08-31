#!/bin/bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${repo_dir}"

# shellcheck disable=SC1091
source "${repo_dir}/versions.env"

channel="${1:-stable}"
image_name="${IMAGE_NAME:-pegasbur/subtitle-edit}"

case "${channel}" in
  stable)
    subtitle_edit_version="${SUBTITLE_EDIT_STABLE_VERSION}"
    subtitle_edit_sha256="${SUBTITLE_EDIT_STABLE_SHA256}"
    channel_tag="latest"
    ;;
  beta)
    subtitle_edit_version="${SUBTITLE_EDIT_BETA_VERSION}"
    subtitle_edit_sha256="${SUBTITLE_EDIT_BETA_SHA256}"
    channel_tag="beta"
    ;;
  *)
    echo "Usage: ./build.sh [stable|beta]" >&2
    exit 2
    ;;
esac

for digest in \
  "${subtitle_edit_sha256}" \
  "${SUBTITLE_EDIT_ICON_SHA256}" \
  "${FFMPEG_SHA256}" \
  "${MPV_SHA256}" \
  "${TESSERACT_SHA256}"
do
  if [[ ! "${digest}" =~ ^[0-9a-f]{64}$ ]]; then
    echo "Invalid SHA-256 value: ${digest}" >&2
    exit 1
  fi
done

if [[ ! "${SELKIES_IMAGE}" =~ @sha256:[0-9a-f]{64}$ ]]; then
  echo "SELKIES_IMAGE must include an immutable sha256 digest." >&2
  exit 1
fi

version_tag="${subtitle_edit_version}-r${IMAGE_REVISION}"
build_date="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
vcs_ref="$(git rev-parse HEAD 2>/dev/null || printf 'local')"

docker build \
  --pull \
  --build-arg "BASE_IMAGE=${SELKIES_IMAGE}" \
  --build-arg "BUILD_DATE=${build_date}" \
  --build-arg "VCS_REF=${vcs_ref}" \
  --build-arg "IMAGE_REVISION=${IMAGE_REVISION}" \
  --build-arg "SELKIES_VERSION=${SELKIES_VERSION}" \
  --build-arg "SUBTITLE_EDIT_VERSION=${subtitle_edit_version}" \
  --build-arg "SUBTITLE_EDIT_SHA256=${subtitle_edit_sha256}" \
  --build-arg "SUBTITLE_EDIT_ICON_SHA256=${SUBTITLE_EDIT_ICON_SHA256}" \
  --build-arg "FFMPEG_VERSION=${FFMPEG_VERSION}" \
  --build-arg "FFMPEG_SHA256=${FFMPEG_SHA256}" \
  --build-arg "MPV_VERSION=${MPV_VERSION}" \
  --build-arg "MPV_SHA256=${MPV_SHA256}" \
  --build-arg "TESSERACT_VERSION=${TESSERACT_VERSION}" \
  --build-arg "TESSERACT_SHA256=${TESSERACT_SHA256}" \
  --tag "${image_name}:${version_tag}" \
  --tag "${image_name}:${channel_tag}" \
  .

echo
echo "Built ${image_name}:${version_tag} and ${image_name}:${channel_tag}"
