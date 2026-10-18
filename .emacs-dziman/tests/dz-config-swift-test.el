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
(require 'dz-config-bind-maps)
(require 'dz-config-prog-mode)
(require 'dz-config-eglot)
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

(defmacro dziman-swift-test-capturing-messages (&rest body)
  "Run BODY and return the list of messages it issued, oldest first."
  (declare (indent 0))
  `(let ((messages nil))
     (cl-letf (((symbol-function 'message)
                 (lambda (format-string &rest args) (push (apply #'format format-string args) messages))))
       ,@body
       )
     (nreverse messages)
     )
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
      (let (command)
        (should (equal (dziman-swift-test-capturing-messages (setq command (dziman/swift-server-command)))
                  '("SDK xros is not installed; checking against the Mac SDK")))
        (should (equal command '("xcrun" "sourcekit-lsp")))
        )
      )
    )
  )

(ert-deftest dziman-swift-server/unknown-platform-falls-back-to-mac ()
  (with-temp-buffer
    (setq dziman/swift-platform 'iphone)
    (let (command)
      (should (equal (dziman-swift-test-capturing-messages (setq command (dziman/swift-server-command)))
                '("Unknown dziman/swift-platform iphone; checking against the Mac SDK")))
      (should (equal command '("xcrun" "sourcekit-lsp")))
      )
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

;;;;;;;; Platform switch in .dir-locals.el
(ert-deftest dziman-swift-server/platform-switch-is-safe-for-known-platforms ()
  (should (safe-local-variable-p 'dziman/swift-platform 'visionos))
  )

(ert-deftest dziman-swift-server/platform-switch-is-unsafe-for-other-values ()
  (should-not (safe-local-variable-p 'dziman/swift-platform 'iphone))
  )

;;;;;;;; Installed SDK lookup
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

(ert-deftest dziman-swift-server/sdk-without-xcrun-output-reports-nothing ()
  (cl-letf (((symbol-function 'process-lines) (lambda (&rest _args) nil)))
    (should-not (dziman/swift--sdk "iphoneos"))
    )
  )

;;;;;;;; Eglot server contact
(ert-deftest dziman-swift-server/eglot-contact-is-the-server-command ()
  (with-temp-buffer
    (should (equal (dziman/swift-eglot-contact nil nil) '("xcrun" "sourcekit-lsp")))
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
  (dziman-swift-test-with-project
    '("App/buildServer.json" "App/Packages/Kit/Package.swift" "App/Packages/Kit/Sources/X.swift")
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
        (should (dziman-swift-test-same-dir-p
                  (cdr (dziman/swift-project-find (expand-file-name "Sources/" root)))
                  root))
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

(ert-deftest dziman-swift-server/swift-finder-is-registered-beside-vc-finder ()
  ;; Registering the Swift finder must keep project.el's own VC finder
  (should (memq #'dziman/swift-project-find project-find-functions))
  (should (memq #'project-try-vc project-find-functions))
  )

(ert-deftest dziman-swift-server/file-outside-any-package-has-no-package-folder ()
  (dziman-swift-test-with-project '("Loose/X.swift")
    (let ((default-directory root))
      (should-not (dziman/swift-package-root (expand-file-name "Loose/" root)))
      )
    )
  )

(ert-deftest dziman-swift-server/file-outside-any-package-gets-no-eglot-project ()
  (dziman-swift-test-with-project '("Loose/X.swift")
    (with-temp-buffer
      (setq-local major-mode 'swift-mode)
      (let ((eglot-lsp-context t))
        (should-not (dziman/swift-project-find (expand-file-name "Loose/" root)))
        )
      )
    )
  )

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
    (cl-letf (((symbol-function 'executable-find) (lambda (_name &rest _) "/usr/local/bin/swiftlint")))
      (should (equal (dziman/swift-tool-available-p 'swiftlint) "/usr/local/bin/swiftlint"))
      )
    )
  )

(ert-deftest dziman-swift-start/missing-path-tool-is-unavailable ()
  (let ((dziman/swift--tool-paths nil))
    (should-not (dziman/swift-tool-available-p 'no-such-swift-tool))
    )
  )

(ert-deftest dziman-swift-start/missing-xcode-tool-is-unavailable ()
  (let ((dziman/swift--tool-paths nil))
    (cl-letf (((symbol-function 'process-lines) (lambda (&rest _args) (error "xcrun failed"))))
      (should-not (dziman/swift-tool-available-p 'sourcekit-lsp))
      )
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

(ert-deftest dziman-swift-start/empty-xcrun-output-means-tool-missing ()
  (let ((dziman/swift--tool-paths nil))
    (cl-letf (((symbol-function 'process-lines) (lambda (&rest _args) '(""))))
      (should-not (dziman/swift-tool-available-p 'sourcekit-lsp))
      )
    )
  )

(ert-deftest dziman-swift-start/swift-buffers-start-eglot-and-flycheck ()
  (should (memq #'dziman/swift-start-eglot swift-mode-hook))
  (should (memq #'flycheck-mode swift-mode-hook))
  )

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

(ert-deftest dziman-swift-lint/non-json-output-is-a-checker-failure ()
  (with-temp-buffer
    (should-error (dziman/swift-swiftlint-parse "error: Invalid configuration" 'swift-swiftlint (current-buffer))
      :type 'json-parse-error)
    )
  )

(ert-deftest dziman-swift-lint/buffer-without-file-is-not-linted ()
  (require 'flycheck)
  (with-temp-buffer
    (should-not (funcall (flycheck-checker-get 'swift-swiftlint 'predicate)))
    )
  )

(ert-deftest dziman-swift-lint/file-without-swiftlint-config-is-not-linted ()
  (require 'flycheck)
  (dziman-swift-test-with-project '("Sources/A/X.swift")
    (with-temp-buffer
      (setq buffer-file-name (expand-file-name "Sources/A/X.swift" root)
        default-directory (expand-file-name "Sources/A/" root))
      (should-not (funcall (flycheck-checker-get 'swift-swiftlint 'predicate)))
      )
    )
  )

(ert-deftest dziman-swift-lint/file-under-swiftlint-config-is-linted-from-topmost-config ()
  (require 'flycheck)
  (dziman-swift-test-with-project '(".swiftlint.yml" "Sources/A/.swiftlint.yml" "Sources/A/X.swift")
    (with-temp-buffer
      (setq buffer-file-name (expand-file-name "Sources/A/X.swift" root)
        default-directory (expand-file-name "Sources/A/" root))
      (should (funcall (flycheck-checker-get 'swift-swiftlint 'predicate)))
      (should (dziman-swift-test-same-dir-p
                (funcall (flycheck-checker-get 'swift-swiftlint 'working-directory) 'swift-swiftlint)
                root))
      )
    )
  )

(ert-deftest dziman-swift-lint/checker-runs-in-swift-buffers-first ()
  ;; flycheck-eglot chains the first checker in `flycheck-checkers' that supports the mode;
  ;; flycheck's own `swift' checker (swiftc -parse) must not be that one
  (require 'flycheck)
  (should (eq (cl-find-if (lambda (c) (flycheck-checker-supports-major-mode-p c 'swift-mode)) flycheck-checkers)
            'swift-swiftlint))
  )

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
      (should (memq #'dziman/swift--format-before-save before-save-hook))
      (setq buffer-file-name nil)
      )
    )
  )

(ert-deftest dziman-swift-format/unconfigured-project-does-not-format-on-save ()
  (dziman-swift-test-with-project '("X.swift")
    (with-temp-buffer
      (setq buffer-file-name (expand-file-name "X.swift" root) default-directory root)
      (dziman/swift-format-on-save-setup)
      (should-not (memq #'dziman/swift--format-before-save before-save-hook))
      (setq buffer-file-name nil)
      )
    )
  )

(ert-deftest dziman-swift-format/swift-buffers-set-up-format-on-save ()
  (should (memq #'dziman/swift-format-on-save-setup swift-mode-hook))
  )

(ert-deftest dziman-swift-format/missing-formatter-leaves-buffer-unchanged ()
  (dziman-swift-test-with-project '()
    (with-temp-buffer
      (setq default-directory root)
      (insert "let a=[1,2 ,3]\n")
      (cl-letf (((symbol-function 'dziman/swift-tool-available-p) #'ignore))
        (dziman-swift-test-capturing-messages (dziman/swift-format-buffer))
        )
      (should (equal (buffer-string) "let a=[1,2 ,3]\n"))
      )
    )
  )

(ert-deftest dziman-swift-format/missing-formatter-names-it-in-a-note ()
  (with-temp-buffer
    (setq default-directory temporary-file-directory)
    (cl-letf (((symbol-function 'dziman/swift-tool-available-p) #'ignore))
      (should (equal (dziman-swift-test-capturing-messages (dziman/swift-format-buffer))
                '("Apple swift-format is not installed; buffer not formatted")))
      )
    )
  )

(ert-deftest dziman-swift-format/missing-swiftformat-names-it-in-a-note ()
  (dziman-swift-test-with-project '(".swiftformat")
    (with-temp-buffer
      (setq default-directory root)
      (cl-letf (((symbol-function 'dziman/swift-tool-available-p) #'ignore))
        (should (equal (dziman-swift-test-capturing-messages (dziman/swift-format-buffer))
                  '("SwiftFormat is not installed; buffer not formatted")))
        )
      )
    )
  )

(ert-deftest dziman-swift-format/missing-formatter-on-save-shows-its-note-after-the-save ()
  (dziman-swift-test-with-project '()
    (with-temp-buffer
      (setq default-directory root)
      (let ((deferred nil))
        (cl-letf (((symbol-function 'dziman/swift-tool-available-p) #'ignore)
                   ((symbol-function 'run-at-time) (lambda (&rest args) (setq deferred args))))
          (should-not (dziman-swift-test-capturing-messages (dziman/swift--format-before-save)))
          )
        (should (equal deferred
                  '(0 nil message "%s" "Apple swift-format is not installed; buffer not formatted")))
        )
      )
    )
  )

(ert-deftest dziman-swift-format/apple-formatter-reformats-a-scratch-buffer ()
  (skip-unless (dziman/swift-tool-available-p 'swift-format))
  (dziman-swift-test-with-project '()
    (with-temp-buffer
      (setq default-directory root)
      (insert "let a=[1,2 ,3]\n")
      (dziman-swift-test-capturing-messages (dziman/swift-format-buffer))
      (should (equal (buffer-string) "let a = [1, 2, 3]\n"))
      )
    )
  )

(ert-deftest dziman-swift-format/failing-formatter-leaves-buffer-and-shows-its-output ()
  (skip-unless (dziman/swift-tool-available-p 'swift-format))
  (dziman-swift-test-with-project '()
    (with-temp-buffer
      (setq default-directory root)
      (insert "let a=[1,\n")
      (unwind-protect
        (progn
          (dziman-swift-test-capturing-messages (dziman/swift-format-buffer))
          (should (equal (buffer-string) "let a=[1,\n"))
          (should (get-buffer "*dziman/swift-apple-format errors*"))
          (should (> (buffer-size (get-buffer "*dziman/swift-apple-format errors*")) 0))
          )
        (kill-buffer "*dziman/swift-apple-format errors*")
        )
      )
    )
  )

(ert-deftest dziman-swift-format/swiftformat-reformats-in-its-project ()
  (skip-unless (dziman/swift-tool-available-p 'swiftformat))
  (dziman-swift-test-with-project '(".swiftformat")
    (with-temp-buffer
      (setq default-directory root)
      (insert "let a=[1,2 ,3]\n")
      (dziman-swift-test-capturing-messages (dziman/swift-format-buffer))
      (should (equal (buffer-string) "let a = [1, 2, 3]\n"))
      )
    )
  )

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

(ert-deftest dziman-swift-helpers/apple-docs-looks-up-the-selection ()
  (let ((opened nil))
    (with-temp-buffer
      (insert "let navigationStack = 1")
      (set-mark 5)
      (goto-char 20)
      (let ((transient-mark-mode t))
        (cl-letf (((symbol-function 'browse-url) (lambda (url &rest _) (setq opened url))))
          (call-interactively #'dziman/swift-apple-docs)
          )
        )
      )
    (should (equal opened "https://developer.apple.com/search/?q=navigationStack"))
    )
  )

(ert-deftest dziman-swift-helpers/apple-docs-asks-when-nothing-is-under-the-cursor ()
  (let ((opened nil))
    (with-temp-buffer
      (cl-letf (((symbol-function 'read-string) (lambda (&rest _) "List"))
                 ((symbol-function 'browse-url) (lambda (url &rest _) (setq opened url))))
        (call-interactively #'dziman/swift-apple-docs)
        )
      )
    (should (equal opened "https://developer.apple.com/search/?q=List"))
    )
  )

(ert-deftest dziman-swift-helpers/apple-docs-refuses-an-empty-lookup ()
  (let ((opened nil))
    (with-temp-buffer
      (cl-letf (((symbol-function 'read-string) (lambda (&rest _) ""))
                 ((symbol-function 'browse-url) (lambda (url &rest _) (setq opened url))))
        (should-error (call-interactively #'dziman/swift-apple-docs) :type 'user-error)
        )
      )
    (should-not opened)
    )
  )

(ert-deftest dziman-swift-helpers/apple-docs-refuses-a-blank-lookup ()
  (let ((opened nil))
    (with-temp-buffer
      (cl-letf (((symbol-function 'read-string) (lambda (&rest _) "  "))
                 ((symbol-function 'browse-url) (lambda (url &rest _) (setq opened url))))
        (should-error (call-interactively #'dziman/swift-apple-docs) :type 'user-error)
        )
      )
    (should-not opened)
    )
  )

(ert-deftest dziman-swift-helpers/open-in-xcode-needs-xcode-installed ()
  (with-temp-buffer
    (setq buffer-file-name "/p/X.swift")
    (unwind-protect
      (cl-letf (((symbol-function 'dziman/swift-tool-available-p) (lambda (_tool) nil)))
        (should-error (dziman/swift-open-in-xcode) :type 'user-error)
        )
      (setq buffer-file-name nil)
      )
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
      (unwind-protect
        (cl-letf (((symbol-function 'dziman/swift-tool-available-p) (lambda (_tool) "/usr/bin/xed"))
                   ((symbol-function 'call-process) (lambda (&rest call) (setq args call) 0)))
          (dziman/swift-open-in-xcode)
          )
        (setq buffer-file-name nil)
        )
      )
    (should (equal args '("/usr/bin/xed" nil 0 nil "--line" "3" "/p/X.swift")))
    )
  )

(ert-deftest dziman-swift-helpers/open-in-xcode-saves-unsaved-changes-first ()
  (let ((saved nil))
    (with-temp-buffer
      (setq buffer-file-name "/p/X.swift")
      (insert "a\n")
      (unwind-protect
        (cl-letf (((symbol-function 'dziman/swift-tool-available-p) (lambda (_tool) "/usr/bin/xed"))
                   ((symbol-function 'save-buffer) (lambda (&rest _) (setq saved t) (set-buffer-modified-p nil)))
                   ((symbol-function 'call-process) (lambda (&rest _) 0)))
          (dziman/swift-open-in-xcode)
          )
        (setq buffer-file-name nil)
        )
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
    ;; Stands in for a live server connection: the minor mode whose keymap is `eglot-mode-map'
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

;;;;;;;; Going to a type
(ert-deftest dziman-swift-type/package-tests-folder-is-test-code ()
  (should (dziman/swift-test-file-p "Tests/AppTests/Fixtures.swift"))
  )

(ert-deftest dziman-swift-type/xcode-tests-target-is-test-code ()
  (should (dziman/swift-test-file-p "MyAppTests/Helpers.swift"))
  )

(ert-deftest dziman-swift-type/xcode-ui-tests-target-is-test-code ()
  (should (dziman/swift-test-file-p "MyAppUITests/Screens/LoginScreen.swift"))
  )

(ert-deftest dziman-swift-type/tests-file-name-is-test-code ()
  (should (dziman/swift-test-file-p "Sources/App/LoginTests.swift"))
  )

(ert-deftest dziman-swift-type/app-source-is-not-test-code ()
  (should-not (dziman/swift-test-file-p "Sources/App/Login.swift"))
  )

(ert-deftest dziman-swift-type/folder-only-starting-with-tests-is-app-code ()
  (should-not (dziman/swift-test-file-p "Sources/TestsSupport/Fixture.swift"))
  )

(defun dziman-swift-test-symbol (kind file)
  "LSP SymbolInformation of KIND, a symbol kind number, declared in FILE."
  (list :name "Login" :kind kind
    :location (list :uri (concat "file://" file)
                :range '(:start (:line 0 :character 0) :end (:line 0 :character 5))))
  )

(defmacro dziman-swift-test-type-kind (name kind)
  "Define a test that symbols of KIND in app code count as types."
  `(ert-deftest ,(intern (format "dziman-swift-type/%s-is-a-type" name)) ()
     (should (dziman/swift-type-symbol-p "/work/MyApp/" (dziman-swift-test-symbol ,kind "/work/MyApp/Sources/Login.swift")))
     )
  )

(dziman-swift-test-type-kind class 5)
(dziman-swift-test-type-kind enum 10)
(dziman-swift-test-type-kind protocol 11)
(dziman-swift-test-type-kind struct 23)

(ert-deftest dziman-swift-type/method-is-not-a-type ()
  (should-not (dziman/swift-type-symbol-p "/work/MyApp/" (dziman-swift-test-symbol 6 "/work/MyApp/Sources/Login.swift")))
  )

(ert-deftest dziman-swift-type/type-in-test-code-is-left-out ()
  (should-not (dziman/swift-type-symbol-p "/work/MyApp/" (dziman-swift-test-symbol 5 "/work/MyApp/Tests/AppTests/Fake.swift")))
  )

(ert-deftest dziman-swift-type/tests-folder-above-the-project-does-not-count ()
  (should (dziman/swift-type-symbol-p "/work/UITests/MyApp/"
            (dziman-swift-test-symbol 5 "/work/UITests/MyApp/Sources/Login.swift")))
  )

(ert-deftest dziman-swift-type/needs-a-language-server ()
  (require 'swift-mode)
  (with-temp-buffer
    (let ((swift-mode-hook nil)) (swift-mode))
    (should-error (dziman/swift-find-type) :type 'user-error)
    )
  )

(ert-deftest dziman-swift-type/swift-buffer-has-go-to-type-key ()
  (require 'swift-mode)
  (with-temp-buffer
    (let ((swift-mode-hook nil)) (swift-mode))
    (should (eq (key-binding (kbd "M-p t")) 'dziman/swift-find-type))
    )
  )

;;;;;;;; Reloading the platform
(defmacro dziman-swift-test-reloading (buffers &rest body)
  "Run BODY, then return the events recorded by stubbed eglot calls.
BUFFERS are (DIRECTORY . SERVER) specs of Swift buffers; the first is current.
Events are (shutdown SERVER) and (normal-mode DIRECTORY), in order."
  (declare (indent 1))
  `(let ((events nil) (live nil))
     (unwind-protect
       (progn
         (dolist (spec ,buffers)
           (let ((buffer (generate-new-buffer " dz-swift-reload")))
             (with-current-buffer buffer
               (setq major-mode 'swift-mode
                 default-directory (car spec))
               )
             (push buffer live)
             )
           )
         (cl-letf (((symbol-function 'eglot-current-server) (lambda () (cdr (car ,buffers))))
                    ((symbol-function 'eglot-shutdown)
                      (lambda (server) (push (list 'shutdown server) events)))
                    ((symbol-function 'normal-mode)
                      (lambda (&rest _) (push (list 'normal-mode default-directory) events))))
           (with-current-buffer (car (last live))
             ,@body
             )
           )
         (nreverse events)
         )
       (mapc #'kill-buffer live)
       )
     )
  )

(ert-deftest dziman-swift-reload/server-stops-before-locals-are-re-read ()
  (dziman-swift-test-with-project '("Package.swift")
    (let ((events (dziman-swift-test-reloading (list (cons root 'server))
                    (dziman/swift-reload-platform))))
      (should (equal (mapcar #'car events) '(shutdown normal-mode)))
      )
    )
  )

(ert-deftest dziman-swift-reload/locals-are-re-read-in-every-buffer-of-the-package ()
  (dziman-swift-test-with-project '("Package.swift" "Sources/A/a.swift")
    (let* ((sources (expand-file-name "Sources/A/" root))
            (events (dziman-swift-test-reloading (list (cons root nil) (cons sources nil))
                      (dziman/swift-reload-platform))))
      (should (equal (sort (mapcar #'cadr (cl-remove 'shutdown events :key #'car)) #'string<)
                (sort (list root sources) #'string<)))
      )
    )
  )

(ert-deftest dziman-swift-reload/buffers-of-other-packages-are-left-alone ()
  (dziman-swift-test-with-project '("Package.swift" "Other/Package.swift")
    (let* ((other (expand-file-name "Other/" root))
            (events (dziman-swift-test-reloading (list (cons root nil) (cons other nil))
                      (dziman/swift-reload-platform))))
      (should (equal (mapcar #'cadr events) (list root)))
      )
    )
  )

(ert-deftest dziman-swift-reload/no-running-server-still-re-reads-locals ()
  (dziman-swift-test-with-project '("Package.swift")
    (let ((events (dziman-swift-test-reloading (list (cons root nil))
                    (dziman/swift-reload-platform))))
      (should (equal events (list (list 'normal-mode root))))
      )
    )
  )

;;;;;;;; Menu
(ert-deftest dziman-swift-menu/swift-mode-menu-offers-the-swift-commands ()
  (let ((commands (mapcar #'cadr (symbol-value 'major-mode-hydras/swift-mode/heads))))
    (dolist (command '(eglot-rename eglot-code-actions consult-eglot-symbols
                        dziman/swift-format-buffer dziman/swift-open-in-xcode
                        dziman/swift-apple-docs dziman/swift-reload-platform consult-flycheck
                        dziman/swift-find-type))
      (should (memq command commands))
      )
    )
  )

(provide 'dz-config-swift-test)
