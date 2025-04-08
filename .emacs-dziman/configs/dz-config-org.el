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

(defun dziman/org/get-formatted-date (&optional date-format)
  (interactive)
  (let* (
          (date-format-to-use (or date-format "%B %d %G, %a"))
          )
    (format-time-string date-format-to-use (org-read-date nil t nil nil))
    )
  )

(add-hook 'org-mode-hook (lambda () (setq-local truncate-lines nil)))

(defvar dziman/org-directory "~/wiki")

(defun dziman/refresh-agenda-files ()
  (interactive)
  ;; TODO Automatically reload on new file created/deleted
  ;; Original source: https://stackoverflow.com/questions/11384516/how-to-make-all-org-files-under-a-folder-added-in-agenda-list-automatically
  ;; Could cause performance issues for agenda view. Check https://github.com/nicolas-graves/org-agenda-files-track as potential solution
  (setq org-agenda-files (directory-files-recursively dziman/org-directory "\\.org$"))
  )

(add-hook 'org-mode-hook 'dziman/refresh-agenda-files)

(add-hook 'org-mode-hook 'org-sticky-header-mode)
(setq org-sticky-header-full-path 'full)

(add-hook 'org-mode-hook 'org-rainbow-tags-mode)
(setq org-rainbow-tags-hash-start-index 13)

(add-hook 'org-mode-hook 'abbrev-mode)

(setq org-descriptive-links nil) ;; Show raw link markup by default

(setq org-special-ctrl-a/e '(t . t)) ;; smart jump in headers

(setq org-todo-keywords '((sequence "TODO" "|" "DONE" "CANCELED")))
(setq org-complete-tags-always-offer-all-agenda-tags t)

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

(setq org-roam-directory dziman/org-directory)
(setq org-roam-db-location (concat org-roam-directory "/.org-roam/org-roam-sqlite-database.db"))
(add-hook 'org-mode-hook 'org-roam-db-autosync-mode)

(pretty-hydra-define dziman/hydra/org-template
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
      (dziman/hydra/org-template/body)
      (self-insert-command 1)
      )
    )
  )

(major-mode-hydra-define org-mode
  (:color blue)
  (
    "View"
    (
      ("l" org-toggle-link-display "toggle link view" :toggle t) ;; TODO Write wrapper function so that toggle status works
      )

    "Capture"
    (
      ("c j d" (lambda () (interactive) (org-capture nil "jd")) "journal day entry")
      ("c j m" (lambda () (interactive) (org-capture nil "jm")) "journal meeting header")
      ("c j M" (lambda () (interactive) (org-capture nil "jM")) "journal month header")
      )
    )
  )

(bind-map dziman/bind-map/org
  :keys ("C-c")
  :major-modes (org-mode)
  :bindings (
              "a" 'org-agenda
              "R" 'dziman/refresh-agenda-files
              )
  )

(setq org-capture-templates
  '(
     (
       "jd" "Journal day entry" plain (here)
       (file "~/.emacs-dziman/configs/org-templates/journal-day.tmpl.org")
       )

     (
       "jm" "Journal meeting entry" plain (here)
       (file "~/.emacs-dziman/configs/org-templates/journal-apple-meeting.tmpl.org")
       )

     (
       "jM" "Journal month entry" plain (here)
       (file "~/.emacs-dziman/configs/org-templates/journal-month.tmpl.org")
       )
     )
  )

(bind-map dziman/bind-map/org-capture
  :keys ("C-c c")
  :major-modes (org-mode)
  :bindings (
              "j d" (lambda () (interactive) (org-capture nil "jd"))
              "j m" (lambda () (interactive) (org-capture nil "jm"))
              "j M" (lambda () (interactive) (org-capture nil "jM"))
              )
  )

(which-key-add-keymap-based-replacements dziman/bind-map/org-capture
  "j" "journal entry"
  "j d" "journal day entry"
  "j m" "journal meeting header"
  "j M" "journal month header"
  )

(provide 'dz-config-org)
