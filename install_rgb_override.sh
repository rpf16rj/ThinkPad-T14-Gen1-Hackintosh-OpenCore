#!/bin/bash
# Instala EDID override p/ forçar RGB no monitor Acer VG240Y V
# Rode: sudo ./install_rgb_override.sh  →  depois reinicie
SRC="$(dirname "$0")/display_overrides/DisplayVendorID-472"
DST="/Library/Displays/Contents/Resources/Overrides/DisplayVendorID-472"
mkdir -p "$DST"
cp "$SRC/DisplayProductID-75a" "$DST/"
echo "Instalado em $DST:"
ls -la "$DST"
echo ""
echo "Reinicie e reconecte o HDMI. Para desfazer: sudo rm -rf '$DST'"
