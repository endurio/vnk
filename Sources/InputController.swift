import Cocoa
import InputMethodKit

// One instance per client text field. The name must match
// InputMethodServerControllerClass in Info.plist.
@objc(VNKInputController)
class VNKInputController: IMKInputController {
    private var engine = TelexEngine()

    private enum Key {
        static let backspace: UInt16 = 51
        static let escape: UInt16 = 53
    }

    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
        guard let event = event, event.type == .keyDown,
              let client = sender as? IMKTextInput else { return false }

        let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if !mods.intersection([.command, .control, .option]).isEmpty {
            commit(client)
            return false
        }

        switch event.keyCode {
        case Key.backspace:
            if engine.isEmpty { return false }
            engine.backspace()
            showMarked(client)
            return true
        case Key.escape:
            // Esc while composing: drop the Vietnamese and keep what was typed.
            if engine.isEmpty { return false }
            insert(engine.rawText, client)
            engine.reset()
            return true
        default:
            break
        }

        guard let chars = event.characters, chars.count == 1,
              let ch = chars.first, ch.isASCII, ch.isLetter else {
            // Space, digits, punctuation, Return, arrows...: finish the word
            // and let the app handle the key itself.
            commit(client)
            return false
        }

        engine.process(ch)
        showMarked(client)
        return true
    }

    override func commitComposition(_ sender: Any!) {
        if let client = sender as? IMKTextInput { commit(client) }
    }

    override func deactivateServer(_ sender: Any!) {
        if let client = sender as? IMKTextInput { commit(client) }
        super.deactivateServer(sender)
    }

    // MARK: -

    private func commit(_ client: IMKTextInput) {
        guard !engine.isEmpty else { return }
        insert(engine.text, client)
        engine.reset()
    }

    private func insert(_ s: String, _ client: IMKTextInput) {
        client.insertText(s, replacementRange: NSRange(location: NSNotFound, length: 0))
    }

    private func showMarked(_ client: IMKTextInput) {
        let s = engine.text
        let attr = NSAttributedString(string: s, attributes: [
            .underlineStyle: NSUnderlineStyle.single.rawValue,
        ])
        client.setMarkedText(attr,
                             selectionRange: NSRange(location: (s as NSString).length, length: 0),
                             replacementRange: NSRange(location: NSNotFound, length: 0))
    }
}
