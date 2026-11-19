#!/bin/bash
# Build with the Swift SDK for Android: point the C targets at Block.h, curl and libxml2.
set -euo pipefail
args=("$@"); triple=""
for ((i = 0; i < ${#args[@]}; i++)); do [[ "${args[i]}" == --triple ]] && triple="${args[i+1]}"; done
arch="${triple%%-*}"
res=$(find "$HOME" -maxdepth 6 -type d -path '*_android.artifactbundle/swift-android/swift-resources' | head -1)
lib="$res/usr/lib"
hdr="${RUNNER_TEMP:-/tmp}/android-headers"
out="$hdr/$arch"; mkdir -p "$out/lib" "$out/pc"
cp "$lib/swift_static-$arch/android/"{libcurl,libssl,libcrypto,libxml2}.a "$out/lib/"
cat > "$out/pc/libcurl.pc" <<PC
Name: libcurl
Description: curl from the Swift SDK for Android
Version: 8.9.1
Cflags: -I$hdr/curl/include -DCURL_STATICLIB
Libs: -L$out/lib -lcurl -lssl -lcrypto -lz
PC
cat > "$out/pc/libxml-2.0.pc" <<PC
Name: libxml-2.0
Description: libxml2 from the Swift SDK for Android
Version: 2.11.5
Cflags: -I$hdr/libxml2/include -DLIBXML_STATIC
Libs: -L$out/lib -lxml2
PC
export PKG_CONFIG_PATH="$out/pc"
export DISPATCH_INCLUDE_PATH="$lib/swift-$arch"
echo "arch=$arch res=$res"
exec swift build "$@"
