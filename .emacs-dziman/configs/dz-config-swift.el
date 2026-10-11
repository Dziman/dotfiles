;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Swift editing: sourcekit-lsp through eglot, SwiftLint, formatting, Xcode helpers.
;;;;;; Xcode builds and runs the apps.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'subr-x)
(use-package swift-mode :defer t)

;;;;;;;; Language server
(defconst dziman/swift-platforms
  '(
     (ios      . ("iphoneos"  . "ios"))
     (tvos     . ("appletvos" . "tvos"))
     (watchos  . ("watchos"   . "watchos"))
     (visionos . ("xros"      . "xros"))
     )
  "Platform switch value to (SDK-NAME . TARGET-OS).
Mac is the absence of a value.")

(defvar-local dziman/swift-platform nil
  "Apple platform a Swift package is checked against; nil for Mac.
A key of `dziman/swift-platforms'.  Set it in the package's .dir-locals.el.
After a change, open buffers need `normal-mode' to re-read it, then
`eglot-reconnect'.  Ignored in folders with buildServer.json.")

(put 'dziman/swift-platform 'safe-local-variable
  (lambda (value) (and (assq value dziman/swift-platforms) t))
  )

(defun dziman/swift--sdk (sdk-name)
  "Return (PATH . VERSION) of the Xcode SDK SDK-NAME, or nil when not installed."
  (condition-case nil
    (when-let* (
                 (path (car (process-lines "xcrun" "--sdk" sdk-name "--show-sdk-path")))
                 (version (car (process-lines "xcrun" "--sdk" sdk-name "--show-sdk-version")))
                 )
      (cons path version)
      )
    ;; xcrun exits non-zero for an unknown SDK and is missing without Xcode's command line tools
    (error nil)
    )
  )

(defun dziman/swift-platform-server-args (target-os sdk-path sdk-version)
  "Return sourcekit-lsp arguments checking a package against SDK-PATH.
TARGET-OS and SDK-VERSION name the target triple."
  ;; Without -isysroot, SwiftPM (Swift 6.4) keeps the Mac SDK for Clang modules: "Cannot load underlying module"
  (list
    "-Xswiftc" "-sdk" "-Xswiftc" sdk-path
    "-Xswiftc" "-target" "-Xswiftc" (format "arm64-apple-%s%s" target-os sdk-version)
    "-Xcc" "-isysroot" "-Xcc" sdk-path
    )
  )

(defun dziman/swift-server-command (&optional root)
  "Return the sourcekit-lsp command for the buffer's `dziman/swift-platform'.
ROOT is the server's folder; one holding buildServer.json takes its platform
from Xcode's build settings.
Unknown platforms and platforms without an installed SDK fall back to Mac,
with a message."
  (let* (
          (mac (list "xcrun" "sourcekit-lsp"))
          (platform (alist-get dziman/swift-platform dziman/swift-platforms))
          sdk
          )
    (cond
      ((null dziman/swift-platform) mac)
      ((and root (file-exists-p (expand-file-name "buildServer.json" root))) mac)
      ((null platform)
        (message "Unknown dziman/swift-platform %S; checking against the Mac SDK" dziman/swift-platform)
        mac
        )
      ;; The SDK lookup runs xcrun, so it is tried only once the earlier clauses have not decided
      ((setq sdk (dziman/swift--sdk (car platform)))
        (append mac (dziman/swift-platform-server-args (cdr platform) (car sdk) (cdr sdk)))
        )
      (t
        (message "SDK %s is not installed; checking against the Mac SDK" (car platform))
        mac
        )
      )
    )
  )

(defun dziman/swift-eglot-contact (_interactive project)
  "Eglot server contact for Swift buffers; see `dziman/swift-server-command'."
  (dziman/swift-server-command (and project (project-root project)))
  )

