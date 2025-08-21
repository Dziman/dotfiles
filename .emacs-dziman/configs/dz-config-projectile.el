;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Projectile packages and their configs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package projectile :ensure t)
(use-package helm-projectile :ensure t)
(use-package ibuffer-projectile :ensure t)
;; TODO Move to common?
(use-package ag :ensure t)
(require 'dz-config-helm-ag)

(projectile-mode)
(setq projectile-completion-system 'helm)
(helm-projectile-on)
(define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map)

(provide 'dz-config-projectile)
