;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Completion-related packages and their configs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package company :ensure t)

(add-hook 'after-init-hook 'global-company-mode)
(setq company-tooltip-align-annotations t)

(eval-after-load 'company
  '(progn
     (define-key company-mode-map (kbd "C-c c") 'helm-company)
       (define-key company-active-map (kbd "C-c c") 'helm-company)))

(provide 'dz-config-completion)
