import Cocoa
import InputMethodKit

let info = Bundle.main.infoDictionary ?? [:]
let connectionName = info["InputMethodConnectionName"] as? String ?? "io.endur.inputmethod.vnk_Connection"

// Must stay alive for the lifetime of the process.
let server = IMKServer(name: connectionName, bundleIdentifier: Bundle.main.bundleIdentifier)

NSApplication.shared.run()
