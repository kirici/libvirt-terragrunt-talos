#!/usr/bin/env bash
# Downloads a Talos metal raw image and decompresses it for upload into the libvirt pool.
set -euo pipefail

: "${IMAGE_URL:?IMAGE_URL is required}"
: "${IMAGE_PATH:?IMAGE_PATH is required}"

if [[ -s "${IMAGE_PATH}" ]]; then
    exit 0
fi

mkdir -p "$(dirname "${IMAGE_PATH}")"
partial="${IMAGE_PATH}.part"

# The factory builds an image on first request, so retries matter more than speed. Streaming into zstd avoids ever
# storing the compressed file, and the rename keeps an interrupted download from looking like a finished one.
curl --fail --location --silent --show-error --retry 5 --retry-delay 10 "${IMAGE_URL}" \
    | zstd --decompress --stdout > "${partial}" \
    && mv "${partial}" "${IMAGE_PATH}"
