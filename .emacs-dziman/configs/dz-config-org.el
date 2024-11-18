;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; org packages and their configs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package org-super-agenda :ensure t)
(use-package org-multi-wiki :ensure t) ;; TODO Learn https://github.com/akirak/org-multi-wiki
(use-package org-ql :ensure t) ;; TODO Learn https://github.com/alphapapa/org-ql
(use-package org-rainbow-tags :ensure t)
(use-package org-sticky-header :ensure t)
(use-package org-super-agenda :ensure t)

(add-hook 'org-mode-hook (lambda () (setq-local truncate-lines nil)))

;; FIXME Remove path hardcoding
;; TODO Automatically reload on new file created/deleted
;; Original source: https://stackoverflow.com/questions/11384516/how-to-make-all-org-files-under-a-folder-added-in-agenda-list-automatically
;; Could cause performance issues for agenda view. Check https://github.com/nicolas-graves/org-agenda-files-track as potential solution
(setq org-agenda-files (directory-files-recursively "~/src/idr/kb" "\\.org$"))

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

(provide 'dz-config-org)
