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

(put 'dziman/swift-platform 'safe-local-variable
  (lambda (value) (and (assq value dziman/swift-platforms) t))
  )

(defun dziman/swift--sdk (sdk-name)
  "Return (PATH . VERSION) of the Xcode SDK SDK-NAME, or nil when that SDK is not installed."
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
  "Return sourcekit-lsp arguments checking a package against SDK-PATH for TARGET-OS SDK-VERSION."
  ;; Without -isysroot, SwiftPM (Swift 6.4) keeps the Mac SDK for Clang modules: "Cannot load underlying module"
  (list
    "-Xswiftc" "-sdk" "-Xswiftc" sdk-path
    "-Xswiftc" "-target" "-Xswiftc" (format "arm64-apple-%s%s" target-os sdk-version)
    "-Xcc" "-isysroot" "-Xcc" sdk-path
    )
  )

(defun dziman/swift-server-command (&optional root)
  "Return the sourcekit-lsp command for the current buffer's `dziman/swift-platform'.
ROOT is the server's folder; one holding buildServer.json takes its platform from Xcode's build settings.
Unknown platforms and platforms without an installed SDK fall back to Mac, with a message."
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

;;;;;;;; Tools
(defconst dziman/swift--xcrun-tools '(sourcekit-lsp swift-format)
  "Tools that ship with Xcode and are found with `xcrun --find' rather than on PATH.")

(defvar dziman/swift--tool-paths nil
  "Alist of tool symbol to its path, nil when missing. Filled on first lookup of each tool.")

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

(provide 'dz-config-swift)
