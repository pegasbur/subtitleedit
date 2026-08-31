#!/bin/bash
set -euo pipefail

version="${1:-5.1.0}"
image_name="${IMAGE_NAME:-goztepe/subtitle-edit}"

if [[ "${version}" == "5.1.0" ]]; then
  default_sha256="455938238969d3aa0a2a500ac061b66161bed1602a96846e01c883322cd5255f"
else
  default_sha256=""
fi

sha256="${SUBTITLE_EDIT_SHA256:-${default_sha256}}"

if [[ -z "${sha256}" ]]; then
  echo "No SHA-256 is bundled for Subtitle Edit ${version}."
  echo "Set SUBTITLE_EDIT_SHA256 to the hash of SubtitleEdit-Linux-x64.tar.gz, then run again."
  exit 1
fi

docker build \
  --pull \
  --build-arg "BUILD_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --build-arg "SUBTITLE_EDIT_VERSION=${version}" \
  --build-arg "SUBTITLE_EDIT_SHA256=${sha256}" \
  --tag "${image_name}:${version}" \
  --tag "${image_name}:latest" \
  .

echo
echo "Built ${image_name}:${version} and ${image_name}:latest"
