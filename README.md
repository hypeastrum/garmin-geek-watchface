# Geek Watchface

A data-dense Garmin Connect IQ watchface with a technical HUD aesthetic — green-on-black, 7-segment time display, left-aligned layout.

## Data fields

- **Time** — 7-segment programmatic rendering (HH:MM:SS)
- **Heart rate** — latest sensor sample
- **Stress** — stress score (amber when high)
- **Steps** — fact / goal
- **Weather** — condition icon + low/current/high temperature
- **Altitude** — barometric, meters
- **UV index** — amber when ≥ 6
- **Sunrise / Sunset** — times with sun/moon symbols
- **Solar intensity** — percentage (solar-equipped watches only)

## Layout

```
  12:34:56          ← 7-segment, large
  HR:72  STR:34     ← heart rate + stress
  STP:8432/10000    ← steps fact/goal
  ☀ 12/18/24°       ← weather icon + lo/cur/hi
  ALT:1284m  UV:3   ← altitude + UV
  ☼06:12 ☾20:45     ← sunrise/sunset
  SOL:82%           ← solar (if available)
```

Labels in dim green, values in bright green. High stress/UV highlighted in amber.

## Supported devices

- fenix 7 / 7S / 7X
- Forerunner 265, 965
- Venu 3
- epix Pro (42/47/51mm)

## Building

Requires the [Garmin Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/).

```bash
# Set up the SDK and add to PATH
export PATH=$PATH:/path/to/connectiq-sdk/bin

# Build for a specific device
monkeyc -d fenix7 -f monkey.jungle -o GeekWatchFace.prg -y /path/to/developer_key.der

# Or use the VS Code Connect IQ extension for a GUI build workflow
```

## Low power mode

Seconds are hidden when the watch enters sleep mode and restored on wake.

## License

MIT
