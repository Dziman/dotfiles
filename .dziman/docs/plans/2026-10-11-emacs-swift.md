# Emacs Swift Editing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Swift editing in Emacs — completion, navigation, correct errors for Swift packages on any Apple platform and for Xcode app projects, per-project formatting, SwiftLint, and three helpers — while Xcode keeps building and running.

**Architecture:** Two new shared config files. `dz-config-eglot.el` holds language-agnostic eglot settings and keys; `dz-config-swift.el` holds everything Swift: one sourcekit-lsp per package or app folder, the per-package platform SDK switch, the eglot start guard, a SwiftLint flycheck checker, formatter selection through `reformatter`, and the helpers with their `M-p` keys. Logic lives in small `dziman/swift-…` functions that ERT tests call directly with stubbed tools.

**Tech Stack:** Emacs 32 Lisp, eglot (built in), flycheck, MELPA `swift-mode`, `flycheck-eglot`, `consult-eglot`, `reformatter`, `bind-map`; Xcode `sourcekit-lsp` / `swift-format` / `xed`; Homebrew `swiftformat`, `swiftlint`; ERT.

**Spec:** `.dziman/docs/specs/2026-10-11-emacs-swift-design.md`

## Global Constraints

- Work in this checkout (`~/src/dziman/settings`), branch `feature/emacs-swift`. Every path is relative to the repo root. The live `~/.emacs` (bare repo `~/.dziman-dotfiles`, work tree `$HOME`) is not touched; manual checks run Emacs against the checkout.
- New MELPA packages: exactly `swift-mode`, `flycheck-eglot`, `consult-eglot`, `reformatter`. No other new dependency.
- Elisp files start with `;;; -*- lexical-binding: t -*-`, use the banner-comment style and closing-paren-on-own-line layout of `.emacs-dziman/configs/dz-config-prog-mode.el`, and end with a newline.
- Public names use the `dziman/swift-` / `dziman/` prefix; internal helpers `dziman/swift--`. Tests are named `dziman-swift-<group>/<business-rule>`.
- Platform values and SDK mapping, verbatim from the spec: `ios`→`iphoneos`/`ios`, `tvos`→`appletvos`/`tvos`, `watchos`→`watchos`/`watchos`, `visionos`→`xros`/`xros`; unset means Mac.
- Server arguments for a platform, verbatim: `-Xswiftc -sdk -Xswiftc <sdk>`, `-Xswiftc -target -Xswiftc arm64-apple-<os><version>`, `-Xcc -isysroot -Xcc <sdk>`.
- A missing tool never raises an error: no server, a skipped checker, or a one-line echo-area note.
- Emacs startup stays at about 0.24 s; loading the two new files costs a few milliseconds at most.
- Commit subjects use the `[emacs]` / `[docs]` tags. Every commit ends with `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`. `git add` explicit paths only. No push.

**Test command** (from the repo root; `<group>` is `server`, `start`, `lint`, `format` or `helpers`; omit the `--eval` to run all):

```bash
emacs --batch -f package-initialize -L .emacs-dziman/configs -L .emacs-dziman/tests \
  -l dz-config-swift-test --eval '(ert-run-tests-batch-and-exit "^dziman-swift-<group>/")'
```

## Review Focus

- A platform whose SDK is not installed (e.g. `visionos` on a machine without the visionOS SDK): the server still starts against the Mac SDK and the echo area says why — pinned in Task 1.
- A mistyped platform value (`iphone`): Emacs treats it as unsafe; if accepted anyway, the server starts against the Mac SDK with a message — pinned in Task 1.
- A file under a nested `.swiftlint.yml` (root config plus `Sources/A/.swiftlint.yml`): SwiftLint runs from the topmost config folder so both configs apply — pinned in Task 3.
- Both formatter configs present: the nearer one decides; in the same folder SwiftFormat wins — pinned in Task 4.
- A Swift buffer not visiting a file (scratch buffer): formatting still works without a path, Open in Xcode refuses with a clear message — pinned in Tasks 4 and 5.
- A package inside an Xcode app folder (`App/buildServer.json` + `App/Packages/Kit/Package.swift`): the package gets its own server, the app keeps the platform from Xcode — pinned in Task 1.

---

### Task 1: Language server command, platform switch and package folders

**Files:**
- Create: `.emacs-dziman/configs/dz-config-swift.el`
- Test: `.emacs-dziman/tests/dz-config-swift-test.el`

**Interfaces:**
- Produces:
  - `dziman/swift-platforms` — alist `(PLATFORM . (SDK-NAME . TARGET-OS))`
  - `dziman/swift-platform` — buffer-local symbol or nil, safe for keys of `dziman/swift-platforms`
  - `(dziman/swift--sdk SDK-NAME)` → `(PATH . VERSION)` or nil
  - `(dziman/swift-platform-server-args TARGET-OS SDK-PATH SDK-VERSION)` → list of strings
  - `(dziman/swift-server-command &optional ROOT)` → list of strings, starts with `"xcrun" "sourcekit-lsp"`; no platform arguments when ROOT holds `buildServer.json`
  - `(dziman/swift-eglot-contact INTERACTIVE PROJECT)` → `(dziman/swift-server-command (project-root PROJECT))`
  - `(dziman/swift-package-root DIRECTORY)` → nearest folder with `Package.swift` or `buildServer.json`, or nil
  - `(dziman/swift-project-find DIRECTORY)` → `(dziman-swift . ROOT)` for eglot in Swift buffers, else nil; `project-root` method for it
  - test macro `dziman-swift-test-with-project` (binds `root`), test helper `dziman-swift-test-same-dir-p`

- [ ] **Step 1: Install the new MELPA packages**

The test runs need them installed; Emacs would install them on first start anyway.

```bash
emacs --batch -f package-initialize --eval "(progn (add-to-list 'package-archives '(\"melpa\" . \"https://melpa.org/packages/\") t) (package-refresh-contents) (dolist (p '(swift-mode flycheck-eglot consult-eglot reformatter)) (package-install p)))"
```

Expected: ends with `Package ‘reformatter’ installed` (or already installed), no errors.

- [ ] **Step 2: Write the stub**

Create `.emacs-dziman/configs/dz-config-swift.el`:

```elisp
;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Swift editing: sourcekit-lsp through eglot, SwiftLint, formatting, Xcode helpers.
;;;;;; Xcode builds and runs the apps.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package swift-mode :defer t)

;;;;;;;; Language server
(defconst dziman/swift-platforms
  '(
     (ios      . ("iphoneos"  . "ios"))
     (tvos     . ("appletvos" . "tvos"))
     (watchos  . ("watchos"   . "watchos"))
     (visionos . ("xros"      . "xros"))
     )
  "Platform switch value to (SDK-NAME . TARGET-OS). Mac is the absence of a value.")

(defvar-local dziman/swift-platform nil
  "Apple platform a Swift package is checked against: a key of `dziman/swift-platforms', nil for Mac.
Set it in the package's .dir-locals.el. After a change, open buffers need `normal-mode'
to re-read it, then `eglot-reconnect'. Ignored in folders with buildServer.json.")

(defun dziman/swift--sdk (_sdk-name)
  nil
  )

(defun dziman/swift-platform-server-args (_target-os _sdk-path _sdk-version)
  nil
  )

(defun dziman/swift-server-command (&optional _root)
  (list "xcrun" "sourcekit-lsp")
  )

(defun dziman/swift-eglot-contact (_interactive _project)
  nil
  )

(defun dziman/swift-package-root (_directory)
  nil
  )

(defun dziman/swift-project-find (_directory)
  nil
  )

(provide 'dz-config-swift)
```

