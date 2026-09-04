#!/bin/bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

export IMAGE_NAME="${IMAGE_NAME:-subtitleedit-jlesage}"
export CHANNEL_TAG="${CHANNEL_TAG:-test}"

exec "${repo_dir}/build.sh"
