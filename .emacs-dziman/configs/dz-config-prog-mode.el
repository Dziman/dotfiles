;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Development related small-ish packages and related configs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package hl-todo)
(use-package rainbow-delimiters)
(use-package rainbow-mode)
(use-package smartparens)
(use-package hungry-delete)
(use-package highlight-parentheses)
;; Language server integration
(use-package dap-mode)
(use-package lsp-mode)
(use-package lsp-ui)
(use-package helm-lsp)

;; formatting
(use-package apheleia)

(use-package yasnippet)
(use-package string-inflection)
(use-package flycheck-inline)

;; Highlight TODOs
(setq hl-todo-keyword-faces
  '(
     ("TODO" warning bold)
     ("FIXME" error bold)
     ("NOTE" success bold)
   )
)
(add-hook 'prog-mode-hook 'hl-todo-mode)

;; rainbow parentheses
(add-hook 'prog-mode-hook 'rainbow-delimiters-mode)

(add-hook 'prog-mode-hook 'rainbow-mode)
(add-hook 'prog-mode-hook 'yas-minor-mode)

;; Autoclose parentheses
(smartparens-global-mode 1)

(add-hook 'prog-mode-hook 'hungry-delete-mode)
(setq hungry-delete-join-reluctantly t)

(add-hook 'prog-mode-hook 'highlight-parentheses-mode)

(add-hook 'before-save-hook 'dziman/remove-trailing-whitespace)

(defun dziman/remove-trailing-whitespace()
  (when (derived-mode-p 'prog-mode)
    (delete-trailing-whitespace)))

;; Autoconfigure debug capabilities
(dap-auto-configure-mode)

;;;;;; In terminal emacs doesn't show `fringe` where `dap-ui` is rendering 'icons' for debug (like brakepoint symbol)
;;;;;; As (temp) workaround, customizing faces instead. This solution still has issues: highlighting expands if current bookmark line edited and new line added from it.
;;;;;; TODO Revisit for better UI/UX solution
;; Current execution point
(set-face-attribute 'dap-ui-marker-face nil :inherit nil :background "darkolivegreen" :foreground "white")

;; Breakpoints
(set-face-attribute 'dap-ui-pending-breakpoint-face nil :inherit nil :background "salmon3" :foreground "white")
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar dziman/hydra/debug--title (dziman/with-faicon "bug" "Debug" 1 -0.05))

(pretty-hydra-define dziman/hydra/debug
  (:color pink :quit-key "q" :title dziman/hydra/debug--title)
  (
    " Stepping"
    (
      ("n" dap-next " step over")
      ("i" dap-step-in "󰆹 step in")
      ("o" dap-step-out "󰆸 step out")
      ("c" dap-continue " continue")
      ("r" dap-restart-frame " restart frame")
      ("D" dap-disconnect " disconnect")
      )

    " Breakpoints"
    (
      ("b b" dap-breakpoint-toggle " toggle")
      ("b a" dap-breakpoint-add " add")
      ("b d" dap-breakpoint-delete " delete")
      ("b c" dap-breakpoint-condition " condition")
      ("b h" dap-breakpoint-hit-condition " hit count")
      ("b l" dap-breakpoint-log-message "log")
      )

    " Debug"
    (
      ("d d" dap-debug " start")
      ("d r" dap-debug-recent " recent")
      ("d l" dap-debug-last " last")
      ("d R" dap-debug-restart " restart")
      )

    "Eval"
    (
      ("e e" dap-eval "eval")
      ("e r" dap-eval-region "region")
      ("e s" dap-eval-thing-at-point "at point")
      ("e a" dap-ui-expressions-add "add expression")
      )

    "Switch"
    (
      ("s s" dap-switch-session "session")
      ("s t" dap-switch-thread "thread")
      ("s f" dap-switch-stack-frame "stack frame")
      ("s u" dap-up-stack-frame "up stack frame")
      ("s d" dap-down-stack-frame "down stack frame")
      ("s l" dap-ui-loclals "list locals")
      ("s b" dap-ui-breakpoints " list breakpints")
      ("s S" dap-ui-sessions "list sessions")
      )

    )
  )

;; TODO Make it specific to `prog-mode` only
(bind-key "d" 'dziman/hydra/debug/body dziman/bind-map/hydra)

;; TODO Create `prog-mode` bind-map?
;; TODO Revisit if need external package
;; (bind-key "C-c f" 'apheleia-format-buffer)
;; (bind-key "C-c f" 'eglot-format)
(bind-key "C-c f" 'lsp-format-buffer)

;; TODO Try to fix icons in terminal. For now disable it at all
(setq lsp-headerline-breadcrumb-icons-enable nil)

;; TODO Is Java style is good for global?
(bind-key "M-U" 'string-inflection-java-style-cycle)

;; TODO It might duplicate `lsp-mode` messages
;; FIXME Disable as `flyover` is doing the same and even better(?)
;;(add-hook 'flycheck-mode-hook 'flycheck-inline-mode)

(require 'flyover)
(add-hook 'flycheck-mode-hook #'flyover-mode)
(setq flyover-checkers '(flycheck flymake))
(setq flyover-levels '(error warning info))
(setq flyover-show-at-eol t)
(setq flyover-show-virtual-line t)
(setq flyover-virtual-line-icon "  ")

(use-package periphery-search
  :ensure nil
  :bind (:map prog-mode-map
          ("C-c C-s" . #'periphery-search-rg)
          ("C-c C-f" . #'periphery-search-dwiw-rg) ;; TODO Fix: does not work
          ("C-x C-t" . #'periphery-query-todos-and-fixmes) ;; TODO Fix: does not work
          ("C-x C-m" . #'periphery-query-marks) ;; TODO Fix: does not work
          ("M-?" . #'periphery-toggle-buffer)
          )
  )

(provide 'dz-config-prog-mode)
