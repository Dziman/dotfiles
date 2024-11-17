;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; org packages and their configs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package org-super-agenda :ensure t)
(use-package org-multi-wiki :ensure t) ;; TODO Learn https://github.com/akirak/org-multi-wiki
(use-package org-ql :ensure t) ;; TODO Learn https://github.com/alphapapa/org-ql
(use-package org-rainbow-tags :ensure t)

(add-hook 'org-mode-hook
  (lambda ()
    (setq-local truncate-lines nil)))

(provide 'dz-config-org)