- [ ] **Step 3: Write the failing tests**

Create `.emacs-dziman/tests/dz-config-swift-test.el`:

```elisp
;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; ERT tests for dz-config-swift. Run from the repo root:
;;;;;;   emacs --batch -f package-initialize -L .emacs-dziman/configs -L .emacs-dziman/tests \
;;;;;;     -l dz-config-swift-test -f ert-run-tests-batch-and-exit
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'ert)
(require 'cl-lib)
;; Loaded up front so `eglot-lsp-context' is special when tests let-bind it
(require 'project)
(require 'eglot)
(require 'dz-config-swift)

(defmacro dziman-swift-test-with-project (files &rest body)
  "Run BODY with `root' bound to a new temp directory holding empty FILES (paths relative to it)."
  (declare (indent 1))
  `(let ((root (file-name-as-directory (make-temp-file "dz-swift-test" t))))
     (unwind-protect
       (progn
         (dolist (file ,files)
           (let ((path (expand-file-name file root)))
             (make-directory (file-name-directory path) t)
             (write-region "" nil path)
             )
           )
         ,@body
         )
       (delete-directory root t)
       )
     )
  )

(defun dziman-swift-test-same-dir-p (dir expected)
  "Non-nil when DIR names the directory EXPECTED; nil when DIR is nil."
  (and dir (file-equal-p dir expected))
  )

;;;;;;;; Language server command
(ert-deftest dziman-swift-server/mac-is-the-default-platform ()
  (with-temp-buffer
    (should (equal (dziman/swift-server-command) '("xcrun" "sourcekit-lsp")))
    )
  )

(ert-deftest dziman-swift-server/platforms-name-xcode-sdks-and-target-os ()
  ;; The rule lives in the table: each switch value names Xcode's SDK and the target-triple OS
  (should (equal dziman/swift-platforms
            '((ios . ("iphoneos" . "ios"))
               (tvos . ("appletvos" . "tvos"))
               (watchos . ("watchos" . "watchos"))
               (visionos . ("xros" . "xros")))))
  )

(ert-deftest dziman-swift-server/iphone-package-checks-against-iphone-sdk ()
  (with-temp-buffer
    (setq dziman/swift-platform 'ios)
    (cl-letf (((symbol-function 'dziman/swift--sdk)
                (lambda (sdk-name) (and (equal sdk-name "iphoneos") '("/SDKs/iPhoneOS.sdk" . "27.0")))))
      (should (equal (dziman/swift-server-command)
                '("xcrun" "sourcekit-lsp"
                   "-Xswiftc" "-sdk" "-Xswiftc" "/SDKs/iPhoneOS.sdk"
                   "-Xswiftc" "-target" "-Xswiftc" "arm64-apple-ios27.0"
                   "-Xcc" "-isysroot" "-Xcc" "/SDKs/iPhoneOS.sdk")))
      )
    )
  )

(ert-deftest dziman-swift-server/vision-pro-package-uses-xros-target ()
  (with-temp-buffer
    (setq dziman/swift-platform 'visionos)
    (cl-letf (((symbol-function 'dziman/swift--sdk)
                (lambda (sdk-name) (and (equal sdk-name "xros") '("/SDKs/XROS.sdk" . "27.0")))))
      (should (member "arm64-apple-xros27.0" (dziman/swift-server-command)))
      )
    )
  )

(ert-deftest dziman-swift-server/missing-platform-sdk-falls-back-to-mac ()
  (with-temp-buffer
    (setq dziman/swift-platform 'visionos)
    (cl-letf (((symbol-function 'dziman/swift--sdk) #'ignore))
      (should (equal (dziman/swift-server-command) '("xcrun" "sourcekit-lsp")))
      )
    )
  )

(ert-deftest dziman-swift-server/unknown-platform-falls-back-to-mac ()
  (with-temp-buffer
    (setq dziman/swift-platform 'iphone)
    (should (equal (dziman/swift-server-command) '("xcrun" "sourcekit-lsp")))
    )
  )

(ert-deftest dziman-swift-server/platform-switch-is-safe-for-known-platforms ()
  (should (safe-local-variable-p 'dziman/swift-platform 'visionos))
  )

(ert-deftest dziman-swift-server/platform-switch-is-unsafe-for-other-values ()
  (should-not (safe-local-variable-p 'dziman/swift-platform 'iphone))
  )

(ert-deftest dziman-swift-server/installed-sdk-reports-path-and-version ()
  (skip-unless (executable-find "xcrun"))
  (let ((sdk (dziman/swift--sdk "macosx")))
    (should (file-directory-p (car sdk)))
    (should (string-match-p "\\`[0-9]+\\.[0-9]+" (cdr sdk)))
    )
  )

(ert-deftest dziman-swift-server/absent-sdk-reports-nothing ()
  (should-not (dziman/swift--sdk "no-such-sdk"))
  )

(ert-deftest dziman-swift-server/eglot-contact-is-the-server-command ()
  (with-temp-buffer
    (should (equal (dziman/swift-eglot-contact nil nil) '("xcrun" "sourcekit-lsp")))
    )
  )

(ert-deftest dziman-swift-server/xcode-app-folder-ignores-platform-switch ()
  (dziman-swift-test-with-project '("buildServer.json")
    (with-temp-buffer
      (setq dziman/swift-platform 'ios)
      (cl-letf (((symbol-function 'dziman/swift--sdk) (lambda (_sdk-name) '("/SDKs/iPhoneOS.sdk" . "27.0"))))
        (should (equal (dziman/swift-server-command root) '("xcrun" "sourcekit-lsp")))
        )
      )
    )
  )

(ert-deftest dziman-swift-server/eglot-contact-passes-the-project-folder ()
  (dziman-swift-test-with-project '("buildServer.json")
    (with-temp-buffer
      (setq dziman/swift-platform 'ios)
      (cl-letf (((symbol-function 'dziman/swift--sdk) (lambda (_sdk-name) '("/SDKs/iPhoneOS.sdk" . "27.0"))))
        (should (equal (dziman/swift-eglot-contact nil (cons 'dziman-swift root)) '("xcrun" "sourcekit-lsp")))
        )
      )
    )
  )

;;;;;;;; One server per package or app folder
(ert-deftest dziman-swift-server/package-file-gets-its-package-folder ()
  (dziman-swift-test-with-project '("Package.swift" "Sources/Kit/X.swift")
    (should (dziman-swift-test-same-dir-p (dziman/swift-package-root (expand-file-name "Sources/Kit/" root)) root))
    )
  )

(ert-deftest dziman-swift-server/app-file-gets-its-app-folder ()
  (dziman-swift-test-with-project '("App/buildServer.json" "App/Sources/X.swift")
    (should (dziman-swift-test-same-dir-p
              (dziman/swift-package-root (expand-file-name "App/Sources/" root))
              (expand-file-name "App/" root)))
    )
  )

(ert-deftest dziman-swift-server/package-inside-app-gets-its-own-folder ()
  (dziman-swift-test-with-project '("App/buildServer.json" "App/Packages/Kit/Package.swift" "App/Packages/Kit/Sources/X.swift")
    (should (dziman-swift-test-same-dir-p
              (dziman/swift-package-root (expand-file-name "App/Packages/Kit/Sources/" root))
              (expand-file-name "App/Packages/Kit/" root)))
    )
  )

(ert-deftest dziman-swift-server/eglot-project-is-the-package-folder ()
  (dziman-swift-test-with-project '("Package.swift" "Sources/X.swift")
    (with-temp-buffer
      (setq-local major-mode 'swift-mode)
      (let ((eglot-lsp-context t))
        (should (dziman-swift-test-same-dir-p (cdr (dziman/swift-project-find (expand-file-name "Sources/" root))) root))
        )
      )
    )
  )

(ert-deftest dziman-swift-server/other-project-commands-keep-their-root ()
  (dziman-swift-test-with-project '("Package.swift" "Sources/X.swift")
    (with-temp-buffer
      (setq-local major-mode 'swift-mode)
      (should-not (dziman/swift-project-find (expand-file-name "Sources/" root)))
      )
    )
  )

(ert-deftest dziman-swift-server/project-root-of-a-package-project-is-its-folder ()
  (should (equal (project-root '(dziman-swift . "/p/Kit/")) "/p/Kit/"))
  )

(ert-deftest dziman-swift-server/git-projects-still-found ()
  ;; Adding the Swift finder must keep project.el's own VC finder
  (should (memq #'project-try-vc project-find-functions))
  )

(provide 'dz-config-swift-test)
```

- [ ] **Step 4: Run the tests to verify they fail**

Run the test command with group `server`.
Expected: FAIL. `iphone-package-checks-against-iphone-sdk` fails its `equal` assertion (got `("xcrun" "sourcekit-lsp")`); `vision-pro-package-uses-xros-target`, `platform-switch-is-safe-for-known-platforms`, `installed-sdk-reports-path-and-version`, `eglot-contact-is-the-server-command`, `eglot-contact-passes-the-project-folder`, the three `…-gets-its-…-folder` tests, `eglot-project-is-the-package-folder` and `project-root-of-a-package-project-is-its-folder` fail their assertions (the last one may signal `cl-no-applicable-method`: add the `project-root` method stub from Step 5 first, returning nil, until it fails on `equal`). Quote one assertion failure message before Step 5.

- [ ] **Step 5: Implement**

In `dz-config-swift.el`, replace the six stubs with:

```elisp
(put 'dziman/swift-platform 'safe-local-variable
  (lambda (value) (and (assq value dziman/swift-platforms) t))
  )

(defun dziman/swift--sdk (sdk-name)
  "Return (PATH . VERSION) of the Xcode SDK SDK-NAME, or nil when that SDK is not installed."
  (ignore-errors
    (cons
      (car (process-lines "xcrun" "--sdk" sdk-name "--show-sdk-path"))
      (car (process-lines "xcrun" "--sdk" sdk-name "--show-sdk-version"))
      )
    )
  )

(defun dziman/swift-platform-server-args (target-os sdk-path sdk-version)
  "sourcekit-lsp arguments that check a Swift package against SDK-PATH for TARGET-OS SDK-VERSION."
  ;; Without -isysroot, SwiftPM (Swift 6.4) keeps the Mac SDK for Clang modules: "Cannot load underlying module"
  (list
    "-Xswiftc" "-sdk" "-Xswiftc" sdk-path
    "-Xswiftc" "-target" "-Xswiftc" (format "arm64-apple-%s%s" target-os sdk-version)
    "-Xcc" "-isysroot" "-Xcc" sdk-path
    )
  )

(defun dziman/swift-server-command (&optional root)
  "sourcekit-lsp command for the current buffer's `dziman/swift-platform'.
ROOT is the server's folder; one holding buildServer.json takes its platform from Xcode's build settings.
Unknown platforms and platforms without an installed SDK fall back to Mac, with a message."
  (let* (
          (mac (list "xcrun" "sourcekit-lsp"))
          (xcode-project (and root (file-exists-p (expand-file-name "buildServer.json" root))))
          (platform (and dziman/swift-platform (alist-get dziman/swift-platform dziman/swift-platforms)))
          (sdk (and platform (not xcode-project) (dziman/swift--sdk (car platform))))
          )
    (cond
      ((or (null dziman/swift-platform) xcode-project) mac)
      ((null platform)
        (message "Unknown dziman/swift-platform %S; checking against the Mac SDK" dziman/swift-platform)
        mac
        )
      ((null sdk)
        (message "SDK %s is not installed; checking against the Mac SDK" (car platform))
        mac
        )
      (t (append mac (dziman/swift-platform-server-args (cdr platform) (car sdk) (cdr sdk))))
      )
    )
  )

(defun dziman/swift-eglot-contact (_interactive project)
  "Eglot server contact for Swift buffers; see `dziman/swift-server-command'."
  (dziman/swift-server-command (and project (project-root project)))
  )

(defun dziman/swift-package-root (directory)
  "Nearest directory at or above DIRECTORY holding Package.swift or buildServer.json, or nil."
  (locate-dominating-file directory
    (lambda (dir)
      (or
        (file-exists-p (expand-file-name "Package.swift" dir))
        (file-exists-p (expand-file-name "buildServer.json" dir))
        )
      )
    )
  )

(defvar eglot-lsp-context)

(defun dziman/swift-project-find (directory)
  "Eglot's project for a Swift buffer: the package or app folder around DIRECTORY.
Other project commands keep their usual root."
  (when-let* (
               ((bound-and-true-p eglot-lsp-context))
               ((derived-mode-p 'swift-mode))
               (root (dziman/swift-package-root directory))
               )
    (cons 'dziman-swift root)
    )
  )

;; Inside the after-load: adding to `project-find-functions' before project.el defines it
;; would leave out project.el's default VC finder
(with-eval-after-load 'project
  (cl-defmethod project-root ((project (head dziman-swift)))
    (cdr project)
    )
  (add-hook 'project-find-functions #'dziman/swift-project-find)
  )
```

- [ ] **Step 6: Run the tests to verify they pass**

Run the test command with group `server`.
Expected: all `dziman-swift-server/` tests pass (`installed-sdk-reports-path-and-version` skipped only on a machine without `xcrun`).

- [ ] **Step 7: Commit**

```bash
git add .emacs-dziman/configs/dz-config-swift.el .emacs-dziman/tests/dz-config-swift-test.el
git commit -F - <<'EOF'
[emacs] Swift: sourcekit-lsp per package folder, platform SDK switch

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 2: eglot config, start guard and wiring into `.emacs`

**Files:**
- Create: `.emacs-dziman/configs/dz-config-eglot.el`
- Modify: `.emacs-dziman/configs/dz-config-swift.el` (tool lookup, start guard, eglot registration)
- Modify: `.emacs:63` (after `(require 'dz-config-prog-languages)`)
- Modify: `.emacs-dziman/custom.el:15-16`
- Test: `.emacs-dziman/tests/dz-config-swift-test.el`

**Interfaces:**
- Consumes: `dziman/swift-eglot-contact` (Task 1).
- Produces:
  - `(dziman/swift-tool-available-p TOOL)` → path string or nil; TOOL is one of `sourcekit-lsp`, `swift-format` (found with `xcrun --find`), `swiftformat`, `swiftlint`, `xed` (found on PATH); cached per session in `dziman/swift--tool-paths`
  - `dziman/swift--xcrun-tools` — list of tool symbols looked up with `xcrun`
  - `(dziman/swift-start-eglot)` — swift-mode hook function
  - eglot keys `M-p r` / `M-p a` / `M-p s` in `eglot-mode-map` (eglot buffers only)

- [ ] **Step 1: Write the stub**

Append to the Language server section of `dz-config-swift.el`, before `(provide 'dz-config-swift)`:

```elisp
;;;;;;;; Tools
(defconst dziman/swift--xcrun-tools '(sourcekit-lsp swift-format)
  "Tools that ship with Xcode and are found with `xcrun --find' rather than on PATH.")

(defvar dziman/swift--tool-paths nil
  "Alist of tool symbol to its path, nil when missing. Filled on first lookup of each tool.")

(defun dziman/swift-tool-available-p (_tool)
  nil
  )

(defun dziman/swift-start-eglot ()
  nil
  )
```

- [ ] **Step 2: Write the failing tests**

Append to `dz-config-swift-test.el`, before `(provide 'dz-config-swift-test)`:

```elisp
;;;;;;;; Starting the language server
(ert-deftest dziman-swift-start/no-language-server-means-no-eglot ()
  (let ((started nil))
    (cl-letf (((symbol-function 'dziman/swift-tool-available-p) #'ignore)
               ((symbol-function 'eglot-ensure) (lambda () (setq started t))))
      (dziman/swift-start-eglot)
      )
    (should-not started)
    )
  )

(ert-deftest dziman-swift-start/installed-language-server-starts-eglot ()
  (let ((started nil))
    (cl-letf (((symbol-function 'dziman/swift-tool-available-p) (lambda (_tool) "/usr/bin/sourcekit-lsp"))
               ((symbol-function 'eglot-ensure) (lambda () (setq started t))))
      (dziman/swift-start-eglot)
      )
    (should started)
    )
  )

(ert-deftest dziman-swift-start/eglot-uses-the-swift-contact ()
  (require 'eglot)
  (should (eq (alist-get 'swift-mode eglot-server-programs) 'dziman/swift-eglot-contact))
  )

(ert-deftest dziman-swift-start/path-tool-found-on-path ()
  (let ((dziman/swift--tool-paths nil))
    (should (dziman/swift-tool-available-p 'emacs))
    )
  )

(ert-deftest dziman-swift-start/missing-path-tool-is-unavailable ()
  (let ((dziman/swift--tool-paths nil))
    (should-not (dziman/swift-tool-available-p 'no-such-swift-tool))
    )
  )

(ert-deftest dziman-swift-start/missing-xcode-tool-is-unavailable ()
  (let ((dziman/swift--tool-paths nil)
         (dziman/swift--xcrun-tools '(no-such-swift-tool)))
    (should-not (dziman/swift-tool-available-p 'no-such-swift-tool))
    )
  )

(ert-deftest dziman-swift-start/tool-is-looked-up-once-per-session ()
  (let ((dziman/swift--tool-paths nil)
         (lookups 0))
    (cl-letf (((symbol-function 'executable-find) (lambda (_name &rest _) (setq lookups (1+ lookups)) nil)))
      (dziman/swift-tool-available-p 'swiftlint)
      (dziman/swift-tool-available-p 'swiftlint)
      )
    (should (= lookups 1))
    )
  )
```

- [ ] **Step 3: Run the tests to verify they fail**

Run the test command with group `start`.
Expected: FAIL — `installed-language-server-starts-eglot` (`started` is nil), `eglot-uses-the-swift-contact` (alist-get returns nil), `path-tool-found-on-path`, `tool-is-looked-up-once-per-session` (`lookups` is 0) fail on their assertions; `no-language-server-means-no-eglot`, `missing-…-is-unavailable` pass against the stub. Quote one assertion failure.

- [ ] **Step 4: Implement the Swift side**

Replace the two stubs in `dz-config-swift.el` with:

```elisp
(defun dziman/swift--locate-tool (tool)
  (let ((name (symbol-name tool)))
    (if (memq tool dziman/swift--xcrun-tools)
      (ignore-errors (car (process-lines "xcrun" "--find" name)))
      (executable-find name)
      )
    )
  )

(defun dziman/swift-tool-available-p (tool)
  "Path of TOOL (a symbol such as `swiftlint'), or nil when it is not installed.
Looked up once per session."
  (let ((cached (assq tool dziman/swift--tool-paths)))
    (if cached
      (cdr cached)
      (let ((path (dziman/swift--locate-tool tool)))
        (push (cons tool path) dziman/swift--tool-paths)
        path
        )
      )
    )
  )

(defun dziman/swift-start-eglot ()
  "Start eglot in a Swift buffer when Apple's language server is installed."
  (when (dziman/swift-tool-available-p 'sourcekit-lsp)
    (eglot-ensure)
    )
  )

(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs '(swift-mode . dziman/swift-eglot-contact))
  )

(add-hook 'swift-mode-hook #'dziman/swift-start-eglot)
(add-hook 'swift-mode-hook #'flycheck-mode)
```

- [ ] **Step 5: Run the tests to verify they pass**

Run the test command with group `start`, then with no group.
Expected: all pass.

- [ ] **Step 6: Create `dz-config-eglot.el`**

```elisp
;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Eglot (Language Server Protocol client) settings shared by all languages
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package eglot
  :ensure nil
  :defer t
  :bind
  (:map eglot-mode-map
    ("M-p r" . eglot-rename)
    ("M-p a" . eglot-code-actions)
    ("M-p s" . consult-eglot-symbols)
    )
  :custom
  (eglot-autoshutdown t)
  (eglot-extend-to-xref t)
  )

;; Diagnostics go to flycheck (margin marks, flycheck-inline, `M-g e') instead of flymake.
;; Not exclusive, so a language's own flycheck checker (e.g. SwiftLint) runs after the server's.
(use-package flycheck-eglot
  :after eglot
  :custom
  (flycheck-eglot-exclusive nil)
  :config
  (global-flycheck-eglot-mode 1)
  )

(use-package consult-eglot
  :defer t
  :commands consult-eglot-symbols
  )

(provide 'dz-config-eglot)
```

- [ ] **Step 7: Require both files from `.emacs`**

In `.emacs`, after `(require 'dz-config-prog-languages)`:

```elisp
(require 'dz-config-prog-languages)
(require 'dz-config-eglot)
(require 'dz-config-swift)
(require 'dz-config-ibuffer)
```

- [ ] **Step 8: Drop the stale lsp-mode entries from `custom.el`**

In `.emacs-dziman/custom.el`, `safe-local-variable-values` becomes:

```elisp
 '(safe-local-variable-values
    '((web-mode-indent-style . 2) (web-mode-block-padding . 2)
       (web-mode-script-padding . 2) (web-mode-style-padding . 2)
       (rustic-indent-offset . 2))))
```

- [ ] **Step 9: Verify the whole config loads**

```bash
DZIMAN_EMACS_SETTINGS_DIR=$PWD/.emacs-dziman emacs --batch -f package-initialize -l .emacs \
  --eval "(progn (require 'eglot) (princ (format \"eglot keys: %S %S %S\n\" (lookup-key eglot-mode-map (kbd \"M-p r\")) (lookup-key eglot-mode-map (kbd \"M-p a\")) (lookup-key eglot-mode-map (kbd \"M-p s\")))))"
```

Expected: no errors or warnings; prints `eglot keys: eglot-rename eglot-code-actions consult-eglot-symbols`.

- [ ] **Step 10: Commit**

```bash
git add .emacs .emacs-dziman/custom.el .emacs-dziman/configs/dz-config-eglot.el .emacs-dziman/configs/dz-config-swift.el .emacs-dziman/tests/dz-config-swift-test.el
git commit -F - <<'EOF'
[emacs] eglot config; start sourcekit-lsp for Swift buffers when installed

Drops the leftover lsp-mode `register-swift-lsp-client' safe local values.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 3: SwiftLint checker

**Files:**
- Modify: `.emacs-dziman/configs/dz-config-swift.el`
- Test: `.emacs-dziman/tests/dz-config-swift-test.el`

**Interfaces:**
- Consumes: `dziman-swift-test-with-project` (Task 1).
- Produces:
  - `(dziman/swift-lint-root DIRECTORY)` → topmost directory at or above DIRECTORY holding `.swiftlint.yml`, or nil
  - `(dziman/swift-swiftlint-parse OUTPUT CHECKER BUFFER)` → list of `flycheck-error`
  - flycheck checker `swift-swiftlint`, first in `flycheck-checkers`

SwiftLint reading stdin only applies the config in its working directory (probed: nested configs ignored). The checker lints a temp copy of the buffer next to the file (`source-inplace`) from the topmost config folder, which applies every config on the way down.

- [ ] **Step 1: Write the stub**

Append to `dz-config-swift.el`, before `(provide 'dz-config-swift)`:

```elisp
;;;;;;;; SwiftLint
(defun dziman/swift-lint-root (_directory)
  nil
  )

(defun dziman/swift-swiftlint-parse (_output _checker _buffer)
  nil
  )
```

- [ ] **Step 2: Write the failing tests**

Append to `dz-config-swift-test.el`, before `(provide 'dz-config-swift-test)`:

```elisp
;;;;;;;; SwiftLint
(defconst dziman-swift-test-force-cast-json
  "[{\"character\":11,\"file\":\"/p/X.swift\",\"line\":3,\"reason\":\"Force casts should be avoided\",\"rule_id\":\"force_cast\",\"severity\":\"Error\",\"type\":\"Force Cast\"}]"
  "SwiftLint 0.65 JSON reporter output for one error.")

(defun dziman-swift-test-error-summary (errors)
  (mapcar
    (lambda (e) (list (flycheck-error-line e) (flycheck-error-column e) (flycheck-error-level e) (flycheck-error-message e)))
    errors
    )
  )

(ert-deftest dziman-swift-lint/project-without-swiftlint-config-is-not-linted ()
  (dziman-swift-test-with-project '("Sources/A/X.swift")
    (should-not (dziman/swift-lint-root (expand-file-name "Sources/A/" root)))
    )
  )

(ert-deftest dziman-swift-lint/file-below-config-runs-from-config-folder ()
  (dziman-swift-test-with-project '(".swiftlint.yml" "Sources/A/X.swift")
    (should (dziman-swift-test-same-dir-p (dziman/swift-lint-root (expand-file-name "Sources/A/" root)) root))
    )
  )

(ert-deftest dziman-swift-lint/nested-config-runs-from-topmost-config ()
  (dziman-swift-test-with-project '(".swiftlint.yml" "Sources/A/.swiftlint.yml" "Sources/A/X.swift")
    (should (dziman-swift-test-same-dir-p (dziman/swift-lint-root (expand-file-name "Sources/A/" root)) root))
    )
  )

(ert-deftest dziman-swift-lint/violation-is-reported-with-its-rule ()
  (require 'flycheck)
  (with-temp-buffer
    (should (equal
              (dziman-swift-test-error-summary
                (dziman/swift-swiftlint-parse dziman-swift-test-force-cast-json 'swift-swiftlint (current-buffer)))
              '((3 11 error "Force casts should be avoided [force_cast]"))))
    )
  )

(ert-deftest dziman-swift-lint/warning-without-column-stays-a-warning ()
  (require 'flycheck)
  (with-temp-buffer
    (should (equal
              (dziman-swift-test-error-summary
                (dziman/swift-swiftlint-parse
                  "[{\"character\":null,\"line\":1,\"reason\":\"Line should be 120 characters or less\",\"rule_id\":\"line_length\",\"severity\":\"Warning\"}]"
                  'swift-swiftlint (current-buffer)))
              '((1 nil warning "Line should be 120 characters or less [line_length]"))))
    )
  )

(ert-deftest dziman-swift-lint/clean-file-has-no-errors ()
  (with-temp-buffer
    (should-not (dziman/swift-swiftlint-parse "[\n\n]\n" 'swift-swiftlint (current-buffer)))
    )
  )

(ert-deftest dziman-swift-lint/silent-swiftlint-has-no-errors ()
  (with-temp-buffer
    (should-not (dziman/swift-swiftlint-parse "" 'swift-swiftlint (current-buffer)))
    )
  )

(ert-deftest dziman-swift-lint/checker-runs-in-swift-buffers-first ()
  ;; flycheck-eglot chains the first checker in `flycheck-checkers' that supports the mode;
  ;; flycheck's own `swift' checker (swiftc -parse) must not be that one
  (require 'flycheck)
  (should (eq (cl-find-if (lambda (c) (flycheck-checker-supports-major-mode-p c 'swift-mode)) flycheck-checkers)
            'swift-swiftlint))
  )
```

- [ ] **Step 3: Run the tests to verify they fail**

Run the test command with group `lint`.
Expected: FAIL — `file-below-config-…` and `nested-config-…` (nil root), `violation-is-reported-…`, `warning-without-column-…` (got nil), `checker-runs-in-swift-buffers-first` (got `swift`). The two "no errors" tests and the no-config test pass on the stub. Quote one assertion failure.

- [ ] **Step 4: Implement**

Replace the stubs in `dz-config-swift.el` with:

```elisp
(require 'subr-x)

(defun dziman/swift-lint-root (directory)
  "Topmost directory at or above DIRECTORY holding .swiftlint.yml, or nil when there is none.
SwiftLint run from there applies that config and every nested one down to the file."
  (let ((dir (locate-dominating-file directory ".swiftlint.yml"))
         (root nil))
    (while dir
      (setq root dir)
      (let ((parent (file-name-directory (directory-file-name dir))))
        (setq dir (and (not (equal parent dir)) (locate-dominating-file parent ".swiftlint.yml")))
        )
      )
    root
    )
  )

(defun dziman/swift-swiftlint-parse (output checker buffer)
  "Flycheck errors for BUFFER from SwiftLint's JSON reporter OUTPUT."
  (unless (string-blank-p output)
    (mapcar
      (lambda (violation)
        (let ((rule (alist-get 'rule_id violation)))
          (flycheck-error-new-at
            (alist-get 'line violation)
            (alist-get 'character violation)
            (if (equal (alist-get 'severity violation) "Error") 'error 'warning)
            (format "%s [%s]" (alist-get 'reason violation) rule)
            :id rule
            :checker checker
            :buffer buffer
            :filename (buffer-file-name buffer)
            )
          )
        )
      (json-parse-string output :object-type 'alist :array-type 'list :null-object nil)
      )
    )
  )

(declare-function flycheck-define-command-checker "flycheck")
(declare-function flycheck-error-new-at "flycheck")

(with-eval-after-load 'flycheck
  (flycheck-define-command-checker 'swift-swiftlint
    "SwiftLint, in projects that have a .swiftlint.yml."
    :command '("swiftlint" "lint" "--quiet" "--reporter" "json" source-inplace)
    :error-parser #'dziman/swift-swiftlint-parse
    :working-directory (lambda (_checker) (dziman/swift-lint-root default-directory))
    :predicate (lambda () (and buffer-file-name (dziman/swift-lint-root default-directory)))
    :modes '(swift-mode)
    )
  (add-to-list 'flycheck-checkers 'swift-swiftlint)
  )
```

- [ ] **Step 5: Run the tests to verify they pass**

Run the test command with group `lint`, then with no group.
Expected: all pass.

- [ ] **Step 6: Check the checker against real SwiftLint**

```bash
D=$(mktemp -d) && mkdir -p $D/Sources/A && printf 'only_rules:\n  - force_unwrapping\n' > $D/.swiftlint.yml \
  && printf 'only_rules:\n  - force_cast\n' > $D/Sources/A/.swiftlint.yml \
  && printf 'let a: Int? = 1\nlet c = 1 as! Int\n' > $D/Sources/A/X.swift
emacs --batch -f package-initialize -L .emacs-dziman/configs --eval "(progn (require 'flycheck) (require 'dz-config-swift) (find-file \"$D/Sources/A/X.swift\") (flycheck-mode 1) (flycheck-select-checker 'swift-swiftlint) (flycheck-buffer) (while (flycheck-running-p) (accept-process-output nil 0.2)) (princ (format \"%S\n\" (mapcar #'flycheck-error-message flycheck-current-errors))))"
```

Expected (skip on a machine without `swiftlint`): `("Force casts should be avoided [force_cast]")`. The nested config's rule applies, proving the run from the topmost folder.

- [ ] **Step 7: Commit**

```bash
git add .emacs-dziman/configs/dz-config-swift.el .emacs-dziman/tests/dz-config-swift-test.el
git commit -F - <<'EOF'
[emacs] Swift: SwiftLint flycheck checker for projects with .swiftlint.yml

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 4: Formatting

**Files:**
- Modify: `.emacs-dziman/configs/dz-config-swift.el`
- Test: `.emacs-dziman/tests/dz-config-swift-test.el`

**Interfaces:**
- Consumes: `dziman/swift-tool-available-p` (Task 2), `dziman-swift-test-with-project` (Task 1).
- Produces:
  - `(dziman/swift-formatter-config DIRECTORY)` → `(FORMATTER . CONFIG-DIR)` for the nearest formatter config, or nil
  - `(dziman/swift-formatter DIRECTORY)` → `swiftformat` or `swift-format`
  - `(dziman/swift-format-buffer)` — interactive command, also the before-save function
  - `(dziman/swift-format-on-save-setup)` — swift-mode hook function

`reformatter-define` is an autoloaded macro, so loading this file loads `reformatter` (about 2 ms).

- [ ] **Step 1: Write the stub**

Append to `dz-config-swift.el`, before `(provide 'dz-config-swift)`:

```elisp
;;;;;;;; Formatting
(defun dziman/swift-formatter-config (_directory)
  nil
  )

(defun dziman/swift-formatter (_directory)
  'swift-format
  )

(defun dziman/swift-format-buffer ()
  (interactive)
  nil
  )

(defun dziman/swift-format-on-save-setup ()
  nil
  )
```

- [ ] **Step 2: Write the failing tests**

Append to `dz-config-swift-test.el`, before `(provide 'dz-config-swift-test)`:

```elisp
;;;;;;;; Formatting
(ert-deftest dziman-swift-format/swiftformat-config-selects-swiftformat ()
  (dziman-swift-test-with-project '(".swiftformat" "Sources/X.swift")
    (should (eq (dziman/swift-formatter (expand-file-name "Sources/" root)) 'swiftformat))
    )
  )

(ert-deftest dziman-swift-format/swift-format-config-selects-apple-formatter ()
  (dziman-swift-test-with-project '(".swift-format" "Sources/X.swift")
    (should (eq (dziman/swift-formatter (expand-file-name "Sources/" root)) 'swift-format))
    )
  )

(ert-deftest dziman-swift-format/nearest-config-wins ()
  (dziman-swift-test-with-project '(".swift-format" "Sources/.swiftformat" "Sources/X.swift")
    (should (eq (dziman/swift-formatter (expand-file-name "Sources/" root)) 'swiftformat))
    )
  )

(ert-deftest dziman-swift-format/swiftformat-wins-in-the-same-folder ()
  (dziman-swift-test-with-project '(".swift-format" ".swiftformat" "Sources/X.swift")
    (should (eq (dziman/swift-formatter (expand-file-name "Sources/" root)) 'swiftformat))
    )
  )

(ert-deftest dziman-swift-format/unconfigured-project-uses-apple-formatter ()
  (dziman-swift-test-with-project '("Sources/X.swift")
    (should (eq (dziman/swift-formatter (expand-file-name "Sources/" root)) 'swift-format))
    )
  )

(ert-deftest dziman-swift-format/configured-project-formats-on-save ()
  (dziman-swift-test-with-project '(".swift-format" "X.swift")
    (with-temp-buffer
      (setq buffer-file-name (expand-file-name "X.swift" root) default-directory root)
      (dziman/swift-format-on-save-setup)
      (should (memq #'dziman/swift-format-buffer before-save-hook))
      (setq buffer-file-name nil)
      )
    )
  )

(ert-deftest dziman-swift-format/unconfigured-project-does-not-format-on-save ()
  (dziman-swift-test-with-project '("X.swift")
    (with-temp-buffer
      (setq buffer-file-name (expand-file-name "X.swift" root) default-directory root)
      (dziman/swift-format-on-save-setup)
      (should-not (memq #'dziman/swift-format-buffer before-save-hook))
      (setq buffer-file-name nil)
      )
    )
  )

(ert-deftest dziman-swift-format/missing-formatter-leaves-buffer-unchanged ()
  (dziman-swift-test-with-project '()
    (with-temp-buffer
      (setq default-directory root)
      (insert "let a=[1,2 ,3]\n")
      (cl-letf (((symbol-function 'dziman/swift-tool-available-p) #'ignore))
        (dziman/swift-format-buffer)
        )
      (should (equal (buffer-string) "let a=[1,2 ,3]\n"))
      )
    )
  )

(ert-deftest dziman-swift-format/missing-formatter-names-it-in-a-note ()
  (let ((note nil))
    (with-temp-buffer
      (setq default-directory temporary-file-directory)
      (cl-letf (((symbol-function 'dziman/swift-tool-available-p) #'ignore)
                 ((symbol-function 'message) (lambda (fmt &rest args) (setq note (apply #'format-message fmt args)))))
        (dziman/swift-format-buffer)
        )
      )
    (should (equal note "Apple swift-format is not installed; buffer not formatted"))
    )
  )

(ert-deftest dziman-swift-format/apple-formatter-reformats-a-scratch-buffer ()
  (skip-unless (dziman/swift-tool-available-p 'swift-format))
  (dziman-swift-test-with-project '()
    (with-temp-buffer
      (setq default-directory root)
      (insert "let a=[1,2 ,3]\n")
      (dziman/swift-format-buffer)
      (should (equal (buffer-string) "let a = [1, 2, 3]\n"))
      )
    )
  )

(ert-deftest dziman-swift-format/swiftformat-reformats-in-its-project ()
  (skip-unless (dziman/swift-tool-available-p 'swiftformat))
  (dziman-swift-test-with-project '(".swiftformat")
    (with-temp-buffer
      (setq default-directory root)
      (insert "let a=[1,2 ,3]\n")
      (dziman/swift-format-buffer)
      (should (equal (buffer-string) "let a = [1, 2, 3]\n"))
      )
    )
  )
```

- [ ] **Step 3: Run the tests to verify they fail**

Run the test command with group `format`.
Expected: FAIL — `swiftformat-config-selects-swiftformat`, `nearest-config-wins`, `swiftformat-wins-in-the-same-folder` (got `swift-format`), `configured-project-formats-on-save`, `missing-formatter-names-it-in-a-note` (got nil), both reformat tests (buffer unchanged). The Apple-formatter selection, unconfigured-on-save and unchanged-buffer tests pass on the stub. Quote one assertion failure.

- [ ] **Step 4: Implement**

Replace the stubs in `dz-config-swift.el` with:

```elisp
(use-package reformatter :defer t)

(defconst dziman/swift-formatter-configs
  '((".swiftformat" . swiftformat) (".swift-format" . swift-format))
  "Formatter config file names and the formatter each selects; earlier entries win a tie.")

(defconst dziman/swift-formatter-names
  '((swiftformat . "SwiftFormat") (swift-format . "Apple swift-format"))
  )

(defun dziman/swift-formatter-config (directory)
  "(FORMATTER . CONFIG-DIR) for the formatter config nearest DIRECTORY, or nil when there is none."
  (let ((nearest nil))
    (dolist (entry dziman/swift-formatter-configs nearest)
      (let ((dir (locate-dominating-file directory (car entry))))
        ;; Both are ancestors of DIRECTORY, so the longer path is the nearer one
        (when (and dir (or (null nearest) (> (length (expand-file-name dir)) (length (expand-file-name (cdr nearest))))))
          (setq nearest (cons (cdr entry) dir))
          )
        )
      )
    )
  )

(defun dziman/swift-formatter (directory)
  "Formatter for Swift files under DIRECTORY: the configured one, else Apple swift-format."
  (or (car (dziman/swift-formatter-config directory)) 'swift-format)
  )

(reformatter-define dziman/swift-swiftformat
  :program "swiftformat"
  :args (append '("stdin" "--quiet") (and buffer-file-name (list "--stdin-path" buffer-file-name)))
  :mode nil
  )

(reformatter-define dziman/swift-apple-format
  :program "xcrun"
  :args (append '("swift-format" "format") (and buffer-file-name (list "--assume-filename" buffer-file-name)) '("-"))
  :mode nil
  )

(defun dziman/swift-format-buffer ()
  "Reformat the buffer with the project's Swift formatter; see `dziman/swift-formatter'."
  (interactive)
  (let ((formatter (dziman/swift-formatter default-directory)))
    (cond
      ((not (dziman/swift-tool-available-p formatter))
        (message "%s is not installed; buffer not formatted" (alist-get formatter dziman/swift-formatter-names))
        )
      ((eq formatter 'swiftformat) (dziman/swift-swiftformat-buffer t))
      (t (dziman/swift-apple-format-buffer t))
      )
    )
  )

(defun dziman/swift-format-on-save-setup ()
  "Format on save in projects that have a formatter config."
  (when (and buffer-file-name (dziman/swift-formatter-config default-directory))
    (add-hook 'before-save-hook #'dziman/swift-format-buffer nil t)
    )
  )

(add-hook 'swift-mode-hook #'dziman/swift-format-on-save-setup)
```

- [ ] **Step 5: Run the tests to verify they pass**

Run the test command with group `format`, then with no group.
Expected: all pass (the two reformat tests skip only where the tool is missing).

- [ ] **Step 6: Commit**

```bash
git add .emacs-dziman/configs/dz-config-swift.el .emacs-dziman/tests/dz-config-swift-test.el
git commit -F - <<'EOF'
[emacs] Swift: per-project formatter, format on save where configured

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 5: Helpers and Swift keys

**Files:**
- Modify: `.emacs-dziman/configs/dz-config-swift.el`
- Test: `.emacs-dziman/tests/dz-config-swift-test.el`

**Interfaces:**
- Consumes: `dziman/swift-tool-available-p` (Task 2), `dziman/swift-format-buffer` (Task 4), eglot keys (Task 2).
- Produces:
  - `(dziman/swift-open-in-xcode)` — interactive
  - `(dziman/swift-apple-docs-url TERM)` → string
  - `(dziman/swift-apple-docs TERM)` — interactive
  - `dziman/bind-map/swift` — `M-p` map for `swift-mode`

Emacs merges the `M-p` prefix maps of the prog-mode bind-map, this Swift map and `eglot-mode-map` (probed), so each map holds only its own keys.

- [ ] **Step 1: Write the stub**

Append to `dz-config-swift.el`, before `(provide 'dz-config-swift)`:

```elisp
;;;;;;;; Helpers
(defun dziman/swift-open-in-xcode ()
  (interactive)
  nil
  )

(defun dziman/swift-apple-docs-url (_term)
  ""
  )

(defun dziman/swift-apple-docs (_term)
  (interactive (list nil))
  nil
  )
```

- [ ] **Step 2: Write the failing tests**

At the top of `dz-config-swift-test.el`, replace the line `(require 'dz-config-swift)` with:

```elisp
(require 'dz-config-bind-maps)
(require 'dz-config-prog-mode)
(require 'dz-config-eglot)
(require 'dz-config-swift)
```

Append, before `(provide 'dz-config-swift-test)`:

```elisp
;;;;;;;; Helpers and keys
(ert-deftest dziman-swift-helpers/apple-docs-query-is-url-encoded ()
  (should (equal (dziman/swift-apple-docs-url "Text field") "https://developer.apple.com/search/?q=Text%20field"))
  )

(ert-deftest dziman-swift-helpers/apple-docs-looks-up-symbol-at-point ()
  (let ((opened nil))
    (with-temp-buffer
      (insert "NavigationStack")
      (goto-char 3)
      (cl-letf (((symbol-function 'browse-url) (lambda (url &rest _) (setq opened url))))
        (call-interactively #'dziman/swift-apple-docs)
        )
      )
    (should (equal opened "https://developer.apple.com/search/?q=NavigationStack"))
    )
  )

(ert-deftest dziman-swift-helpers/open-in-xcode-needs-a-file ()
  (with-temp-buffer
    (should-error (dziman/swift-open-in-xcode) :type 'user-error)
    )
  )

(ert-deftest dziman-swift-helpers/open-in-xcode-selects-the-cursor-line ()
  (let ((args nil))
    (with-temp-buffer
      (setq buffer-file-name "/p/X.swift")
      (insert "a\nb\nc\n")
      (goto-char (point-min))
      (forward-line 2)
      (set-buffer-modified-p nil)
      (cl-letf (((symbol-function 'dziman/swift-tool-available-p) (lambda (_tool) "/usr/bin/xed"))
                 ((symbol-function 'call-process) (lambda (&rest call) (setq args call) 0)))
        (dziman/swift-open-in-xcode)
        )
      (setq buffer-file-name nil)
      )
    (should (equal args '("/usr/bin/xed" nil 0 nil "--line" "3" "/p/X.swift")))
    )
  )

(ert-deftest dziman-swift-helpers/open-in-xcode-saves-unsaved-changes-first ()
  (let ((saved nil))
    (with-temp-buffer
      (setq buffer-file-name "/p/X.swift")
      (insert "a\n")
      (cl-letf (((symbol-function 'dziman/swift-tool-available-p) (lambda (_tool) "/usr/bin/xed"))
                 ((symbol-function 'save-buffer) (lambda (&rest _) (setq saved t) (set-buffer-modified-p nil)))
                 ((symbol-function 'call-process) (lambda (&rest _) 0)))
        (dziman/swift-open-in-xcode)
        )
      (setq buffer-file-name nil)
      )
    (should saved)
    )
  )

(ert-deftest dziman-swift-helpers/swift-buffer-has-swift-keys ()
  (require 'swift-mode)
  (with-temp-buffer
    (let ((swift-mode-hook nil)) (swift-mode))
    (should (equal (list (key-binding (kbd "M-p f")) (key-binding (kbd "M-p x")) (key-binding (kbd "M-p d")))
              '(dziman/swift-format-buffer dziman/swift-open-in-xcode dziman/swift-apple-docs)))
    )
  )

(ert-deftest dziman-swift-helpers/swift-buffer-keeps-prog-keys ()
  (require 'swift-mode)
  (with-temp-buffer
    (let ((swift-mode-hook nil)) (swift-mode))
    (should (eq (key-binding (kbd "M-p U")) 'string-inflection-java-style-cycle))
    )
  )

(ert-deftest dziman-swift-helpers/language-server-buffer-has-eglot-keys ()
  (require 'swift-mode)
  (require 'eglot)
  (with-temp-buffer
    (let ((swift-mode-hook nil)) (swift-mode))
    (setq-local eglot--managed-mode t)
    (should (equal (list (key-binding (kbd "M-p r")) (key-binding (kbd "M-p a")) (key-binding (kbd "M-p s")))
              '(eglot-rename eglot-code-actions consult-eglot-symbols)))
    )
  )

(ert-deftest dziman-swift-helpers/buffer-without-language-server-has-no-eglot-keys ()
  (require 'swift-mode)
  (require 'eglot)
  (with-temp-buffer
    (let ((swift-mode-hook nil)) (swift-mode))
    (should-not (key-binding (kbd "M-p r")))
    )
  )

(ert-deftest dziman-swift-helpers/other-languages-have-no-swift-keys ()
  (with-temp-buffer
    (emacs-lisp-mode)
    (should-not (key-binding (kbd "M-p x")))
    )
  )
```

- [ ] **Step 3: Run the tests to verify they fail**

Run the test command with group `helpers`.
Expected: FAIL — the URL, symbol-at-point, needs-a-file (no error signalled), cursor-line (`args` nil), saves-first (`saved` nil) and swift-keys tests fail on their assertions; the prog-keys, eglot-keys (set up in Task 2), no-eglot-keys and other-languages tests pass. Quote one assertion failure.

- [ ] **Step 4: Implement**

Replace the stubs in `dz-config-swift.el` with:

```elisp
(defun dziman/swift-open-in-xcode ()
  "Open the current file in Xcode at the cursor line, saving it first."
  (interactive)
  (unless buffer-file-name
    (user-error "Buffer is not visiting a file")
    )
  (let ((xed (dziman/swift-tool-available-p 'xed)))
    (unless xed
      (user-error "xed is not installed; it ships with Xcode")
      )
    (when (buffer-modified-p)
      (save-buffer)
      )
    (call-process xed nil 0 nil "--line" (number-to-string (line-number-at-pos)) buffer-file-name)
    )
  )

(defun dziman/swift-apple-docs-url (term)
  (concat "https://developer.apple.com/search/?q=" (url-hexify-string term))
  )

(defun dziman/swift--docs-term ()
  (cond
    ((use-region-p) (buffer-substring-no-properties (region-beginning) (region-end)))
    ((thing-at-point 'symbol t))
    (t (read-string "Apple docs for: "))
    )
  )

(defun dziman/swift-apple-docs (term)
  "Search developer.apple.com for TERM: the selection, else the symbol at point, else asked for."
  (interactive (list (dziman/swift--docs-term)))
  (browse-url (dziman/swift-apple-docs-url term))
  )

(bind-map dziman/bind-map/swift
  :keys ("M-p")
  :major-modes (swift-mode)
  :bindings (
              "f" 'dziman/swift-format-buffer
              "x" 'dziman/swift-open-in-xcode
              "d" 'dziman/swift-apple-docs
              )
  )
```

- [ ] **Step 5: Run the tests to verify they pass**

Run the test command with group `helpers`, then with no group.
Expected: all pass.

- [ ] **Step 6: Commit**

```bash
git add .emacs-dziman/configs/dz-config-swift.el .emacs-dziman/tests/dz-config-swift-test.el
git commit -F - <<'EOF'
[emacs] Swift: Open in Xcode, Apple docs lookup, M-p keys

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 6: Docs and acceptance checks

**Files:**
- Create: `.dziman/docs/emacs-swift.md`
- Modify (only if Step 5 finds a doubled display): `.emacs-dziman/configs/dz-config-eglot.el`

**Interfaces:**
- Consumes: everything above.

- [ ] **Step 1: Write the doc**

Create `.dziman/docs/emacs-swift.md`:

````markdown
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
`M-x normal-mode` in open Swift buffers (or reopen them), then
`M-x eglot-reconnect`. Folders with `buildServer.json` ignore it.

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
| `M-p d` | Apple docs for symbol |
| `M-.` / `M-,` / `M-?` | definition / back / references |

`M-p r`, `a`, `s` exist only in buffers with a running language server.
Indexing progress shows as a percentage in the mode line.
````

- [ ] **Step 2: Full test run and config load**

```bash
emacs --batch -f package-initialize -L .emacs-dziman/configs -L .emacs-dziman/tests -l dz-config-swift-test -f ert-run-tests-batch-and-exit
DZIMAN_EMACS_SETTINGS_DIR=$PWD/.emacs-dziman emacs --batch -f package-initialize -l .emacs
```

Expected: every test passes or skips for a missing tool; the config load prints no errors or warnings.

- [ ] **Step 3: Byte-compile both new files without warnings**

```bash
emacs --batch -f package-initialize -L .emacs-dziman/configs \
  --eval '(setq byte-compile-error-on-warn t byte-compile-dest-file-function (lambda (f) (expand-file-name (concat (file-name-nondirectory f) "c") temporary-file-directory)))' \
  -f batch-byte-compile .emacs-dziman/configs/dz-config-eglot.el .emacs-dziman/configs/dz-config-swift.el
```

Expected: exit 0, no warnings. Fix any warning in the file that raised it (declare-function / defvar / `:custom`), re-run the tests, and amend the task's commit only if it is still the latest commit; otherwise commit the fix as `[emacs] Swift: byte-compile cleanly`.

- [ ] **Step 4: Measure load cost**

```bash
emacs --batch -f package-initialize -L .emacs-dziman/configs \
  --eval "(progn (require 'dz-config-bind-maps) (require 'dz-config-prog-mode) (princ (format \"%.1f ms\n\" (* 1000 (car (benchmark-run 1 (require 'dz-config-eglot) (require 'dz-config-swift)))))))"
```

Expected: a few milliseconds (reformatter ~2 ms). Report the number.

- [ ] **Step 5: Manual checks with the user**

Start Emacs against the checkout:

```bash
DZIMAN_EMACS_SETTINGS_DIR=$PWD/.emacs-dziman emacs -q --eval '(package-activate-all)' -l $PWD/.emacs
```

Check, and report each result:

1. `M-x emacs-init-time` about 0.24 s (compare with the live config).
2. A Swift package importing UIKit with `dziman/swift-platform` `ios`: completion on `UIView`, no false "No such module"; a wrong-type line shows an error. Repeat with `visionos` and with `watchos` (a package importing WatchKit).
3. An Xcode app project with `buildServer.json` (create one with `xcodegen` + `xcode-build-server config` if none exists): completion and `M-.` into project code.
4. Format on save in a project with `.swiftformat` and in one with `.swift-format`; no format on save without either.
5. SwiftLint warnings show inline and on `M-g e` in a project with `.swiftlint.yml`, alongside compiler errors.
6. Each key in the table above.
7. While indexing, the mode line shows a percentage. If doom-modeline shows eglot twice (its own icon and eglot's `[name …]` block), add to `dz-config-eglot.el` under `:custom` of `use-package eglot`:

   ```elisp
   (eglot-mode-line-format '(eglot-mode-line-progress eglot-mode-line-action-suggestion))
   ```

   re-check, and include it in this task's commit.

- [ ] **Step 6: Commit**

```bash
git add .dziman/docs/emacs-swift.md
git add .emacs-dziman/configs/dz-config-eglot.el   # only if Step 5.7 changed it
git commit -F - <<'EOF'
[docs] Swift in Emacs: tools, platform switch, Xcode projects, keys

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```
