#!/usr/bin/env zsh
set -euo pipefail

KEY="${GARMIN_DEV_KEY:-$HOME/developer_key.der}"
DEVICE="${1:-fenix7}"
OUT="GeekWatchFace.prg"

if [ ! -f "$KEY" ]; then
    echo "Developer key not found at: $KEY" >&2
    echo "Set GARMIN_DEV_KEY to the absolute path of your .der key." >&2
    exit 1
fi

cd "$(dirname "$0")"
monkeyc -d "$DEVICE" -f monkey.jungle -o "$OUT" -y "$KEY" -w -l 0
echo "Built $OUT for $DEVICE"
