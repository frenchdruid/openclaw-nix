#!/bin/sh
set -e

if [ -z "${OPENCLAW_GATEWAY:-}" ]; then
  echo "OPENCLAW_GATEWAY is not set" >&2
  exit 1
fi

export HOME="$(mktemp -d)"

"$OPENCLAW_GATEWAY/bin/openclaw" --help >/dev/null
