# zmk-corne

ZMK firmware for a Typeractive Corne 6-column wireless keyboard with a
Prospector dongle (Seeed XIAO BLE) and YADS display.

- ZMK v0.3.0 / Zephyr 3.5
- YADS ([zmk-dongle-screen](https://github.com/janpfischer/zmk-dongle-screen)) on `main`

## Architecture

```
                   ┌────────┐
                   │  Host  │
                   └───┬────┘
                       │
                       │ USB
                       │
 ┌──────┐          ┌───┴────┐          ┌───────┐
 │ Left │ ──BLE──► │ Dongle │ ◄──BLE── │ Right │
 │ nano │          │  XIAO  │          │ nano  │
 └──────┘          └────────┘          └───────┘
```

- **Dongle** — central role, XIAO BLE, connects to host via USB. Runs the
  keymap and YADS display. The only target you rebuild for keymap changes.
- **Left / Right** — peripheral role, nice!nano v2. Forward key presses to
  the dongle over BLE. No keymap, no display.
- **5 firmware targets**: `dongle`, `left`, `right`, `reset_xiao`, `reset_nano`.

## Build

### Local (Docker)

Build the image (first time or after changing `west.yml` / `Dockerfile`):

```sh
docker compose build
```

Build firmware — outputs land in `firmware/`:

```sh
docker compose run --rm make          # all 5 targets
docker compose run --rm make dongle   # just the dongle
docker compose run --rm make left     # just the left half
docker compose run --rm make right    # just the right half
docker compose run --rm make reset    # both settings_reset images
```

Shell access (for debugging west/cmake issues):

```sh
docker compose run --rm --entrypoint bash make
```

### Remote (GitHub Actions)

Two workflows in `.github/workflows/`:

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `check.yml` | PR to `main` | Gate: lint (ShellCheck, yamllint) + keymap validation + compile all 5 targets. No artifacts. |
| `build.yml` | Push to `main` / manual | Build all 5 targets in parallel, upload individual + bundled UF2 artifacts. |

To download firmware from a CI build: go to the Actions tab → select the
build run → download the `firmware` artifact (zip with all 5 UF2 files).

### Flashing

1. Enter bootloader:
   - **nice!nano v2** (halves): double-tap the reset button
   - **XIAO BLE** (dongle): double-tap the tiny side button
2. A USB drive appears — drag the `.uf2` file onto it.
3. The board reboots automatically.

**Bond reset** (if halves won't connect to dongle):

1. Flash `reset_xiao.uf2` to the dongle, `reset_nano.uf2` to both halves.
2. Power-cycle all three boards.
3. Re-flash the normal firmware (`dongle.uf2`, `left.uf2`, `right.uf2`).

## File Layout

```
zmk-corne/
├── config/
│   ├── west.yml                        # West manifest (ZMK v0.3.0 + YADS)
│   ├── corne.keymap                    # Keymap (lives on dongle only)
│   ├── corne.conf                      # Shared ZMK settings (debounce)
│   ├── corne_dongle.conf               # Dongle-specific (YADS display)
│   └── boards/shields/corne_dongle/    # Custom dongle shield overlay
│       ├── Kconfig.shield
│       ├── Kconfig.defconfig
│       └── corne_dongle.overlay
├── Dockerfile                          # Build image (zmk-dev-arm:stable)
├── docker-compose.yml                  # Service definition
├── entrypoint.sh                       # Build orchestrator (targets)
├── extract-zephyr-bindings.sh          # Extract ZMK/Zephyr for dts-lsp
├── .github/workflows/
│   ├── build.yml                       # Post-merge build + artifacts
│   └── check.yml                       # PR gate (lint + compile)
├── firmware/                           # Build outputs (.uf2) — gitignored
├── .zmk-app/                           # Extracted ZMK app — gitignored
└── .zephyr-sdk/                        # Extracted Zephyr tree — gitignored
```

## dts-lsp

[dts-lsp](https://github.com/nickel-lang/dts-lsp) provides code intelligence
(go-to-definition, diagnostics, completions) for `.dts`, `.dtsi`, `.keymap`,
and `.overlay` files.

It needs ZMK and Zephyr source trees on the host for bindings and include
resolution. These are extracted from the Docker image:

```sh
./extract-zephyr-bindings.sh
```

This creates two gitignored directories:

| Directory | Source in container | Contents |
|-----------|-------------------|----------|
| `.zmk-app/` | `/workspace/zmk/app` | ZMK DTS bindings, behaviors, include headers, upstream corne shield |
| `.zephyr-sdk/` | `/workspace/zephyr` | Zephyr SoC DTSIs, core bindings, include headers, XIAO BLE board DTS |

Re-run after `docker compose build` if you change `west.yml` (new ZMK/Zephyr
version).

Editor config (neovim): `~/.config/nvim/lua/lsp/dts_lsp.lua`
