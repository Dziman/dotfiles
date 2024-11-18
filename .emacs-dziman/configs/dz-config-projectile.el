;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Projectile packages and their configs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package projectile :ensure t)
(use-package helm-projectile :ensure t) ;; TODO Learn/config https://github.com/bbatsov/helm-projectile
(use-package ibuffer-projectile :ensure t) ;; TODO Learn/config https://github.com/purcell/ibuffer-projectile
(use-package org-projectile :ensure t) ;; TODO Learn/config https://github.com/colonelpanic8/org-project-capture
(use-package org-projectile-helm :ensure t) ;; TODO Learn/config https://github.com/colonelpanic8/org-project-capture

(projectile-mode)
(setq projectile-completion-system 'helm)
(helm-projectile-on)
(define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map)

(provide 'dz-config-projectile)
