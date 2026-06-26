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
(use-package string-inflection)
(bind-map dziman/bind-map/prog
  :keys ("M-p")
  :minor-modes (dziman-prog-mode)
  :bindings (
              "U" 'string-inflection-java-style-cycle
              )
  )

;;;;;;;;
(use-package hl-todo)
(setq hl-todo-keyword-faces
  '(
     ("TODO" warning bold)
     ("FIXME" error bold)
     ("NOTE" success bold)
   )
)
(add-hook 'prog-mode-hook 'hl-todo-mode)

;;;;;;;;
(use-package rainbow-delimiters)
(add-hook 'prog-mode-hook 'rainbow-delimiters-mode)

;;;;;;;;
(use-package rainbow-mode)
(add-hook 'prog-mode-hook 'rainbow-mode)

;;;;;;;; TODO Review: do not use it explicitly, but some other packages can provide some functionality because it enabled
(use-package yasnippet)
(add-hook 'prog-mode-hook 'yas-minor-mode)

;;;;;;;;
(use-package smartparens)
;; Autoclose parentheses
(smartparens-global-mode 1)

;;;;;;;;
(use-package hungry-delete)
(add-hook 'prog-mode-hook 'hungry-delete-mode)
(setq hungry-delete-join-reluctantly t)

;;;;;;;;
(use-package highlight-parentheses)
(add-hook 'prog-mode-hook 'highlight-parentheses-mode)

;;;;;;;;
(use-package flycheck-inline)
(add-hook 'flycheck-mode-hook 'flycheck-inline-mode)

(provide 'dz-config-prog-mode)
