#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOME_DIR="${HOME}"
ICON_SRC="$ROOT/icon.svg"
HICOLOR="$HOME_DIR/.local/share/icons/hicolor"
APP_DIR="$HOME_DIR/.local/share/applications"
BIN_DIR="$HOME_DIR/.local/bin"
OPT_DIR="$HOME_DIR/.local/opt/shadowfetch-darts"
SIZES=(16 22 24 32 48 64 128 256 512)

mkdir -p "$HICOLOR/scalable/apps" "$APP_DIR" "$BIN_DIR" "$OPT_DIR" \
	"$ROOT/assets/icons/hicolor/scalable/apps"

cp "$ICON_SRC" "$HICOLOR/scalable/apps/shadowfetch-darts.svg"
cp "$ICON_SRC" "$ROOT/assets/icons/shadowfetch-darts.svg"
cp "$ICON_SRC" "$ROOT/assets/icons/hicolor/scalable/apps/shadowfetch-darts.svg"

if ! command -v rsvg-convert >/dev/null 2>&1; then
	echo "Missing rsvg-convert. Install with: sudo apt install librsvg2-bin desktop-file-utils" >&2
else
	for sz in "${SIZES[@]}"; do
		mkdir -p "$HICOLOR/${sz}x${sz}/apps" "$ROOT/assets/icons/hicolor/${sz}x${sz}/apps"
		rsvg-convert -w "$sz" -h "$sz" "$ICON_SRC" -o "$HICOLOR/${sz}x${sz}/apps/shadowfetch-darts.png"
		cp "$HICOLOR/${sz}x${sz}/apps/shadowfetch-darts.png" \
			"$ROOT/assets/icons/hicolor/${sz}x${sz}/apps/shadowfetch-darts.png"
	done
fi

SRC_BIN="$ROOT/export/linux/shadowfetch-darts.x86_64"
if [[ -x "$SRC_BIN" ]]; then
	cp -f "$SRC_BIN" "$OPT_DIR/shadowfetch-darts"
	chmod +x "$OPT_DIR/shadowfetch-darts"
	ln -sfn "$OPT_DIR/shadowfetch-darts" "$BIN_DIR/shadowfetch-darts"
else
	cat > "$BIN_DIR/shadowfetch-darts" <<EOF
#!/usr/bin/env bash
set -euo pipefail
BIN="\$HOME/.local/opt/shadowfetch-darts/shadowfetch-darts"
if [[ -x "\$BIN" ]]; then
	exec "\$BIN" "\$@"
fi
echo "Shadowfetch Darts: exported Linux build not found. Run tools/export_linux.sh then tools/install_linux.sh" >&2
exit 1
EOF
	chmod +x "$BIN_DIR/shadowfetch-darts"
fi

cat > "$APP_DIR/shadowfetch-darts.desktop" <<EOF
[Desktop Entry]
Type=Application
Version=1.0
Name=Shadowfetch Darts
GenericName=Darts
Comment=301, 501, Cricket, and Around the Clock for Linux
Exec=shadowfetch-darts
TryExec=shadowfetch-darts
Icon=shadowfetch-darts
Terminal=false
Categories=Game;
Keywords=darts;301;501;cricket;shadowfetch;
StartupNotify=true
StartupWMClass=Shadowfetch Darts
EOF

if command -v desktop-file-validate >/dev/null 2>&1; then
	desktop-file-validate "$APP_DIR/shadowfetch-darts.desktop"
else
	echo "Missing desktop-file-validate. Install with: sudo apt install desktop-file-utils" >&2
fi
update-desktop-database "$APP_DIR" >/dev/null 2>&1 || true
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
	gtk-update-icon-cache -f "$HICOLOR" >/dev/null 2>&1 || true
fi

echo "Installed Shadowfetch Darts launcher:"
echo "  $BIN_DIR/shadowfetch-darts"
echo "  $APP_DIR/shadowfetch-darts.desktop"
echo "  $HICOLOR/scalable/apps/shadowfetch-darts.svg"
