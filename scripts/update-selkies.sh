#!/bin/bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
versions_file="${repo_dir}/versions.env"
image_tag="ghcr.io/linuxserver/baseimage-selkies:ubunturesolute"

echo "Pulling current AMD64 Ubuntu Resolute Selkies base..."
docker pull --platform linux/amd64 "${image_tag}"

repo_digest="$({
  docker image inspect \
    --format '{{range .RepoDigests}}{{println .}}{{end}}' \
    "${image_tag}"
} | awk '/^ghcr\.io\/linuxserver\/baseimage-selkies@sha256:/{print; exit}')"

digest="${repo_digest##*@}"
if [[ ! "${digest}" =~ ^sha256:[0-9a-f]{64}$ ]]; then
  echo "Could not resolve the immutable Selkies manifest digest." >&2
  exit 1
fi

build_label="$(
  docker image inspect \
    --format '{{index .Config.Labels "build_version"}}' \
    "${image_tag}"
)"
selkies_version="$(sed -nE 's/.*version:-[[:space:]]*([^[:space:]]+).*/\1/p' <<<"${build_label}")"

if [[ ! "${selkies_version}" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "Could not resolve the Selkies version from image label: ${build_label}" >&2
  exit 1
fi

sed -i -E \
  "s|^SELKIES_VERSION=.*$|SELKIES_VERSION=${selkies_version}|" \
  "${versions_file}"
sed -i -E \
  "s|^SELKIES_IMAGE=.*$|SELKIES_IMAGE=${image_tag}@${digest}|" \
  "${versions_file}"

echo
echo "Updated versions.env:"
grep -E '^SELKIES_(VERSION|IMAGE)=' "${versions_file}"
echo
echo "Review the change and increment the revision for each channel you rebuild."
