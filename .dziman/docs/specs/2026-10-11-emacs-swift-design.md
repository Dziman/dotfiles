# Emacs Swift editing — design

Date: 2026-10-11
Status: approved design, not implemented

## Goal

Edit Swift code in Emacs for Apple-platform work (iPhone first) with completion,
navigation and correct errors. Xcode keeps building, running and debugging apps.

## Scope

In:

- Both kinds of project: Xcode app projects (`.xcodeproj` / `.xcworkspace`) and
  Swift packages (`Package.swift`).
- Every machine (shared config). A machine without the Swift tools gets syntax
  colors only, with no errors.
- A per-project platform switch for Swift packages that use frameworks only one
  Apple platform has (iPhone, Apple TV, Apple Watch, Vision Pro). Mac is the default.
- Formatting with SwiftFormat or Apple swift-format, chosen per project.
- SwiftLint warnings in projects that use SwiftLint.
- Helpers: open in Xcode, Apple docs for symbol, go to symbol.
- Indexing progress in the mode line.

Out:

- Building, running and debugging from Emacs. Debugging in Emacs is wanted
  eventually and gets its own spec.
- A command that writes an Xcode app project's `buildServer.json`; projects get it
  by other means.
- Making Emacs the default macOS app for `.swift` files.

## Success criteria

- Opening a `.swift` file in a Swift package for a non-Mac platform, and in an
  Xcode app project that has `buildServer.json`, gives completion, jump to
  definition and correct errors, with no false "No such module" errors.
- Emacs startup stays at about 0.24 s (`emacs-init-time`). The first Swift file
  or project may take longer to open.

## Current state (2026-10-11)

- `main` has no Swift support in Emacs and no LSP client config.
- Branch `feature/emacs-ts-prog` (pre-unification) had one: `swift-mode`, lsp-mode
  with a hand-built sourcekit-lsp client passing iPhone SDK flags, vendored
  konrad1977 build and simulator scripts, `dap-lldb`. Not carried over: build and
  run are out of scope, and its SDK flags no longer work (see Language server).
- `.emacs-dziman/custom.el` still lists two `(eval dziman/register-swift-lsp-client …)`
  entries in `safe-local-variable-values`, left over from that branch.
- Completion is corfu + cape, errors are flycheck (`flycheck-inline`,
  `consult-flycheck` on `M-g e`), the mode line is doom-modeline. Emacs 32 ships eglot.
- On this machine: Xcode with Swift 6.4 (`sourcekit-lsp`, `swift-format`, `xed`),
  Homebrew `swiftformat` 0.63.1, `swiftlint` 0.65.1, `xcode-build-server`.

## Design

### Language server

- `swift-mode` (MELPA) for `.swift` files, loaded on the first Swift file.
- eglot (built in) starts `xcrun sourcekit-lsp` for the file's project, one server
  per project.
- eglot starts only when `xcrun --find sourcekit-lsp` succeeds, checked once per
  session. Otherwise Swift buffers get syntax colors only and no message.
- Xcode app projects: with `buildServer.json` in the project, the server takes
  Xcode's build settings from it. Without it, basic editing only.
- Platform switch for Swift packages, in the package's `.dir-locals.el`:

  ```elisp
  ((swift-mode . ((dziman/swift-platform . ios))))
  ```

  Values `ios`, `tvos`, `watchos`, `visionos`; unset means Mac. The variable is
  marked safe for those values. Changing it takes effect after `M-x eglot-reconnect`.
- For a platform, the server command gets these arguments, with `<sdk>` from
  `xcrun --sdk <name> --show-sdk-path` and `<version>` from
  `xcrun --sdk <name> --show-sdk-version`:

  ```
  -Xswiftc -sdk -Xswiftc <sdk>
  -Xswiftc -target -Xswiftc arm64-apple-<os><version>
  -Xcc -isysroot -Xcc <sdk>
  ```

  | `dziman/swift-platform` | SDK name | `<os>` |
  |---|---|---|
  | `ios` | `iphoneos` | `ios` |
  | `tvos` | `appletvos` | `tvos` |
  | `watchos` | `watchos` | `watchos` |
  | `visionos` | `xros` | `xros` |

  Probed with sourcekit-lsp (Swift 6.4) on a package importing UIKit:

  | Server settings | Result |
  |---|---|
  | none | false "No such module 'UIKit'" |
  | `-Xswiftc` SDK and target only (the old branch) | false "Cannot load underlying module for 'UIKit'" |
  | `SDKROOT` env + `swiftPM.triple` init option | no diagnostics at all, a real type error missed |
  | the three flag pairs above | correct, real type error reported, on iPhone, Apple TV, Vision Pro |

  Apple Watch was not probed (no UIKit there); the manual check covers it.

- Status: sourcekit-lsp sends `$/progress` while indexing or preparing a file
  (probed: `Indexing 0 / 1`, `Preparing current file`). eglot shows it as a
  percentage in `mode-line-misc-info`, task on hover, and doom-modeline shows that
  segment. No extra code. If doom-modeline's own eglot icon and eglot's block both
  show the server, keep only the progress part of eglot's block.

### Errors and SwiftLint

