#!/bin/bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck disable=SC1091
source "${repo_dir}/versions.env"

resolve_image_digest() {
  docker buildx imagetools inspect "${1%%@*}" |
    awk '$1 == "Digest:" { print $2; exit }'
}

release="$(
  curl -fsSL \
    'https://api.github.com/repos/SubtitleEdit/subtitleedit/releases?per_page=100' |
    jq -c 'first(.[] | select(.draft == false and .prerelease == false))'
)"

upstream_tag="$(jq -r '.tag_name' <<<"${release}")"
upstream_version="${upstream_tag#v}"

upstream_commit="$(
  git ls-remote \
    https://github.com/SubtitleEdit/subtitleedit.git \
    "refs/tags/${upstream_tag}^{}" \
    "refs/tags/${upstream_tag}" |
    awk '
      $2 ~ /\^\{\}$/ { peeled=$1 }
      $2 !~ /\^\{\}$/ { direct=$1 }
      END { print peeled != "" ? peeled : direct }
    '
)"

jlesage_upstream_digest="$(resolve_image_digest "${JLESAGE_IMAGE}")"
dotnet_upstream_digest="$(resolve_image_digest "${DOTNET_SDK_IMAGE}")"

jlesage_pinned_digest="${JLESAGE_IMAGE##*@}"
dotnet_pinned_digest="${DOTNET_SDK_IMAGE##*@}"

printf '%-22s %s\n' 'Component' 'Status'
printf '%-22s %s\n' \
  'Subtitle Edit' \
  "$(
    if [[ "${SUBTITLE_EDIT_STABLE_VERSION}" == "${upstream_version}" &&
          "${SUBTITLE_EDIT_STABLE_COMMIT}" == "${upstream_commit}" ]]; then
      printf 'current (%s)' "${SUBTITLE_EDIT_STABLE_VERSION}"
    else
      printf 'update available (%s -> %s)' \
        "${SUBTITLE_EDIT_STABLE_VERSION}" \
        "${upstream_version}"
    fi
  )"

printf '%-22s %s\n' \
  'jlesage base image' \
  "$(
    if [[ "${jlesage_pinned_digest}" == "${jlesage_upstream_digest}" ]]; then
      printf 'current'
    else
      printf 'update available'
    fi
  )"

printf '%-22s %s\n' \
  '.NET SDK image' \
  "$(
    if [[ "${dotnet_pinned_digest}" == "${dotnet_upstream_digest}" ]]; then
      printf 'current'
    else
      printf 'update available'
    fi
  )"

printf '%-22s %s\n' \
  'Avalonia X11' \
  "${AVALONIA_VERSION} with local window-hints patch"

printf '%-22s %s\n' \
  'Multimedia/OCR' \
  'managed by Ubuntu APT'
