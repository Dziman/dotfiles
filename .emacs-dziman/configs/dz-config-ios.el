;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; iOS (and swift general)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package swift-mode :ensure t)
(use-package lsp-sourcekit
  :ensure t
  :after lsp-mode
  :custom (lsp-sourcekit-executable (executable-find "sourcekit-lsp") "Find sourcekit-lsp")
  )

(require 'dap-lldb)
;; TODO Do not hardcode?
(setq dap-lldb-debug-program '("/opt/homebrew/opt/llvm/bin/lldb-dap"))

(add-hook 'swift-mode-hook 'lsp)

(require 'apheleia)
(add-to-list 'apheleia-mode-alist '(swift-mode . swift-format))
(add-to-list 'apheleia-formatters '(swift-format "swift-format" (buffer-file-name)))

(require 'flycheck)
(add-to-list 'flycheck-checkers 'swiftlint)

(provide 'dz-config-ios)
