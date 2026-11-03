var failures = 0

func type(_ keys: String, newStyle: Bool = true) -> TelexEngine {
    var e = TelexEngine()
    e.newToneStyle = newStyle
    for ch in keys { e.process(ch) }
    return e
}

func check(_ keys: String, _ expected: String, newStyle: Bool = true) {
    let got = type(keys, newStyle: newStyle).text
    if got != expected {
        failures += 1
        print("FAIL  \(keys) -> \(got)  (expected \(expected))")
    }
}

// Basic marks and tones
check("tieengs", "tiếng")
check("vieetj", "việt")
check("Vieetj", "Việt")
check("VIEETJ", "VIỆT")
check("nguoiwf", "người")
check("dduowngf", "đường")
check("Dduowngf", "Đường")
check("ruouwj", "rượu")
check("huowng", "hương")
check("thuowr", "thuở")
check("tooi", "tôi")
check("cuar", "của")
check("chuyeenr", "chuyển")
check("khuyeen", "khuyên")
check("hoawcj", "hoặc")
check("baan", "bân")
check("muaf", "mùa")
check("mias", "mía")
check("w", "ư")
check("tw", "tư")
check("nhw", "như")
check("uwa", "ưa")
check("cuwuf", "cừu")
check("guiwr", "gửi")
check("khuya", "khuya")
check("khuyur", "khuỷu")
check("ngoaij", "ngoại")

// Free tone placement
check("tiengse", "tiếng")
check("vietje", "việt")
check("duongwf", "dường")
check("ddw", "đư")

// gi / qu
check("quas", "quá")
check("quys", "quý")
check("quoocs", "quốc")
check("gif", "gì")
check("giaf", "già")
check("giuwx", "giữ")
check("gieengs", "giếng")
check("ginf", "gìn")

// Tone style
check("hoaf", "hoà")
check("hoaf", "hòa", newStyle: false)
check("khoer", "khoẻ")
check("khoer", "khỏe", newStyle: false)
check("thuys", "thuý")
check("hoafn", "hoàn")
check("hoafn", "hoàn", newStyle: false)

// Undo by repeating the key
check("ass", "as")
check("aaa", "aa")
check("ddd", "dd")
check("ww", "w")
check("aww", "aw")
check("uoww", "uow")
check("asz", "a")
check("asf", "à")

// Non-Vietnamese words fall back to the raw keys
check("hello", "hello")
check("word", "word")
check("class", "class")
check("google", "google")
check("zoo", "zoo")

// Backspace
do {
    var e = type("tieengs")
    e.backspace()
    if e.text != "tiến" { failures += 1; print("FAIL  backspace tiếng -> \(e.text)") }
    e.process("g")
    if e.text != "tiếng" { failures += 1; print("FAIL  backspace+g -> \(e.text)") }
    for _ in 0..<5 { e.backspace() }
    if !e.isEmpty { failures += 1; print("FAIL  backspace to empty -> \(e.text)") }

    var r = type("nguoiwf")
    r.backspace()
    if r.text != "ngườ" { failures += 1; print("FAIL  backspace người -> \(r.text)") }
}

// Raw text for Esc
if type("tieengs").rawText != "tieengs" { failures += 1; print("FAIL  rawText") }

print(failures == 0 ? "all tests passed" : "\(failures) failure(s)")
if failures > 0 { exit(1) }

import Foundation
