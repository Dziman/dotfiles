# Swift in Emacs

Emacs edits Swift; Xcode builds, runs and debugs. Config:
`.emacs-dziman/configs/dz-config-swift.el` (Swift) and `dz-config-eglot.el`
(language-server settings shared by all languages). Design:
`specs/2026-10-11-emacs-swift-design.md`.

## Tools

| Tool | From | Used for | If missing |
|---|---|---|---|
| `sourcekit-lsp`, `swift-format`, `xed` | Xcode | language server, Apple formatter, open in Xcode | no server; format and Open in Xcode show a one-line note |
| `swiftformat` | `brew install swiftformat` | projects with `.swiftformat` | one-line note on save and key press |
| `swiftlint` | `brew install swiftlint` | projects with `.swiftlint.yml` | lint skipped |

## Swift packages for iPhone, Apple TV, Apple Watch, Vision Pro

Swift packages are checked against the Mac SDK. For a package that imports
platform-only frameworks (UIKit, …), add to its `.dir-locals.el`:

```elisp
((swift-mode . ((dziman/swift-platform . ios))))
```

Values: `ios`, `tvos`, `watchos`, `visionos`. After editing it, run
`M-x dziman/swift-reload-platform`. Folders with `buildServer.json` ignore it.

Each folder holding `Package.swift` or `buildServer.json` gets its own language
server, so references stay inside that package or app.

## Xcode app projects

The language server reads Xcode's build settings from `buildServer.json` in the
project folder. Create it once per project (again after switching schemes), then
build once in Xcode so the index exists:

```bash
xcode-build-server config -scheme <name> -project <file>.xcodeproj   # or -workspace <file>.xcworkspace
```

## Formatting and lint

- `.swiftformat` nearest → SwiftFormat; `.swift-format` nearest → Apple
  swift-format; same folder → SwiftFormat. With either file, saving formats.
- No config → `M-p f` formats with Apple swift-format defaults; saving does not.
- SwiftLint runs only under a `.swiftlint.yml`, from the topmost one, so nested
  configs apply.

## Keys

| Key | Command |
|---|---|
| `M-p r` | rename symbol |
| `M-p a` | code actions / quick fixes |
| `M-p s` | go to symbol (live list) |
| `M-p f` | format file |
| `M-p x` | open in Xcode at this line |
| `M-p d` | Apple docs for the selection, else the symbol at point, else asks; blank is refused |
| `M-.` / `M-,` / `M-?` | definition / back / references |

`C-. h` opens the Swift menu with all of the above plus `p` (reload platform) and
`e` (error list). `M-x dziman/swift-reload-platform` is also on the menu.
It restarts the language server of the current package with a changed platform.

`M-p r`, `a`, `s` exist only in buffers with a running language server.
Indexing progress shows as a percentage in the mode line.
