#!/usr/bin/env bash
set -euo pipefail

ZMK_APP="/workspace/zmk/app"
CONFIG="/zmk-config"
OUTPUT="/firmware"

# Board names — change these for Path B (Zephyr 4.1)
XIAO_BOARD="seeeduino_xiao_ble"
NANO_BOARD="nice_nano_v2"

build_dongle() {
	echo "==> Building dongle (central + YADS screen)..."
	west build -p -s "$ZMK_APP" -d "$ZMK_APP/build/dongle" \
		-b "$XIAO_BOARD" \
		-- -DSHIELD="corne_dongle dongle_screen" \
		-DZMK_CONFIG="$CONFIG"
	cp "$ZMK_APP/build/dongle/zephyr/zmk.uf2" "$OUTPUT/dongle.uf2"
	echo "    → $OUTPUT/dongle.uf2"
}

build_left() {
	echo "==> Building left half (peripheral)..."
	west build -p -s "$ZMK_APP" -d "$ZMK_APP/build/left" \
		-b "$NANO_BOARD" \
		-- -DSHIELD="corne_left" \
		-DCONFIG_ZMK_SPLIT=y \
		-DCONFIG_ZMK_SPLIT_ROLE_CENTRAL=n \
		-DZMK_CONFIG="$CONFIG"
	cp "$ZMK_APP/build/left/zephyr/zmk.uf2" "$OUTPUT/left.uf2"
	echo "    → $OUTPUT/left.uf2"
}

build_right() {
	echo "==> Building right half (peripheral)..."
	west build -p -s "$ZMK_APP" -d "$ZMK_APP/build/right" \
		-b "$NANO_BOARD" \
		-- -DSHIELD="corne_right" \
		-DCONFIG_ZMK_SPLIT=y \
		-DCONFIG_ZMK_SPLIT_ROLE_CENTRAL=n \
		-DZMK_CONFIG="$CONFIG"
	cp "$ZMK_APP/build/right/zephyr/zmk.uf2" "$OUTPUT/right.uf2"
	echo "    → $OUTPUT/right.uf2"
}

build_reset() {
	echo "==> Building settings_reset (XIAO)..."
	west build -p -s "$ZMK_APP" -d "$ZMK_APP/build/reset_xiao" \
		-b "$XIAO_BOARD" \
		-- -DSHIELD="settings_reset"
	cp "$ZMK_APP/build/reset_xiao/zephyr/zmk.uf2" "$OUTPUT/reset_xiao.uf2"
	echo "    → $OUTPUT/reset_xiao.uf2"

	echo "==> Building settings_reset (nice!nano)..."
	west build -p -s "$ZMK_APP" -d "$ZMK_APP/build/reset_nano" \
		-b "$NANO_BOARD" \
		-- -DSHIELD="settings_reset"
	cp "$ZMK_APP/build/reset_nano/zephyr/zmk.uf2" "$OUTPUT/reset_nano.uf2"
	echo "    → $OUTPUT/reset_nano.uf2"
}

# Default to building everything if no arguments given
TARGETS=("${@:-all}")

for target in "${TARGETS[@]}"; do
	case "$target" in
	dongle) build_dongle ;;
	left) build_left ;;
	right) build_right ;;
	reset) build_reset ;;
	all)
		build_dongle
		build_left
		build_right
		build_reset
		;;
	*)
		echo "Unknown target: $target"
		echo "Usage: docker compose run --rm zmk [dongle|left|right|reset|all]"
		exit 1
		;;
	esac
done

echo ""
echo "==> Done. Firmware files:"
ls -la "$OUTPUT"/*.uf2 2>/dev/null || echo "    (none)"
