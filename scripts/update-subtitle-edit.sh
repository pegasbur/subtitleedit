#!/bin/bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
channel="${1:-}"

case "${channel}" in
  stable)
    selector='select(.draft == false and .prerelease == false)'
    variable_prefix='SUBTITLE_EDIT_STABLE'
    ;;
  beta)
    selector='select(.draft == false and .prerelease == true)'
    variable_prefix='SUBTITLE_EDIT_BETA'
    ;;
  *)
    echo "Usage: scripts/update-subtitle-edit.sh [stable|beta]" >&2
    exit 2
    ;;
esac

release="$(
  curl -fsSL 'https://api.github.com/repos/SubtitleEdit/subtitleedit/releases?per_page=100' |
    jq -c "first(.[] | ${selector})"
)"

version="$(jq -r '.tag_name | ltrimstr("v")' <<<"${release}")"
digest="$(
  jq -r '.assets[] | select(.name == "SubtitleEdit-Linux-x64.tar.gz") | .digest | ltrimstr("sha256:")' <<<"${release}"
)"

if [[ -z "${version}" || ! "${digest}" =~ ^[0-9a-f]{64}$ ]]; then
  echo "The release or its SHA-256 digest could not be resolved." >&2
  exit 1
fi

sed -i -E \
  -e "s/^${variable_prefix}_VERSION=.*/${variable_prefix}_VERSION=${version}/" \
  -e "s/^${variable_prefix}_SHA256=.*/${variable_prefix}_SHA256=${digest}/" \
  "${repo_dir}/versions.env"

echo "Pinned ${channel} to Subtitle Edit ${version}"
git -C "${repo_dir}" diff -- versions.env
