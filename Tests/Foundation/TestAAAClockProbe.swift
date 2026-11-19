// Probe only: prints how the clocks behave on the CI emulator. Not for upstream.

#if canImport(Android)
@preconcurrency import Android
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif
import Dispatch

private func read(_ c: clockid_t) -> Double {
    var t = timespec()
    clock_gettime(c, &t)
    return Double(t.tv_sec) + Double(t.tv_nsec) / 1e9
}

class TestAAAClockProbe: XCTestCase {
    func test_clockProbe() {
        var u = utsname()
        uname(&u)
        let release = withUnsafeBytes(of: &u.release) { String(cString: $0.bindMemory(to: CChar.self).baseAddress!) }
        let machine = withUnsafeBytes(of: &u.machine) { String(cString: $0.bindMemory(to: CChar.self).baseAddress!) }
        print("CLOCKPROBE kernel \(release) \(machine)")
        print("CLOCKPROBE REALTIME \(read(CLOCK_REALTIME)) MONOTONIC \(read(CLOCK_MONOTONIC)) RAW \(read(CLOCK_MONOTONIC_RAW)) BOOTTIME \(read(CLOCK_BOOTTIME))")

        var prev = read(CLOCK_MONOTONIC_RAW)
        var back = 0
        var maxStep = 0.0
        var minStep = 0.0
        for _ in 0..<200_000 {
            let x = read(CLOCK_MONOTONIC_RAW)
            let d = x - prev
            if d < 0 { back += 1 }
            maxStep = max(maxStep, d)
            minStep = min(minStep, d)
            prev = x
        }
        print("CLOCKPROBE RAW loop back=\(back) maxStep=\(maxStep) minStep=\(minStep)")

        let m0 = read(CLOCK_MONOTONIC), r0 = read(CLOCK_MONOTONIC_RAW)
        Thread.sleep(forTimeInterval: 2)
        let m1 = read(CLOCK_MONOTONIC), r1 = read(CLOCK_MONOTONIC_RAW)
        print("CLOCKPROBE sleep 2 s: MONOTONIC +\(m1 - m0) RAW +\(r1 - r0)")

        let lo = UnsafeMutableBufferPointer<Double>.allocate(capacity: 64)
        let hi = UnsafeMutableBufferPointer<Double>.allocate(capacity: 64)
        nonisolated(unsafe) let (l, h) = (lo, hi)
        DispatchQueue.concurrentPerform(iterations: 64) { i in
            var a = Double.infinity, b = -Double.infinity
            for _ in 0..<1000 {
                let m = read(CLOCK_MONOTONIC)
                let r = read(CLOCK_MONOTONIC_RAW)
                a = min(a, r - m); b = max(b, r - m)
            }
            l[i] = a; h[i] = b
        }
        print("CLOCKPROBE threads RAW-MONOTONIC min=\(lo.min()!) max=\(hi.max()!)")
    }
}
