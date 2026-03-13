;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; iOS (and swift in general)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package swift-mode
  :mode "\\.swift\\'"
  :config
  (add-to-list 'auto-mode-alist '("\\.swift\\'" . swift-mode))
  )

;;(define-derived-mode swift-test-mode swift-mode "Swift[Test]")
;;(define-derived-mode swift-ui-test-mode swift-mode "Swift[UI Test]")

(require 'eglot)
(require 'swift-lsp)
(add-to-list 'eglot-server-programs '(swift-mode . my-swift-mode:eglot-server-contact))
;; For tests we need to use `macOS` default platform to enable `Testing` framework
;;(add-to-list 'eglot-server-programs '(swift-test-mode . ("xcrun" "sourcekit-lsp")))
;;(add-hook 'swift-mode-hook 'eglot-ensure)

;;;; Debugging
(require 'dap-lldb)
;; TODO Do not hardcode?
(setq dap-lldb-debug-program '("/opt/homebrew/opt/llvm/bin/lldb-dap"))

(use-package periphery-swiftformat
  :ensure nil
  :after swift-mode
  :bind
  (:map swift-mode-map
    ("C-c C-o" . #'periphery-swiftformat-lint-buffer) ;; TODO format linting does not working for some reason
    ("M-o" . #'periphery-swiftformat-autocorrect-buffer)
    ("C-c C-p" . #'periphery-run-swiftformat-for-project)
    )
  )

(use-package periphery-swiftlint
  :ensure nil
  :after swift-mode
  :bind
  ("C-c C-l" . #'periphery-run-swiftlint)
  )

(use-package swift-additions
  :ensure nil
  :after swift-mode
  :bind
  (:map swift-mode-map
    ("M-r" . #'swift-additions:run)
    ("C-c t m" . #'swift-additions:test-module-silent)
    ("C-c t p" . #'swift-additions:test-swift-package-from-file)
    ("C-c C-c" . #'swift-additions:compile-and-run)
    ("C-c C-b" . #'swift-additions:compile-app)
    ("C-c C-x" . #'swift-additions:reset)
    ("C-c C-f" . #'periphery-search-dwiw-rg)
    )
  )

(use-package xcode-additions
  :ensure nil
  :after swift-mode
  :bind
  (:map swift-mode-map
    ("M-K" .  #'xcode-additions:clean-build-folder)
;;    ("C-c C-d" . #'xcode-additions:start-debugging)
    ("C-c C-x" . #'swift-additions:reset)
    )
  )

;; TODO Review some functionality doesn't work
(use-package swift-refactor
  :ensure nil
  :after (swift-mode)
  :bind
  (:map swift-mode-map
    ("M-t" . #'swift-refactor:insert-todo)
    ("M-m" . #'swift-refactor:insert-mark)
    ("C-c x t" . #'xcode-additions:toggle-device-choice)
    ("C-c x c" . #'xcode-additions:show-current-configuration)
    ("C-c r a" . #'swift-refactor:wrap-selection)
    ("C-c r d" . #'swift-refactor:delete-current-line-with-matching-brace)
    ("C-c r i" . #'swift-refactor:tidy-up-constructor)
    ("C-c r r" . #'swift-refactor:extract-function)
    ("M-P" .  #'swift-refactor:print-thing-at-point)
    ("C-c r t" . #'swift-refactor:add-try-catch)
    )
  )

;; TODO Remove? It looks like publicly accessible JSON endpoint was removed and this functionality doesn't work anymore. Keep it for now
;;(use-package request) ;; Required for `apple-docs-query`
;;(use-package apple-docs-query
;;  :ensure nil
;;  :bind
;;  ("C-c C-a" . #'apple-docs/query)
;;  ("C-c C-A" . #'apple-docs/query-thing-at-point))

(defun dziman/get-lsp-target-platform (sdk-platform)
  (cond
    (
      (string= "iphoneos" sdk-platform)
      "ios"
      )
    (
      t ;; defaulting to macos
      "macos"
      )
    )
  )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; To achieve completion for iOS development have to create LSP client manually instead of using `lsp-sourcekit` package.
;;;;;; Just using `xcrun --sdk` is not enough: we need to pass `swiftc` `sdk` and `target` as well, otherwise some features (like code completion) will not work properly
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun dziman/swift-lsp-target (sdk-platform)
  "Get the current simulator sdk."
  (let* (
          (target-components (split-string (string-trim (shell-command-to-string "clang -print-target-triple")) "-"))
          (arch (nth 0 target-components))
          (vendor (nth 1 target-components))
          (target-platform (dziman/get-lsp-target-platform sdk-platform))
          (version (string-trim (shell-command-to-string (format "xcrun --sdk %s --show-sdk-version" sdk-platform))))
          )
    (format "%s-%s-%s%s" arch vendor target-platform  version)))

(defun dziman/sourcekit-lsp-command-line (sdk-platform)
  (let* (
         (dziman/sourcekit-lsp-sdk-platform sdk-platform)
         (dziman/sourcekit-lsp-sdk-target (dziman/swift-lsp-target dziman/sourcekit-lsp-sdk-platform))
         (dziman/sourcekit-lsp-sdk-path (car (process-lines "xcrun" "--sdk" dziman/sourcekit-lsp-sdk-platform "--show-sdk-path")))
          )
    (list
       "xcrun" "--sdk" dziman/sourcekit-lsp-sdk-platform
         "sourcekit-lsp"
           "-Xswiftc" "-sdk" "-Xswiftc" dziman/sourcekit-lsp-sdk-path
           "-Xswiftc" "-target" "-Xswiftc" dziman/sourcekit-lsp-sdk-target
       )
     )
  )

(defun dziman/register-swift-lsp-client (sdk-platform)
  (lsp-register-client
    (make-lsp-client
      :new-connection
      (lsp-stdio-connection (dziman/sourcekit-lsp-command-line sdk-platform))
      :major-modes '(swift-mode swift-ts-mode)
      :server-id (intern (s-concat "dziman/sourcekit-lsp-" sdk-platform))
      )
    )
  )

(add-hook 'swift-mode-hook 'lsp)

(provide 'dz-config-swift)
