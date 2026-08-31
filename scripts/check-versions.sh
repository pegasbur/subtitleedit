#!/bin/bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck disable=SC1091
source "${repo_dir}/versions.env"

releases_json="$(curl -fsSL 'https://api.github.com/repos/SubtitleEdit/subtitleedit/releases?per_page=100')"
stable="$(jq -r 'first(.[] | select(.draft == false and .prerelease == false)) | .tag_name' <<<"${releases_json}")"
beta="$(jq -r 'first(.[] | select(.draft == false and .prerelease == true)) | .tag_name' <<<"${releases_json}")"
mpv="$(curl -fsSL https://api.github.com/repos/mpv-player/mpv/releases/latest | jq -r '.tag_name')"
libplacebo="$(curl -fsSL https://api.github.com/repos/haasn/libplacebo/releases/latest | jq -r '.tag_name')"
tesseract="$(curl -fsSL https://api.github.com/repos/tesseract-ocr/tesseract/releases/latest | jq -r '.tag_name')"
ffmpeg="$(curl -fsSL https://ffmpeg.org/releases/ | grep -oE 'ffmpeg-[0-9]+\.[0-9]+(\.[0-9]+)?\.tar\.xz' | sed -E 's/^ffmpeg-//; s/\.tar\.xz$//' | sort -V | tail -n 1)"
selkies_token="$(curl -fsSL 'https://ghcr.io/token?scope=repository:linuxserver/baseimage-selkies:pull' | jq -r '.token')"
selkies_digest="$(
  curl -fsSI \
    -H "Authorization: Bearer ${selkies_token}" \
    -H 'Accept: application/vnd.oci.image.index.v1+json' \
    'https://ghcr.io/v2/linuxserver/baseimage-selkies/manifests/debiantrixie' |
    tr -d '\r' |
    awk -F': ' 'tolower($1) == "docker-content-digest" { print $2 }'
)"
selkies_pinned_digest="${SELKIES_IMAGE##*@}"

printf '%-18s %-20s %-20s\n' COMPONENT PINNED UPSTREAM
printf '%-18s %-20s %-20s\n' 'Selkies' "${SELKIES_VERSION}" "$([[ "${selkies_pinned_digest}" == "${selkies_digest}" ]] && printf 'current' || printf 'update available')"
printf '%-18s %-20s %-20s\n' 'Subtitle Edit' "${SUBTITLE_EDIT_STABLE_VERSION}" "${stable#v}"
printf '%-18s %-20s %-20s\n' 'Subtitle Edit beta' "${SUBTITLE_EDIT_BETA_VERSION}" "${beta#v}"
printf '%-18s %-20s %-20s\n' 'FFmpeg' "${FFMPEG_VERSION}" "${ffmpeg}"
printf '%-18s %-20s %-20s\n' 'libplacebo' "${LIBPLACEBO_VERSION}" "${libplacebo#v}"
printf '%-18s %-20s %-20s\n' 'MPV' "${MPV_VERSION}" "${mpv#v}"
printf '%-18s %-20s %-20s\n' 'Tesseract' "${TESSERACT_VERSION}" "${tesseract#v}"
