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

(provide 'dz-config-ios)
