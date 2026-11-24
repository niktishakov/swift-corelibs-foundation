#!/bin/bash
# Fork test only: build the Foundation tests for x86_64 Android API 26 with the
# Swift SDK, pointing the C targets at Block.h, curl and libxml2.
set -euxo pipefail
T=x86_64-unknown-linux-android26; arch=x86_64
res=$( (find $HOME/.swiftpm $HOME/.config/swiftpm -maxdepth 4 -type d -path '*_android.artifactbundle/swift-android/swift-resources' 2>/dev/null || true) | head -1)
lib=$res/usr/lib; hdr=$RUNNER_TEMP/android-headers; out=$hdr/$arch; mkdir -p $out/lib $out/pc
cp $lib/swift_static-$arch/android/{libcurl,libssl,libcrypto,libxml2}.a $out/lib/
cat > $out/pc/libcurl.pc <<PC
Name: libcurl
Description: curl
Version: 8.9.1
Cflags: -I$hdr/curl/include -DCURL_STATICLIB
Libs: -L$out/lib -lcurl -lssl -lcrypto -lz
PC
cat > $out/pc/libxml-2.0.pc <<PC
Name: libxml-2.0
Description: libxml2
Version: 2.11.5
Cflags: -I$hdr/libxml2/include -DLIBXML_STATIC
Libs: -L$out/lib -lxml2
PC
export PKG_CONFIG_PATH=$out/pc DISPATCH_INCLUDE_PATH=$lib/swift-$arch
ndklib=$(find $ANDROID_NDK_HOME/toolchains/llvm/prebuilt -type d -path "*sysroot/usr/lib/${arch}-linux-android" | head -1)
swift build --build-tests --swift-sdk $T --scratch-path $RUNNER_TEMP/build -Xlinker -rpath-link -Xlinker $ndklib
st=$RUNNER_TEMP/stage; mkdir -p $st
find $RUNNER_TEMP/build \( -name '*.xctest' -o -name '*.bundle' -o -name '*.resources' -o -name '*-test-runner' -o -name '*.so' -o -name xdgTestHelper -o -name plutil \) -not -path '*/checkouts/*' -exec cp -a {} $st/ \;
cp $lib/swift-$arch/android/*.so $st/
cp $(find $ANDROID_NDK_HOME -path "*${arch}-linux-android/libc++_shared.so" | head -1) $st/
ls -la $st | head -40