- `flycheck-eglot` (MELPA) feeds the server's diagnostics into flycheck instead of
  flymake, so margin marks, `flycheck-inline` and `M-g e` work as for other languages.
- SwiftLint: a flycheck checker defined in `dz-config-swift.el`, chained after the
  eglot checker. It runs `swiftlint lint --use-stdin --quiet --reporter json` from
  the file's directory, so SwiftLint resolves the project's config (nested ones
  included) as it does in a terminal.
- Enabled only when `.swiftlint.yml` exists in the file's directory or a parent,
  and `swiftlint` is installed. Otherwise skipped silently.
- Each message ends with the rule id, e.g. `[force_unwrapping]`.
- Runs on flycheck's usual triggers.
- Not using MELPA `flycheck-swiftlint` (last updated 2018).

### Formatting

Formatter per file; the nearest config file in the file's directory or a parent
decides:

| Found | Formatter | Format on save |
|---|---|---|
| `.swiftformat` | SwiftFormat | yes |
| `.swift-format`, no `.swiftformat` | Apple swift-format | yes |
| neither | Apple swift-format, default style | no, key press only |

- `reformatter` (MELPA) pipes the buffer through the formatter and replaces it,
  keeping point and scroll; one undo step reverts it.
- Commands (both checked on this machine):
  - SwiftFormat: `swiftformat stdin --stdin-path <file> --quiet`
  - swift-format: `xcrun swift-format format --assume-filename <file> -`
- Whole file only.
- Formatter fails (code that does not parse): buffer unchanged, save goes ahead,
  formatter output shown in an error buffer.
- Formatter not installed: save skips formatting with a one-line echo-area note;
  the key press shows the same note.

### Helpers

- **Open in Xcode:** saves the buffer if modified, runs `xed --line <n> <file>`.
  Xcode reuses the window that has the project open and comes to the front.
- **Apple docs for symbol:** the selection, else the symbol at point, else a prompt;
  opens `https://developer.apple.com/search/?q=<word>` with `browse-url`.
- **Go to symbol:** `consult-eglot-symbols` (MELPA `consult-eglot`): live list of
  workspace symbols as you type, with kind and file, previewing the location.
  Covers indexed code only: Swift packages index in the background, Xcode app
  projects after a build in Xcode.

### Keys

In the existing `M-p` prog-mode map (`dziman/bind-map/prog`):

| Key | Command | Where |
|---|---|---|
| `M-p r` | `eglot-rename` | eglot buffers |
| `M-p a` | `eglot-code-actions` | eglot buffers |
| `M-p s` | `consult-eglot-symbols` | eglot buffers |
| `M-p f` | format file | Swift buffers |
| `M-p x` | open in Xcode | Swift buffers |
| `M-p d` | Apple docs for symbol | Swift buffers |

`M-.`, `M-,` and `M-?` stay the standard xref keys; eglot backs them.

## Files

| File | Change |
|---|---|
| `.emacs-dziman/configs/dz-config-eglot.el` | new: general eglot settings, eglot keys, `flycheck-eglot`, `consult-eglot` |
| `.emacs-dziman/configs/dz-config-swift.el` | new: `swift-mode`, server command and platform switch, SwiftLint checker, formatting, helpers, Swift keys |
| `.emacs` | require both after `dz-config-prog-languages`, eglot first |
| `.emacs-dziman/custom.el` | drop the two `register-swift-lsp-client` entries |
| `.dziman/docs/emacs-swift.md` | new: tools table, platform switch, manual `xcode-build-server config -scheme <name> -project <file>` line, keys |
| `.emacs-dziman/tests/dz-config-swift-test.el` | new: ERT tests |

Neither config goes into `dziman/preload-features`. No profile files.

New MELPA packages, installed by `use-package` on first start: `swift-mode`,
`flycheck-eglot`, `consult-eglot`, `reformatter`.

## Tools

| Tool | From | Used for | If missing |
|---|---|---|---|
| `sourcekit-lsp`, `swift-format`, `xed` | Xcode | server, Apple formatter, open in Xcode | no server; format and open in Xcode show a one-line note |
| `swiftformat` | Homebrew | SwiftFormat projects | one-line note on save and key press |
| `swiftlint` | Homebrew | lint warnings | checker skipped |

`.dziman/profiles/*/brew.packages` are snapshots nothing reads; they are not changed.

## Testing

- ERT, run with `emacs --batch`, in `.emacs-dziman/tests/dz-config-swift-test.el`
  (the repo's first Emacs tests):
  - server arguments for each platform value and for Mac
  - formatter choice and format-on-save for each config-file case
  - SwiftLint enabled or not by `.swiftlint.yml`
  - missing tools degrade without errors
- `emacs --batch -l ~/.emacs` loads with no errors; both new files byte-compile with
  no warnings; `emacs-init-time` about 0.24 s.
- Manual, once on this machine:
  - an iPhone, a Vision Pro and an Apple Watch package show correct errors
  - an Xcode app project with `buildServer.json` completes
  - format on save in a SwiftFormat project and in a swift-format project
  - SwiftLint warnings appear
  - each `M-p` key works
  - the mode line shows indexing progress; check for a doubled eglot display
