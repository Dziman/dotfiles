;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; iOS (and swift in general)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package swift-mode
  :mode "\\.swift\\'"
  :config
  (add-to-list 'auto-mode-alist '("\\.swift\\'" . swift-mode)))

(require 'eglot)
(require 'swift-lsp)
(add-to-list 'eglot-server-programs '(swift-mode . my-swift-mode:eglot-server-contact))
(add-hook 'swift-mode-hook 'eglot-ensure)

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
    ("C-c C-d" . #'xcode-additions:start-debugging)
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

(provide 'dz-config-ios)
