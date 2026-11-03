import Cocoa
import InputMethodKit

let info = Bundle.main.infoDictionary ?? [:]
let connectionName = info["InputMethodConnectionName"] as? String ?? "com.endurio.inputmethod.VNK_Connection"

// Must stay alive for the lifetime of the process.
let server = IMKServer(name: connectionName, bundleIdentifier: Bundle.main.bundleIdentifier)

NSApplication.shared.run()
