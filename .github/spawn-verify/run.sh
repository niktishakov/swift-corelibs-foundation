#!/bin/bash
# Fork test only: run TestProcess and TestNSKeyedUnarchiver on the emulator.
st=$1; D=/data/local/tmp/t
adb shell mkdir -p $D
adb push $st/. $D/ > /dev/null
echo "api: $(adb shell getprop ro.build.version.sdk) user: $(adb shell id -un)"
R=$(cd $st && ls | grep -E -- '-test-runner$|\.xctest$' | head -1)
adb shell "cd $D && chmod 755 ./$R ./xdgTestHelper; LD_LIBRARY_PATH=$D ./$R --testing-library xctest TestFoundation.TestProcess TestFoundation.TestNSKeyedUnarchiver" > $st/../result.txt 2>&1
grep -E "Test Case .*(passed|failed|skipped)|Executed .* tests" $st/../result.txt | sed -E 's/ \([0-9.]+ seconds\)//' | sort | uniq -c | sort -rn | head -80
echo "--- totals:"; grep -E "Executed [0-9]+ tests" $st/../result.txt | tail -2
true
