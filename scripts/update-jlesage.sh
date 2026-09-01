#!/bin/bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
versions_file="${repo_dir}/versions.env"

# shellcheck disable=SC1091
# shellcheck source=../versions.env
source "${versions_file}"

image_tag="${JLESAGE_IMAGE%%@*}"

docker pull \
  --platform linux/amd64 \
  "${image_tag}"

repo_digest="$(
  docker image inspect \
    --format '{{range .RepoDigests}}{{println .}}{{end}}' \
    "${image_tag}" |
    awk '/^jlesage\/baseimage-gui@sha256:/{print; exit}'
)"

digest="${repo_digest##*@}"

if [[ ! "${digest}" =~ ^sha256:[0-9a-f]{64}$ ]]; then
  echo "Could not resolve the immutable jlesage image digest." >&2
  exit 1
fi

sed -i -E \
  "s|^JLESAGE_IMAGE=.*$|JLESAGE_IMAGE=${image_tag}@${digest}|" \
  "${versions_file}"

echo "Updated JLESAGE_IMAGE:"
grep '^JLESAGE_IMAGE=' "${versions_file}"
echo
echo "Review and test the base-image change, then increment the image revision."
