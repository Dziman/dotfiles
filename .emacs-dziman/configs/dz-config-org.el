;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; org packages and their configs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package org-super-agenda :ensure t)
(use-package org-roam :ensure t)
(use-package org-ql :ensure t)
(use-package org-roam-ql-ql :ensure t)
(use-package org-rainbow-tags :ensure t)
(use-package org-sticky-header :ensure t)
(use-package org-super-agenda :ensure t)

(add-hook 'org-mode-hook (lambda () (setq-local truncate-lines nil)))

(defvar dz-org-directory "~/wiki")

(defun dz-refresh-agenda-files ()
  (interactive)
  ;; TODO Automatically reload on new file created/deleted
  ;; Original source: https://stackoverflow.com/questions/11384516/how-to-make-all-org-files-under-a-folder-added-in-agenda-list-automatically
  ;; Could cause performance issues for agenda view. Check https://github.com/nicolas-graves/org-agenda-files-track as potential solution
  (setq org-agenda-files (directory-files-recursively dz-org-directory "\\.org$"))
  )

(add-hook 'org-mode-hook 'dz-refresh-agenda-files)
(bind-key "C-c a r" 'dz-refresh-agenda-files)

(add-hook 'org-mode-hook 'org-sticky-header-mode)
(setq org-sticky-header-full-path 'full)

(add-hook 'org-mode-hook 'org-rainbow-tags-mode)

(setq org-descriptive-links nil) ;; Show raw link markup by default

(setq org-special-ctrl-a/e '(t . t)) ;; smart jump in headers

(setq org-todo-keywords '((sequence "TODO" "BLOCKED" "|" "DONE" "CANCELED")))
(setq org-complete-tags-always-offer-all-agenda-tags t)

;; TODO Customize https://github.com/alphapapa/org-super-agenda
(add-hook 'org-mode-hook 'org-super-agenda-mode)

;(setq org-agenda-time-grid '((daily today require-timed) "----------------------" nil)
;      org-agenda-skip-scheduled-if-done t
;      org-agenda-skip-deadline-if-done t
;      org-agenda-include-deadlines t
;      org-agenda-include-diary t
;      org-agenda-block-separator nil
;      org-agenda-compact-blocks t
;      org-agenda-start-with-log-mode t)

(setq org-super-agenda-groups
       '((:auto-map (lambda (item)
                      (-when-let* ((marker (or (get-text-property 0 'org-marker item)
                                               (get-text-property 0 'org-hd-marker item)))
                                   (file-path (->> marker marker-buffer buffer-file-name))
                                   (directory-name (->> file-path file-name-directory directory-file-name file-name-nondirectory)))
                        (concat "Directory: " directory-name))))))
;  (org-agenda-list))

(setq org-roam-directory dz-org-directory)
(setq org-roam-db-location (concat org-roam-directory "/.org-roam/org-roam-sqlite-database.db"))
(add-hook 'org-mode-hook 'org-roam-db-autosync-mode)

(pretty-hydra-define dz-hydra-org-template
  (:color blue :quit-key "q")
  (
    "Source"
    (
      ("j" (hot-expand "<s" "java") "java")
      ("s" (hot-expand "<s" "shell") "shell")
      ("e" (hot-expand "<s" "emacs-lisp") "elisp")
      ("S" (hot-expand "<s") "generic")
      )

    "Other"
    (
      ("E" (hot-expand "<e") "example")
      ("Q" (hot-expand "<q") "quote")
      ("v" (hot-expand "<v") "vers")
      ("c" (hot-expand "<c") "center")
      ("<" self-insert-command "<")
      )
    )
  )

(require 'org-tempo)
;; Reset the org-template expansion system, this is need after upgrading to org 9 for some reason
(setq org-structure-template-alist (eval (car (get 'org-structure-template-alist 'standard-value))))

(defun hot-expand (str &optional mod header)
  "Expand org template.

STR is a structure template string recognised by org like <s. MOD is a
string with additional parameters to add the begin line of the
structure element. HEADER string includes more parameters that are
prepended to the element after the #+HEADER: tag."
  (let (text)
    (when (region-active-p)
      (setq text (buffer-substring (region-beginning) (region-end)))
      (delete-region (region-beginning) (region-end))
      (deactivate-mark)
      )
    (when header (insert "#+header: " header) (forward-line))
    (insert str)
    (org-tempo-complete-tag)
    (when mod (insert mod) (forward-line))
    (when text (insert text))
    )
  )

(define-key org-mode-map "<"
  (lambda ()
    (interactive)
    (if (or (region-active-p) (looking-back "^"))
      (dz-hydra-org-template/body)
      (self-insert-command 1)
      )
    )
  )

(major-mode-hydra-define org-mode
  (:color amaranth)
  ("View"
    (
      ("l" org-toggle-link-display "toggle link view" :toggle t) ;; TODO Write wrapper function so that toggle status works
      )
    )
  )

(provide 'dz-config-org)
