#!/bin/bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck disable=SC1091
source "${repo_dir}/versions.env"

releases_json="$(curl -fsSL 'https://api.github.com/repos/SubtitleEdit/subtitleedit/releases?per_page=100')"
stable="$(jq -r 'first(.[] | select(.draft == false and .prerelease == false)) | .tag_name' <<<"${releases_json}")"
beta="$(jq -r 'first(.[] | select(.draft == false and .prerelease == true)) | .tag_name' <<<"${releases_json}")"
selkies_token="$(curl -fsSL 'https://ghcr.io/token?scope=repository:linuxserver/baseimage-selkies:pull' | jq -r '.token')"
selkies_digest="$(
  curl -fsSI \
    -H "Authorization: Bearer ${selkies_token}" \
    -H 'Accept: application/vnd.oci.image.index.v1+json' \
    'https://ghcr.io/v2/linuxserver/baseimage-selkies/manifests/ubunturesolute' |
    tr -d '\r' |
    awk -F': ' 'tolower($1) == "docker-content-digest" { print $2 }'
)"
selkies_pinned_digest="${SELKIES_IMAGE##*@}"

printf '%-18s %-20s %-20s\n' COMPONENT PINNED UPSTREAM
printf '%-18s %-20s %-20s\n' 'Selkies' "${SELKIES_VERSION}" "$([[ "${selkies_pinned_digest}" == "${selkies_digest}" ]] && printf 'current' || printf 'update available')"
printf '%-18s %-20s %-20s\n' 'Subtitle Edit' "${SUBTITLE_EDIT_STABLE_VERSION}" "${stable#v}"
printf '%-18s %-20s %-20s\n' 'Subtitle Edit beta' "${SUBTITLE_EDIT_BETA_VERSION}" "${beta#v}"
printf '%-18s %-20s %-20s\n' 'Multimedia/OCR' 'Ubuntu Resolute' 'managed by APT'