(defun dziman/swift-package-root (directory)
  "Nearest directory at or above DIRECTORY with Package.swift or buildServer.json."
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
  "Eglot's project for a Swift buffer: the package or app folder of DIRECTORY.
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

;;;;;;;; Tools
(defconst dziman/swift--xcrun-tools '(sourcekit-lsp swift-format)
  "Tools that ship with Xcode, found with `xcrun --find' rather than on PATH.")

(defvar dziman/swift--tool-paths nil
  "Alist of tool symbol to its path, nil when missing.
Filled on first lookup of each tool.")

(defun dziman/swift--locate-tool (tool)
  "Path of TOOL, or nil when it is not installed."
  (let ((name (symbol-name tool)))
    (if (memq tool dziman/swift--xcrun-tools)
      (condition-case nil
        (let ((path (car (process-lines "xcrun" "--find" name))))
          (and path (not (string-empty-p path)) path)
          )
        ;; xcrun exits non-zero for an unknown tool and is missing without Xcode's command line tools
        (error nil)
        )
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

;;;;;;;; SwiftLint
(defun dziman/swift-lint-root (directory)
  "Topmost directory at or above DIRECTORY holding .swiftlint.yml, or nil.
SwiftLint run from there applies that config and every nested one down to
the file."
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
  "Flycheck errors for BUFFER from SwiftLint's JSON reporter OUTPUT.
Output that is not JSON signals `json-parse-error', which flycheck reports
as a checker failure; that is how SwiftLint's configuration errors surface."
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
(declare-function evil-normalize-keymaps "evil")
(declare-function reformatter--do-region "reformatter")
(declare-function reformatter--make-temp-file "reformatter")

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

;;;;;;;; Formatting
(use-package reformatter :defer t)

(defconst dziman/swift-formatter-configs
  '((".swiftformat" . swiftformat) (".swift-format" . swift-format))
  "Formatter config file names and the formatter each selects.
Earlier entries win a tie.")

(defconst dziman/swift-formatter-names
  '((swiftformat . "SwiftFormat") (swift-format . "Apple swift-format"))
  "Display name of each formatter."
  )

(defun dziman/swift-formatter-config (directory)
  "(FORMATTER . CONFIG-DIR) for the formatter config nearest DIRECTORY, or nil."
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
  "Formatter for Swift files under DIRECTORY: configured, else Apple swift-format."
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

(defun dziman/swift--missing-formatter-note (formatter)
  (format "%s is not installed; buffer not formatted" (alist-get formatter dziman/swift-formatter-names))
  )

(defun dziman/swift--run-formatter (formatter)
  "Reformat the buffer with FORMATTER.
A failing formatter leaves the buffer as is and shows its output."
  ;; Only reformatter's own "Formatting buffer" echo is silenced; errors go to its error buffer
  (let ((inhibit-message t))
    (if (eq formatter 'swiftformat)
      (dziman/swift-swiftformat-buffer t)
      (dziman/swift-apple-format-buffer t)
      )
    )
  )

(defun dziman/swift-format-buffer ()
  "Reformat the buffer with the project's `dziman/swift-formatter'."
  (interactive)
  (let ((formatter (dziman/swift-formatter default-directory)))
    (if (dziman/swift-tool-available-p formatter)
      (dziman/swift--run-formatter formatter)
      (message "%s" (dziman/swift--missing-formatter-note formatter))
      )
    )
  )

(defun dziman/swift--format-before-save ()
  "`dziman/swift-format-buffer' for `before-save-hook'.
A missing-formatter note is deferred so it outlasts the save's own message."
  (let ((formatter (dziman/swift-formatter default-directory)))
    (if (dziman/swift-tool-available-p formatter)
      (dziman/swift--run-formatter formatter)
      (run-at-time 0 nil #'message "%s" (dziman/swift--missing-formatter-note formatter))
      )
    )
  )

(defun dziman/swift-format-on-save-setup ()
  "Format on save in projects that have a formatter config."
  (when (and buffer-file-name (dziman/swift-formatter-config default-directory))
    (add-hook 'before-save-hook #'dziman/swift--format-before-save nil t)
    )
  )

(add-hook 'swift-mode-hook #'dziman/swift-format-on-save-setup)

;;;;;;;; Helpers
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
  "Search developer.apple.com for TERM.
Interactively: the selection, else the symbol at point, else asked for."
  (interactive (list (dziman/swift--docs-term)))
  (when (string-blank-p term)
    (user-error "Nothing to look up")
    )
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

(provide 'dz-config-swift)
