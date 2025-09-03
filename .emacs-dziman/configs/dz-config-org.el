;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; org packages and their configs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package org-super-agenda :ensure t)
(use-package org-roam :ensure t)
(use-package org-rainbow-tags :ensure t)
(use-package org-sticky-header :ensure t)
(use-package org-super-agenda :ensure t)
(use-package helm-org :ensure t)
(use-package helm-roam :ensure t)

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
(add-hook 'org-agenda-finalize-hook 'org-rainbow-tags-mode)
(setq org-rainbow-tags-hash-start-index 13)
(setq org-rainbow-tags-extra-face-attributes '(:inverse-video t :box t :weight 'bold))
(setq org-rainbow-tags-adjust-color-percent 33)

(setq org-descriptive-links nil) ;; Show raw link markup by default

(setq org-special-ctrl-a/e '(t . t)) ;; smart jump in headers

(setq org-todo-keywords '((sequence "TODO" "|" "DONE" "CANCELED")))
(setq org-log-done t)
(setq org-deadline-warning-days 5)
(setq org-scheduled-delay-days 0)

(setq org-complete-tags-always-offer-all-agenda-tags t)

(add-hook 'org-mode-hook 'org-super-agenda-mode)
(setq org-agenda-span 'week)
(setq org-agenda-show-inherited-tags 'always)
(setq org-agenda-with-colors t)
(setq org-agenda-tags-column -105)
(setq org-agenda-time-leading-zero t)
(setq org-agenda-skip-deadline-if-done t)
(setq org-agenda-skip-scheduled-if-done t)
(setq org-agenda-skip-scheduled-if-deadline-is-shown t)
(setq org-agenda-include-deadlines t)
(setq org-agenda-compact-blocks t)

(setq org-agenda-custom-commands
  '(

     (
       "r" "Reading list"
       (
         (
           todo ""
           (
             (org-agenda-overriding-header "Reading list")
             (org-super-agenda-groups
               '(
                  (
                    :name "Books"
                    :and ( :tag ("to_read") :tag ("book") )
                    :order 1
                    )

                  (
                    :name "Web"
                    :and ( :tag ("to_read") :tag ("web") )
                    :order 2
                    )

                  (:discard (:anything t))

                  )
               )
             )
           )
         )
       )

     (
       "e" "Everything TODOs"
       (
         (
           todo ""
           (
             (org-agenda-overriding-header "TODOs")
             (org-super-agenda-groups
               '(
                  (
                    :name "Overdue"
                    :time-grid t
                    :deadline past

                    :face (:foreground "firebrick" :weight bold)
                    :order 0
                    )

                  (
                    :name "Deadline today"
                    :time-grid t
                    :deadline today

                    :face (:foreground "darkgoldenrod" :weight bold)
                    :order 1
                    )

                  (
                    :name "Starting today"
                    :time-grid t
                    :scheduled today

                    :face (:foreground "chartreuse4" :weight bold)
                    :order 2
                    )

                  (
                    :name "Prioritized"
                    :priority<="A"
                    :order 3
                    )

                  (
                    :name "TODOs"
                    :not (:tag ("to_read"))
                    :order 4
                    )

                  (:discard (:anything t))

                  )
               )
             )
           )
         )
       )

     )
  )

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

    "Browse"
    (
      ("b h a" helm-org-agenda-files-headings "All headings")
      ("b h b" helm-org-in-buffer-headings "Buffer headings")
      ("b h p" helm-org-parent-headings "Parent headings")
      )

    "Capture"
    (
      ("c j d" (lambda () (interactive) (org-capture nil "jd")) "journal day entry")
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
              "j M" (lambda () (interactive) (org-capture nil "jM"))
              )
  )

(which-key-add-keymap-based-replacements dziman/bind-map/org-capture
  "j" "journal entry"
  "j d" "journal day entry"
  "j M" "journal month header"
  )

(setq org-refile-targets '((org-agenda-files :maxlevel . 5)))
(setq org-refile-use-outline-path 'file)
(setq org-outline-path-complete-in-steps nil)
(setq org-refile-allow-creating-parent-nodes 'confirm)

(provide 'dz-config-org)
