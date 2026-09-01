#!/bin/bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
versions_file="${repo_dir}/versions.env"
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
    echo "Usage: scripts/update-subtitleedit.sh [stable|beta]" >&2
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

current_version="$(sed -n "s/^${variable_prefix}_VERSION=//p" "${versions_file}")"

sed -i -E \
  -e "s/^${variable_prefix}_VERSION=.*/${variable_prefix}_VERSION=${version}/" \
  -e "s/^${variable_prefix}_SHA256=.*/${variable_prefix}_SHA256=${digest}/" \
  "${versions_file}"

if [[ "${version}" != "${current_version}" ]]; then
  sed -i -E \
    "s/^${variable_prefix}_REVISION=.*/${variable_prefix}_REVISION=1/" \
    "${versions_file}"
fi

echo "Pinned ${channel} to Subtitle Edit ${version}"
git -C "${repo_dir}" diff -- versions.env
