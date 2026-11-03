# VNK Telex

A Vietnamese Telex input method for macOS, built on InputMethodKit.

## Build and install

```sh
make test      # engine tests
make install   # builds, copies to ~/Library/Input Methods, registers it
```

If it doesn't show up in the menu bar right away, add it under
System Settings → Keyboard → Input Sources → Edit → + → Vietnamese → **VNK Telex**.
Logging out and back in also works if macOS hasn't picked it up yet.

`make uninstall` removes it.

## Typing

| Keys | Result | | Keys | Result |
|------|--------|-|------|--------|
| `aa` `ee` `oo` | â ê ô | | `s` | sắc  |
| `aw` `ow` `uw` | ă ơ ư | | `f` | huyền |
| `uow`          | ươ    | | `r` | hỏi  |
| `w`            | ư     | | `x` | ngã  |
| `dd`           | đ     | | `j` | nặng |
|                |       | | `z` | remove tone |

- Accent and tone keys can come anywhere after the vowel: `tiengse` and `tieengs` both give *tiếng*.
- Press the same key twice to undo: `ass` → *as*, `ww` → *w*, `ddd` → *dd*.
- Words that can't be Vietnamese go back to what you typed (`hello`, `google`).
- **Esc** while a word is underlined keeps the raw keystrokes.
- **Backspace** deletes the last letter and keeps the tone.

The tone goes on the main vowel (*hoà*, *khoẻ*, *thuý*). If you prefer *hòa*, *khỏe*, *thúy*, set
`newToneStyle = false` in [Sources/TelexEngine.swift](Sources/TelexEngine.swift).

## Layout

- `Sources/TelexEngine.swift`: the Telex logic, with no AppKit dependency
- `Sources/InputController.swift`: the IMK controller (key handling, marked text)
- `Sources/main.swift`: starts the `IMKServer`
- `Resources/Info.plist`: input method registration (`TISIntendedLanguage = vi`)
- `tools/`: icon generator and the registration helper used by `make install`
