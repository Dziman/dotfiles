;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Development related small-ish packages and related configs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package hl-todo :ensure t)
(use-package rainbow-delimiters :ensure t)
(use-package rainbow-mode :ensure t)
(use-package smartparens :ensure t)
(use-package hungry-delete :ensure t)
(use-package highlight-parentheses :ensure t)
(use-package lsp-mode :ensure t)
(use-package lsp-ui :ensure t)
(use-package dap-mode :ensure t)

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

(provide 'dz-config-prog-mode)
