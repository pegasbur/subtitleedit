#!/bin/bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
versions_file="${repo_dir}/versions.env"
mode="${1:-check}"

if [[ "${mode}" != "check" && "${mode}" != "apply" ]]; then
  echo "Usage: scripts/update-subtitleedit.sh [check|apply]" >&2
  exit 2
fi

# shellcheck disable=SC1091
source "${versions_file}"

release="$(
  curl -fsSL \
    'https://api.github.com/repos/SubtitleEdit/subtitleedit/releases?per_page=100' |
    jq -c 'first(.[] | select(.draft == false and .prerelease == false))'
)"

tag="$(jq -r '.tag_name' <<<"${release}")"
version="${tag#v}"

commit="$(
  git ls-remote \
    https://github.com/SubtitleEdit/subtitleedit.git \
    "refs/tags/${tag}^{}" \
    "refs/tags/${tag}" |
    awk '
      $2 ~ /\^\{\}$/ { peeled=$1 }
      $2 !~ /\^\{\}$/ { direct=$1 }
      END { print peeled != "" ? peeled : direct }
    '
)"

if [[ ! "${commit}" =~ ^[0-9a-f]{40}$ ]]; then
  echo "Could not resolve the upstream release commit." >&2
  exit 1
fi

echo "Pinned:   ${SUBTITLE_EDIT_STABLE_VERSION} ${SUBTITLE_EDIT_STABLE_COMMIT}"
echo "Upstream: ${version} ${commit}"

if [[ "${version}" == "${SUBTITLE_EDIT_STABLE_VERSION}" &&
      "${commit}" == "${SUBTITLE_EDIT_STABLE_COMMIT}" ]]; then
  echo "Subtitle Edit is current."
  exit 0
fi

if [[ "${mode}" == "check" ]]; then
  echo
  echo "An update is available."
  echo "Re-run with 'apply' only when ready to rebase and test both local patches."
  exit 0
fi

sed -i -E \
  -e "s/^SUBTITLE_EDIT_STABLE_VERSION=.*/SUBTITLE_EDIT_STABLE_VERSION=${version}/" \
  -e "s/^SUBTITLE_EDIT_STABLE_COMMIT=.*/SUBTITLE_EDIT_STABLE_COMMIT=${commit}/" \
  -e 's/^SUBTITLE_EDIT_JLESAGE_REVISION=.*/SUBTITLE_EDIT_JLESAGE_REVISION=1/' \
  "${versions_file}"

echo
echo "Updated source pins. The Avalonia and Subtitle Edit patches must now be rebased and tested."
git -C "${repo_dir}" diff -- versions.env
