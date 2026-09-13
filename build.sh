#!/usr/bin/env bash
# build the flatpak bundle into dist/
set -euo pipefail
cd "$(dirname "$0")"

# bump when the bundle changes but the release does not
PORT_RELEASE=1
APP_ID=io.github.Veeiss.wcclient_linux.wcruffle
RUNTIME_REFS=(org.freedesktop.Platform//25.08 org.freedesktop.Sdk//25.08 org.electronjs.Electron2.BaseApp//25.08)

fail() {
    echo "error: $*" >&2
    exit 1
}

for tool in python3 flatpak; do
    command -v "$tool" > /dev/null || fail "$tool not found"
done
if command -v flatpak-builder > /dev/null; then
    FLATPAK_BUILDER=(flatpak-builder)
elif flatpak info org.flatpak.Builder > /dev/null 2>&1; then
    FLATPAK_BUILDER=(flatpak run org.flatpak.Builder)
else
    fail "need flatpak-builder or the org.flatpak.Builder flatpak"
fi
for ref in "${RUNTIME_REFS[@]}"; do
    flatpak info "$ref" > /dev/null 2>&1 || fail "$ref not installed"
done

mkdir -p build
if ! SOURCE_DATE_EPOCH=0 "${FLATPAK_BUILDER[@]}" --user --force-clean --disable-rofiles-fuse \
        --override-source-date-epoch=0 --repo=build/repo build/fp-build "$APP_ID.yml" > build/flatpak-builder.log 2>&1; then
    tail -n 20 build/flatpak-builder.log >&2
    fail "flatpak-builder failed, see build/flatpak-builder.log"
fi

version=$(python3 -c 'import sys, xml.etree.ElementTree as et; print(et.parse(sys.argv[1]).find("releases/release").get("version"))' "$APP_ID.metainfo.xml")
mkdir -p dist
flatpak build-bundle --runtime-repo=https://flathub.org/repo/flathub.flatpakrepo build/repo \
    "dist/wcruffle-${version}-${PORT_RELEASE}.flatpak" "$APP_ID"
ls -l dist/
