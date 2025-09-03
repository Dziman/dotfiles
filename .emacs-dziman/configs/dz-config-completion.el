;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Completion-related packages and their configs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package company :ensure t)
(use-package company-box :ensure t)

(add-hook 'after-init-hook 'global-company-mode)
(setq company-tooltip-align-annotations t)

(add-hook 'company-mode 'company-box-mode)

(provide 'dz-config-completion)
