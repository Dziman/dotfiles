;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; org packages and their configs ;; TODO Review, improve, cleanup
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package org-super-agenda :defer t)
(use-package org-roam :defer t)
(use-package org-rainbow-tags :defer t)
(use-package org-sticky-header :defer t)
(use-package calfw-org :commands calfw-org-open-calendar)

(declare-function org-read-date "org")
(declare-function org-tempo-complete-tag "org-tempo")
(declare-function org-indent-mode "org-indent")

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

(defun dziman/agenda-folders-command (root)
  "Command listing the folders under ROOT, one per line, hidden ones skipped."
  (let ((fd (executable-find "fd")))
    (if fd
      (list fd "--type" "d" "--no-ignore" "--color" "never" "." root)
      (list "find" root "-mindepth" "1" "-name" ".*" "-prune" "-o" "-type" "d" "-print")
      )
    )
  )

(defun dziman/agenda-folders-from-output (root output)
  "ROOT and the folders named in OUTPUT, sorted.
OUTPUT is what `dziman/agenda-folders-command' printed."
  (sort (mapcar #'directory-file-name (cons root (split-string output "\n" t))) #'string<)
  )

(defun dziman/refresh-agenda-files ()
  "Set `org-agenda-files' to the folders under `dziman/org-directory'.
The folders are listed in the background. Org reads the .org files of each
listed folder whenever it needs them, so only a new folder needs a refresh.
Returns the listing process, or nil when the folder is missing."
  (interactive)
  (let ((root (file-name-as-directory (expand-file-name dziman/org-directory))))
    (when (file-directory-p root)
      (let ((default-directory root)
             (output (generate-new-buffer " *dziman-agenda-folders*" t))
             (errors (generate-new-buffer " *dziman-agenda-folders-errors*" t)))
        (make-process
          :name "dziman-agenda-folders"
          :buffer output
          :stderr errors
          :noquery t
          :connection-type 'pipe
          :command (dziman/agenda-folders-command root)
          :sentinel (lambda (process _event)
                      (unless (process-live-p process)
                        (let ((listing (with-current-buffer output (buffer-string))))
                          (unless (zerop (process-exit-status process))
                            (message "Agenda folders: %s" (string-trim (with-current-buffer errors (buffer-string))))
                            )
                          ;; find exits 1 after one unreadable folder but still lists the others
                          (when (or (zerop (process-exit-status process)) (not (string-empty-p listing)))
                            (setq org-agenda-files (dziman/agenda-folders-from-output root listing))
                            )
                          )
                        (kill-buffer output)
                        (kill-buffer errors)
                        )
                      )
          )
        )
      )
    )
  )

(run-with-idle-timer 1 nil #'dziman/refresh-agenda-files)

(add-hook 'org-mode-hook 'org-sticky-header-mode)
(setq org-sticky-header-full-path 'full)

(add-hook 'org-mode-hook 'org-indent-mode)
(add-hook 'org-mode-hook 'org-rainbow-tags-mode)
(add-hook 'org-agenda-finalize-hook 'org-rainbow-tags-mode)
(setq org-rainbow-tags-hash-start-index 13)
(setq org-rainbow-tags-extra-face-attributes '(:inverse-video t :box t :weight 'bold))
(setq org-rainbow-tags-adjust-color-percent 33)

(setq org-link-descriptive t) ;; Show 'rendered' link by default

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

(use-package pretty-hydra)
(require 'hydra)
;; Called by the `bind-map' expansion
(declare-function evil-normalize-keymaps "evil")
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

(with-eval-after-load 'org
  (require 'org-tempo)
  ;; Start from org's standard template list so the `<' expansions match org's documented defaults
  (setq org-structure-template-alist (eval (car (get 'org-structure-template-alist 'standard-value))))
  )

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

(with-eval-after-load 'org
  (define-key org-mode-map "<"
    (lambda ()
      (interactive)
      (if (or (region-active-p) (bolp))
        (dziman/hydra/org-template/body)
        (self-insert-command 1)
        )
      )
    )
  )

(declare-function org-before-first-heading-p "org")
(declare-function org-back-to-heading "org")
(declare-function org-up-heading-safe "org")
(declare-function org-current-level "org")
(declare-function org-get-heading "org")
(declare-function org-fold-show-context "org-fold")

(defun dziman/org-parent-headings ()
  "Ancestors of the heading at point, nearest first, as (\"** Title\" . POSITION).
Empty at top level and before the first heading."
  (save-excursion
    (unless (org-before-first-heading-p)
      (org-back-to-heading t)
      (let ((parents nil))
        (while (org-up-heading-safe)
          (push (cons (concat (make-string (org-current-level) ?*) " " (org-get-heading t t t t)) (point)) parents)
          )
        (nreverse parents)
        )
      )
    )
  )

(defun dziman/org-jump-to-parent-heading ()
  "Jump to an ancestor of the heading at point, picked from a list, nearest first."
  (interactive)
  (let ((parents (dziman/org-parent-headings)))
    (unless parents
      (user-error "No parent heading here")
      )
    (goto-char (cdr (assoc (completing-read "Parent heading: " parents nil t nil nil (caar parents)) parents)))
    (org-fold-show-context)
    )
  )

(use-package major-mode-hydra)
(major-mode-hydra-define org-mode
  (:color blue)
  (
    "View"
    (
      ("l" org-toggle-link-display "toggle link view" :toggle org-link-descriptive)
      ("i" org-indent-mode "toggle indent view" :toggle t)
      )

    "Browse"
    (
      ("b a" consult-org-agenda "agenda headings")
      ("b b" consult-org-heading "buffer headings")
      ("b p" dziman/org-jump-to-parent-heading "parent headings")
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
(setq org-link-file-path-type 'relative)

(setq calfw-display-calendar-holidays nil)

(provide 'dz-config-org)

;; The hydra macro's generated docstring has a separator line of UTF-8 box characters,
;; measured in bytes, which trips the 80-column docstring check of the byte-compiler
;; Local Variables:
;; byte-compile-docstring-max-column: 200
;; End:
