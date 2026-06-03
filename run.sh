#!/usr/bin/env zsh
set -euo pipefail

DEVICE="${1:-fenix7}"
PRG="GeekWatchFace.prg"

cd "$(dirname "$0")"

if [ ! -f "$PRG" ]; then
    ./build.sh "$DEVICE"
fi

if ! pgrep -x simulator >/dev/null 2>&1 && ! pgrep -x ConnectIQ >/dev/null 2>&1; then
    connectiq &
    sleep 4
fi

monkeydo "$PRG" "$DEVICE"
