;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Development related small-ish packages and related configs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package hl-todo :ensure t)
(use-package rainbow-delimiters :ensure t)
(use-package rainbow-mode :ensure t)
(use-package smartparens :ensure t)
(use-package hungry-delete :ensure t)
(use-package highlight-parentheses :ensure t)
(use-package whitespace-cleanup-mode :ensure t) ;; TODO Revisit: see no effect
;; (use-package highlight-indentation :ensure t) ;; TODO Revisit: looks broken

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

;; highlight indentation level
;; (add-hook 'prog-mode-hook 'highlight-indentation-mode)
;; (set-face-background 'highlight-indentation-face "#7f7f7f")
;; (set-face-background 'highlight-indentation-current-column-face "#c3b3b3")

(provide 'dz-config-prog-mode)
