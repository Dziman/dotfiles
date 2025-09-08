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

(provide 'dz-config-ios)
