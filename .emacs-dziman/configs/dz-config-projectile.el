;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Projectile packages and their configs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package projectile)
(use-package helm-projectile)
(use-package ibuffer-projectile)
(use-package treemacs-projectile)
(use-package org-projectile)
(use-package org-projectile-helm)

(projectile-mode)
(setq projectile-completion-system 'helm)
(helm-projectile-on)
(define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map)

(setq org-project-capture-default-backend (make-instance 'org-project-capture-projectile-backend))
;; TODO? Do not hardcode path
(setq org-project-capture-projects-file "~/wiki/dziman/projects/all/TODO.org")
;; TODO? Do not hardcode path
(setq org-project-capture-projects-directory "~/wiki/dziman/projects/")
;; Settign value to not existing file so single file strategy will work by default. To have per project capture file,
;; it should be created (by `touch` for example) and `org-project-capture-per-project-filepath` updated in project's `.dir-locals.el`
(setq org-project-capture-per-project-filepath "unknown/TODO.org")
;; TODO? Customize template `org-project-capture-capture-template` to attach project tag automagically

;; Use project-specific file if it exists, otherwise all projects in one file
(setq org-project-capture-strategy
  (make-instance 'org-project-capture-combine-strategies
    :strategies (list
                  (make-instance 'org-project-capture-single-file-strategy)
                  (make-instance 'org-project-capture-per-project-strategy)
                  )
    )
  )

(bind-key "C-c c p t" 'org-project-capture-project-todo-completing-read projectile-mode-map)

(provide 'dz-config-projectile)
