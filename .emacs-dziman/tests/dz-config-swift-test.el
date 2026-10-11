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
