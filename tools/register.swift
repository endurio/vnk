// Registers and enables the input method at the given bundle path.
import Carbon
import Foundation

let path = CommandLine.arguments[1]
let status = TISRegisterInputSource(URL(fileURLWithPath: path) as CFURL)
print("register: \(status == noErr ? "ok" : "error \(status)")")

func isEnabled(_ src: TISInputSource) -> Bool {
    guard let p = TISGetInputSourceProperty(src, kTISPropertyInputSourceIsEnabled) else { return false }
    return CFBooleanGetValue(Unmanaged<CFBoolean>.fromOpaque(p).takeUnretainedValue())
}

// Right after registering, macOS may still be indexing the bundle and can
// report success without actually enabling it, so check and retry.
let filter = [kTISPropertyBundleID as String: "io.endur.inputmethod.vnk"] as CFDictionary
for _ in 0..<10 {
    let sources = (TISCreateInputSourceList(filter, true)?.takeRetainedValue() as? [TISInputSource]) ?? []
    for src in sources where !isEnabled(src) { TISEnableInputSource(src) }
    if !sources.isEmpty && sources.allSatisfy(isEnabled) {
        print("enabled")
        exit(0)
    }
    Thread.sleep(forTimeInterval: 0.5)
}
print("not enabled yet; add it in System Settings > Keyboard > Input Sources (Vietnamese > VNK Telex)")
