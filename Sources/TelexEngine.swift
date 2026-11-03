// Telex composition engine. No AppKit dependency, so it can be unit-tested
// from the command line.
//
// The engine holds one word at a time. Feed it keystrokes with process(_:),
// read the composed text from `text`, and call reset() after committing.

enum Mark { case none, circumflex, breve, horn, stroke }

enum Tone: Int { case none = 0, grave, acute, hook, tilde, dot }

struct Letter {
    var base: Character   // lowercase ASCII
    var mark: Mark
    var upper: Bool
    var fromW = false     // "ư" produced by a bare w key
}

struct TelexEngine {
    /// true:  hoà, khoẻ, thuý   (tone on the main vowel, current convention)
    /// false: hòa, khỏe, thúy   (traditional placement)
    var newToneStyle = true

    /// When a word stops looking like Vietnamese, show the raw keystrokes
    /// instead (so "hello" stays "hello").
    var restoreInvalidWords = true

    private(set) var letters: [Letter] = []
    private var tone: Tone = .none
    private var raw = ""
    private var literal: String? = nil

    var isEmpty: Bool { text.isEmpty }
    var rawText: String { raw }
    var text: String { literal ?? render() }

    mutating func reset() {
        letters = []
        tone = .none
        raw = ""
        literal = nil
    }

    // MARK: - Input

    mutating func process(_ ch: Character) {
        raw.append(ch)
        if literal != nil {
            literal!.append(ch)
            return
        }
        guard let k = ch.lowercased().first, k.isASCII, k.isLetter else {
            literal = render()
            literal!.append(ch)
            return
        }
        let upper = ch.isUppercase
        let (ni, nj) = TelexEngine.parse(letters.map(\.base))
        let hasVowel = nj > ni

        switch k {
        case "s", "f", "r", "x", "j":
            if hasVowel {
                let t = TelexEngine.toneKeys[k]!
                if tone == t {
                    tone = .none
                    toLiteral(appending: ch)
                } else {
                    tone = t
                }
                return
            }
        case "z":
            if hasVowel && tone != .none {
                tone = .none
                return
            }
        case "d":
            if let first = letters.first, first.base == "d" {
                if first.mark == .stroke {
                    letters[0].mark = .none
                    toLiteral(appending: ch)
                } else {
                    letters[0].mark = .stroke
                }
                return
            }
        case "a", "e", "o":
            if let idx = (ni..<nj).last(where: { letters[$0].base == k }) {
                if letters[idx].mark == .circumflex {
                    letters[idx].mark = .none
                    toLiteral(appending: ch)
                } else {
                    letters[idx].mark = .circumflex
                    if k == "o", idx > ni, letters[idx - 1].base == "u" {
                        letters[idx - 1].mark = .none   // ươ -> uô
                    }
                }
                return
            }
        case "w":
            if applyW(ni, nj, ch) { return }
            if !hasVowel || nj == letters.count {
                letters.append(Letter(base: "u", mark: .horn, upper: upper, fromW: true))
                validate()
                return
            }
        default:
            break
        }

        letters.append(Letter(base: k, mark: .none, upper: upper))
        validate()
    }

    /// Delete the last visible character.
    mutating func backspace() {
        var s = text
        guard !s.isEmpty else { return }
        s.removeLast()
        let wasLiteral = literal != nil
        reset()
        guard !s.isEmpty else { return }
        raw = s
        if wasLiteral {
            literal = s
            return
        }
        for ch in s {
            let lower = Character(ch.lowercased())
            if let d = TelexEngine.decompose[lower] {
                letters.append(Letter(base: d.base, mark: d.mark, upper: ch.isUppercase))
                if d.tone != .none { tone = d.tone }
            } else if lower.isASCII && lower.isLetter {
                letters.append(Letter(base: lower, mark: .none, upper: ch.isUppercase))
            } else {
                letters = []
                tone = .none
                literal = s
                return
            }
        }
    }

    // MARK: - Internals

    private mutating func applyW(_ ni: Int, _ nj: Int, _ ch: Character) -> Bool {
        // "uo" + w -> ươ (or uơ at the end of a word, as in "thuở")
        if let i = (ni..<max(ni, nj - 1)).first(where: { letters[$0].base == "u" && letters[$0 + 1].base == "o" }) {
            if letters[i + 1].mark == .horn {
                letters[i].mark = .none
                letters[i + 1].mark = .none
                toLiteral(appending: ch)
            } else {
                letters[i + 1].mark = .horn
            }
            return true
        }
        guard let idx = (ni..<nj).last(where: { "aou".contains(letters[$0].base) }) else {
            return false
        }
        let target: Mark = letters[idx].base == "a" ? .breve : .horn
        if letters[idx].fromW {
            letters.remove(at: idx)
            toLiteral(appending: ch)
        } else if letters[idx].mark == target {
            letters[idx].mark = .none
            toLiteral(appending: ch)
        } else {
            letters[idx].mark = target
        }
        return true
    }

    private mutating func toLiteral(appending ch: Character) {
        var s = render()
        s.append(ch)
        literal = s
    }

    private mutating func validate() {
        guard restoreInvalidWords else { return }
        if !TelexEngine.isValidPrefix(letters.map(\.base)) {
            literal = raw
        }
    }

