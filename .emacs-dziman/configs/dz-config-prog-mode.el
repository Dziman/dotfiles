;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Development related small-ish packages and related configs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package hl-todo :ensure t)
(use-package rainbow-delimiters :ensure t)
(use-package rainbow-mode :ensure t)
(use-package smartparens :ensure t)
(use-package hungry-delete :ensure t)
(use-package highlight-parentheses :ensure t)

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

;; Autoclose parentheses
(smartparens-global-mode 1)

(add-hook 'prog-mode-hook 'hungry-delete-mode)
(setq hungry-delete-join-reluctantly t)

(add-hook 'prog-mode-hook 'highlight-parentheses-mode)

(add-hook 'before-save-hook 'dz-remove-trailing-whitespace)

(defun dz-remove-trailing-whitespace()
  (when (derived-mode-p 'prog-mode)
    (delete-trailing-whitespace)))

(provide 'dz-config-prog-mode)
