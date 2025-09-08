;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Setting up `eglot` (Language Server Protocol client)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package eglot
  :defer t
  :ensure nil
  :bind
  ("C-c g f" . #'eglot-code-action-quickfix)
  ("C-c g a" . #'eglot-code-actions)
  ("C-c g e" . #'eglot-code-action-extract)
  ("C-c g R" . #'eglot-code-action-rewrite)
  ("C-c g r" . #'eglot-rename)
  ("C-c g m" . #'eglot-menu)
  ("C-c g d" . #'eglot-find-declaration)
  ("C-c g D" . #'eglot-find-typeDefinition)
  ("C-c g i" . #'eglot-find-implementation)
  ("C-c g b" . #'eglot-format-buffer)
  )

(use-package flycheck-eglot
  :ensure t
  :after (flycheck eglot)
  :config
  (global-flycheck-eglot-mode t)
  )

(setq eglot-autoshutdown t)
(setq eglot-extend-to-xref t)
(setq eglot-sync-connect 1)
(setq eglot-connect-timeout 90)
(setq eglot-report-progress nil)
(setq eglot-events-buffer-size 0)
(setq eglot-events-buffer-config '(size: 0 :format full))
(setq eldoc-documentation-strategy 'eldoc-documentation-compose)

(setq eglot-stay-out-of '(corfu flycheck))
(setq jsonrpc-event-hook nil)

(advice-add 'jsonrpc--log-event :override #'ignore)

(provide 'dz-config-eglot)
