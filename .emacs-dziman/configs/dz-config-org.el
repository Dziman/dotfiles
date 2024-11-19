;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; org packages and their configs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package org-super-agenda :ensure t)
(use-package org-roam :ensure t)
(use-package org-ql :ensure t) ;; TODO Learn https://github.com/alphapapa/org-ql
(use-package org-roam-ql-ql :ensure t)
(use-package org-rainbow-tags :ensure t)
(use-package org-sticky-header :ensure t)
(use-package org-super-agenda :ensure t)

(add-hook 'org-mode-hook (lambda () (setq-local truncate-lines nil)))

(defun dz-refresh-agenda-files ()
  (interactive)
  ;; FIXME Remove path hardcoding
  ;; TODO Automatically reload on new file created/deleted
  ;; TODO Exclude temp files
  ;; Original source: https://stackoverflow.com/questions/11384516/how-to-make-all-org-files-under-a-folder-added-in-agenda-list-automatically
  ;; Could cause performance issues for agenda view. Check https://github.com/nicolas-graves/org-agenda-files-track as potential solution
  (setq org-agenda-files (directory-files-recursively "~/wiki" "\\.org$"))
  )

(dz-refresh-agenda-files)
(bind-key "C-c a r" 'dz-refresh-agenda-files)

(add-hook 'org-mode-hook 'org-sticky-header-mode)
(setq org-sticky-header-full-path 'full)

;; TODO Customize https://github.com/alphapapa/org-super-agenda
(add-hook 'org-mode-hook 'org-super-agenda-mode)
(setq org-super-agenda-groups
      '((:name "Next Items"
               :time-grid t
               :tag ("NEXT" "outbox"))
        (:name "Important"
               :priority "A")
        (:name "Quick Picks"
               :effort< "0:30")
        (:priority<= "B"
                     :scheduled future
                     :order 1)))

;; TODO Add avy bindings? https://github.com/abo-abo/avy

(setq org-roam-directory "~/wiki")
(setq org-roam-db-location
      (concat org-roam-directory "/.org-roam/org-roam-sqlite-database.db"))
(org-roam-db-autosync-mode)

(provide 'dz-config-org)
