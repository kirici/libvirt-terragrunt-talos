#!/usr/bin/env bash
# Blocks until a TCP port accepts connections, or fails after a timeout.
set -euo pipefail

usage="usage: wait-for-port.sh <host> <port> [timeout_seconds]"
host="${1:?${usage}}"
port="${2:?${usage}}"
timeout_s="${3:-300}"

deadline=$((SECONDS + timeout_s))

# The subshell opens and immediately closes the connection; bash's /dev/tcp avoids needing nc on the host.
until (exec 3<> "/dev/tcp/${host}/${port}") 2> /dev/null; do
    if ((SECONDS >= deadline)); then
        echo "timed out after ${timeout_s}s waiting for ${host}:${port}" >&2
        exit 1
    fi
    sleep 3
done
