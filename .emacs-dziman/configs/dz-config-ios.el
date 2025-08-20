;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; iOS development
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package swift-mode
  :ensure t
  :mode "\\.swift\\'"
  :interpreter "swift")

;;; Locate sourcekit-lsp
(defun find-sourcekit-lsp ()
  (or (executable-find "sourcekit-lsp")
    (and (eq system-type 'darwin)
      (string-trim (shell-command-to-string "xcrun -f sourcekit-lsp"))
      )
    "/usr/local/swift/usr/bin/sourcekit-lsp"
    )
  )

(use-package lsp-sourcekit
    :ensure t
    :after lsp-mode
    :custom
  (lsp-sourcekit-executable (find-sourcekit-lsp) "Find sourcekit-lsp")
  )

(require 'dap-lldb)
;; TODO Do not hardcode?
(setq dap-lldb-debug-program '("/opt/homebrew/opt/llvm/bin/lldb-dap"))

(add-hook 'swift-mode-hook 'lsp)

(provide 'dz-config-ios)
