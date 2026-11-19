#!/bin/bash
# Fetch the curl and libxml2 headers that match the libraries in the Swift SDK for Android.
set -euo pipefail
dir="${RUNNER_TEMP:-/tmp}/android-headers"
[[ -f "$dir/done" ]] && exit 0
mkdir -p "$dir" && cd "$dir"
curl -fsSL https://github.com/curl/curl/releases/download/curl-8_9_1/curl-8.9.1.tar.gz | tar xz
mkdir -p curl && cp -R curl-8.9.1/include curl/
curl -fsSL https://download.gnome.org/sources/libxml2/2.11/libxml2-2.11.5.tar.xz | tar xJ
cmake -S libxml2-2.11.5 -B xml-build -DLIBXML2_WITH_PYTHON=OFF -DLIBXML2_WITH_ICU=OFF -DLIBXML2_WITH_ICONV=OFF -DLIBXML2_WITH_LZMA=OFF -DLIBXML2_WITH_ZLIB=OFF -DLIBXML2_WITH_TESTS=OFF -DLIBXML2_WITH_PROGRAMS=OFF > /dev/null
mkdir -p libxml2 && cp -R libxml2-2.11.5/include libxml2/ && cp xml-build/libxml/xmlversion.h libxml2/include/libxml/
touch "$dir/done"
