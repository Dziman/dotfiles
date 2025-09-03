;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; iOS (and swift general)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package swift-mode :ensure t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; To achieve completion for iOS development have to create LSP client manually instead of using `lsp-sourcekit` package.
;;;;;; Just using `xcrun --sdk` is not enough: we need to pass `swiftc` `sdka` and `target` as well, otherwise some features (like code completion) will not work properly
;;;;;; TODO Do not hardcode target and add possibility to switch target platform without need to edit emacs config and restart emacs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun dziman/sourcekit-lsp-command-line()
  (let* (
         (dziman/sourcekit-lsp-sdk-platform "iphoneos")
         (dziman/sourcekit-lsp-sdk-target "arm64-apple-ios18.6")
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

(require 'lsp)

(lsp-register-client
  (make-lsp-client
    :new-connection
    (lsp-stdio-connection (dziman/sourcekit-lsp-command-line))
    :major-modes '(swift-mode swift-ts-mode)
    :server-id 'dziman/sourcekit-ls)
  )
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(require 'dap-lldb)
;; TODO Do not hardcode?
(setq dap-lldb-debug-program '("/opt/homebrew/opt/llvm/bin/lldb-dap"))

(add-hook 'swift-mode-hook 'lsp)

;; eglot configs TODO revisit
;;(add-hook 'swift-mode-hook 'eglot-ensure)
(message "warning: `jsonrpc--log-event' is ignored.")
(fset #'jsonrpc--log-event #'ignore)
(require 'eglot)
;; TODO Do not hardcode everything. My ELisp kung-fu was not able to find a way to extract some items to variables
(add-to-list 'eglot-server-programs '(swift-mode . ("xcrun" "--sdk" "iphoneos" "sourcekit-lsp" "-Xswiftc" "-sdk" "-Xswiftc" "/Applications/Xcode-beta.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.0.sdk" "-Xswiftc" "-target" "-Xswiftc" "arm64-apple-ios18.6")))
;;(add-to-list 'eglot-server-programs '(swift-mode . ("xcrun" "sourcekit-lsp")))

(require 'apheleia)
(add-to-list 'apheleia-mode-alist '(swift-mode . swift-format))
(add-to-list 'apheleia-formatters '(swift-format "swift-format" (buffer-file-name)))

(require 'flycheck)
(add-to-list 'flycheck-checkers 'swiftlint)

(provide 'dz-config-ios)
