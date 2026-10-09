;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Development related small-ish packages and related configs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define-minor-mode dziman-prog-mode
  "Dziman prog minor mode for customizing key bindings etc"
  :init-value nil
  :lighter " DzProgMode")

(add-hook 'prog-mode-hook 'dziman-prog-mode)

(defun dziman/remove-trailing-whitespace()
  (when (derived-mode-p 'prog-mode)
    (delete-trailing-whitespace)))

(add-hook 'before-save-hook 'dziman/remove-trailing-whitespace)

;;;;;;;;
(use-package string-inflection :defer t)
(bind-map dziman/bind-map/prog
  :keys ("M-p")
  :minor-modes (dziman-prog-mode)
  :bindings (
              "U" 'string-inflection-java-style-cycle
              )
  )

;;;;;;;;
(use-package hl-todo :defer t)
(setq hl-todo-keyword-faces
  '(
     ("TODO" warning bold)
     ("FIXME" error bold)
     ("NOTE" success bold)
   )
)
(add-hook 'prog-mode-hook 'hl-todo-mode)

;;;;;;;;
(use-package rainbow-delimiters :defer t)
(add-hook 'prog-mode-hook 'rainbow-delimiters-mode)

;;;;;;;;
(use-package rainbow-mode :defer t)
(add-hook 'prog-mode-hook 'rainbow-mode)

;;;;;;;; TODO Review: do not use it explicitly, but some other packages can provide some functionality because it enabled
(use-package yasnippet :defer t)
(add-hook 'prog-mode-hook 'yas-minor-mode)

;;;;;;;;
;; smartparens advises `hippie-expand'; loading hippie-exp after that advice prints an
;; "ad-handle-definition: got redefined" message, so load it first
(require 'hippie-exp)
(use-package smartparens :defer t)
;; Autoclose parentheses
(add-hook 'dziman/first-buffer-hook #'smartparens-global-mode)

;;;;;;;;
(use-package hungry-delete :defer t)
(add-hook 'prog-mode-hook 'hungry-delete-mode)
(setq hungry-delete-join-reluctantly t)

;;;;;;;;
(use-package highlight-parentheses :defer t)
(add-hook 'prog-mode-hook 'highlight-parentheses-mode)

;;;;;;;;
(use-package flycheck-inline :defer t)
(add-hook 'flycheck-mode-hook 'flycheck-inline-mode)

(provide 'dz-config-prog-mode)
