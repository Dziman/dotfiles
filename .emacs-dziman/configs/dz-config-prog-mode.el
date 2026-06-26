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
(use-package yasnippet)
(use-package string-inflection)

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

;; TODO Is Java style is good for global?
(bind-key "M-U" 'string-inflection-java-style-cycle)

(provide 'dz-config-prog-mode)
