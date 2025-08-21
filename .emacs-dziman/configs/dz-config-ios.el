;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; iOS (and swift general)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package swift-mode :ensure t)
(use-package lsp-sourcekit
  :ensure t
  :after lsp-mode
  ;; Setting up in beta version of macOS and `executable-find` leads to some conflict and `lsp` doesn't work properly. So hardcoding path for now
;  :custom (lsp-sourcekit-executable "/Library/Developer/CommandLineTools/usr/bin/sourcekit-lsp" "Find sourcekit-lsp")
; :custom (lsp-sourcekit-executable "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp" "Find sourcekit-lsp")
 :custom (lsp-sourcekit-executable (executable-find "sourcekit-lsp") "Find sourcekit-lsp")
  )
(require 'dap-lldb)
;; TODO Do not hardcode?
(setq dap-lldb-debug-program '("/opt/homebrew/opt/llvm/bin/lldb-dap"))

(add-hook 'swift-mode-hook 'lsp)

(provide 'dz-config-ios)