    /// Marks as displayed. An "ơ" preceded by "u" and followed by more
    /// letters turns the "u" into "ư" too: người, đường, rượu.
    private func effectiveMarks() -> [Mark] {
        var marks = letters.map(\.mark)
        let (ni, nj) = TelexEngine.parse(letters.map(\.base))
        if nj - ni >= 2 {
            for i in ni..<(nj - 1)
            where letters[i].base == "u" && letters[i + 1].base == "o"
                && marks[i + 1] == .horn && i + 2 < letters.count {
                marks[i] = .horn
            }
        }
        return marks
    }

    private func tonePosition(_ marks: [Mark]) -> Int? {
        let bases = letters.map(\.base)
        let (ni, nj) = TelexEngine.parse(bases)
        guard nj > ni else { return nil }
        if let m = (ni..<nj).last(where: { [.circumflex, .breve, .horn].contains(marks[$0]) }) {
            return m
        }
        let count = nj - ni
        if count == 1 { return ni }
        if nj < bases.count { return nj - 1 }           // has a final consonant
        if count >= 3 { return ni + 1 }
        let nucleus = String(bases[ni..<nj])
        if newToneStyle && ["oa", "oe", "uy"].contains(nucleus) { return nj - 1 }
        return ni
    }

    private func render() -> String {
        let marks = effectiveMarks()
        let tp = tone == .none ? nil : tonePosition(marks)
        var out = ""
        for (i, l) in letters.enumerated() {
            let c = TelexEngine.compose(l.base, marks[i], i == tp ? tone : .none)
            out += l.upper ? c.uppercased() : String(c)
        }
        return out
    }

    // MARK: - Tables

    private static let toneKeys: [Character: Tone] = [
        "f": .grave, "s": .acute, "r": .hook, "x": .tilde, "j": .dot,
    ]

    // Columns: none, grave, acute, hook, tilde, dot
    private static let vowelTable: [(Character, Mark, String)] = [
        ("a", .none,       "aàáảãạ"),
        ("a", .breve,      "ăằắẳẵặ"),
        ("a", .circumflex, "âầấẩẫậ"),
        ("e", .none,       "eèéẻẽẹ"),
        ("e", .circumflex, "êềếểễệ"),
        ("i", .none,       "iìíỉĩị"),
        ("o", .none,       "oòóỏõọ"),
        ("o", .circumflex, "ôồốổỗộ"),
        ("o", .horn,       "ơờớởỡợ"),
        ("u", .none,       "uùúủũụ"),
        ("u", .horn,       "ưừứửữự"),
        ("y", .none,       "yỳýỷỹỵ"),
    ]

    private static let composeTable: [String: [Character]] = {
        var t: [String: [Character]] = [:]
        for (b, m, s) in vowelTable { t["\(b)\(m)"] = Array(s) }
        return t
    }()

    private static let decompose: [Character: (base: Character, mark: Mark, tone: Tone)] = {
        var d: [Character: (Character, Mark, Tone)] = ["đ": ("d", .stroke, .none)]
        for (b, m, s) in vowelTable {
            for (i, c) in s.enumerated() { d[c] = (b, m, Tone(rawValue: i)!) }
        }
        return d
    }()

    private static func compose(_ base: Character, _ mark: Mark, _ tone: Tone) -> Character {
        if base == "d" { return mark == .stroke ? "đ" : "d" }
        if let row = composeTable["\(base)\(mark)"] { return row[tone.rawValue] }
        if let row = composeTable["\(base)none"] { return row[tone.rawValue] }
        return base
    }

    // MARK: - Syllable structure

    private static func isVowel(_ c: Character) -> Bool { "aeiouy".contains(c) }

    /// Split into initial consonant [0, ni), vowel nucleus [ni, nj), final [nj, end).
    static func parse(_ b: [Character]) -> (Int, Int) {
        var i = 0
        while i < b.count && !isVowel(b[i]) { i += 1 }
        if i == 1 && b[0] == "q" && i < b.count && b[i] == "u" {
            i = 2
        } else if i == 1 && b[0] == "g" && i + 1 < b.count && b[i] == "i" && isVowel(b[i + 1]) {
            i = 2
        }
        var j = i
        while j < b.count && isVowel(b[j]) { j += 1 }
        return (i, j)
    }

    private static let initials: Set<String> = [
        "", "b", "c", "ch", "d", "g", "gh", "gi", "h", "k", "kh", "l", "m", "n",
        "ng", "ngh", "nh", "p", "ph", "qu", "r", "s", "t", "th", "tr", "v", "x",
    ]
    private static let nuclei: Set<String> = [
        "a", "ai", "ao", "au", "ay", "e", "eo", "eu", "i", "ia", "ie", "ieu", "iu",
        "o", "oa", "oai", "oay", "oe", "oeo", "oi", "oo", "u", "ua", "uay", "ue",
        "ui", "uo", "uoi", "uou", "uu", "uy", "uya", "uye", "uyu", "y", "ye", "yeu",
    ]
    private static let finals: Set<String> = ["c", "ch", "m", "n", "ng", "nh", "p", "t"]

    private static func isPrefix(_ s: String, of set: Set<String>) -> Bool {
        set.contains { $0.hasPrefix(s) }
    }

    static func isValidPrefix(_ b: [Character]) -> Bool {
        let (ni, nj) = parse(b)
        let initial = String(b[0..<ni])
        let nucleus = String(b[ni..<nj])
        let final = String(b[nj...])
        if final.contains(where: isVowel) { return false }
        if nucleus.isEmpty { return isPrefix(initial, of: initials) }
        guard initials.contains(initial) else { return false }
        if final.isEmpty { return isPrefix(nucleus, of: nuclei) }
        return nuclei.contains(nucleus) && isPrefix(final, of: finals)
    }
}
