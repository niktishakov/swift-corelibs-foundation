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
# PROBE ONLY: replace the SDK libcurl with curl 8.9.1 built without CLOCK_MONOTONIC_RAW.
ndk="${ANDROID_NDK_HOME:-${ANDROID_NDK_ROOT:-}}"
[[ -f "$ndk/build/cmake/android.toolchain.cmake" ]] || ndk=$(dirname "$(dirname "$(dirname "$(find / -name android.toolchain.cmake -path '*build/cmake*' 2>/dev/null | head -1)")")")
case "$arch" in aarch64) abi=arm64-v8a ;; armv7) abi=armeabi-v7a ;; *) abi="$arch" ;; esac
api="${triple##*android}"
cmake -G Ninja -S "$hdr/curl-8.9.1" -B "$hdr/curl-build-$arch" -DANDROID_ABI="$abi" -DANDROID_PLATFORM="android-$api" \
  -DCMAKE_TOOLCHAIN_FILE="$ndk/build/cmake/android.toolchain.cmake" -DCMAKE_BUILD_TYPE=Release \
  -DCURL_ENABLE_SSL=OFF -DCURL_USE_LIBSSH2=OFF -DCURL_USE_LIBPSL=OFF -DCURL_BROTLI=OFF -DCURL_ZSTD=OFF -DUSE_NGHTTP2=OFF -DUSE_LIBIDN2=OFF \
  -DENABLE_WEBSOCKETS=ON -DBUILD_CURL_EXE=NO -DBUILD_SHARED_LIBS=OFF -DBUILD_STATIC_LIBS=ON -DBUILD_TESTING=OFF \
  -DHAVE_CLOCK_GETTIME_MONOTONIC_RAW=OFF > "$hdr/curl-cmake-$arch.log"
grep -n 'MONOTONIC' "$hdr/curl-build-$arch/lib/curl_config.h"
ninja -C "$hdr/curl-build-$arch" > /dev/null
cp "$hdr/curl-build-$arch/lib/libcurl.a" "$out/lib/libcurl.a"
echo "PROBE: using curl without CLOCK_MONOTONIC_RAW (ndk=$ndk abi=$abi api=$api)"
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
