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

(add-hook 'org-mode-hook 'dz-refresh-agenda-files)
(bind-key "C-c a r" 'dz-refresh-agenda-files)

(add-hook 'org-mode-hook 'org-sticky-header-mode)
(setq org-sticky-header-full-path 'full)

(setq org-descriptive-links nil) ;; Show raw link markup by default

(setq org-special-ctrl-a/e '(t . t)) ;; smart jump in headers

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
(setq org-roam-db-location (concat org-roam-directory "/.org-roam/org-roam-sqlite-database.db"))
(add-hook 'org-mode-hook 'org-roam-db-autosync-mode)


;; TODO Make it pretty
;; https://github.com/abo-abo/hydra/wiki/Org-mode-block-templates
(defhydra hydra-org-template (:color blue :hint nil)
    "
 _c_enter  _q_uote     _e_macs-lisp    _L_aTeX:
 _l_atex   _E_xample   _p_erl          _i_ndex:
 _a_scii   _v_erse     _P_erl tangled  _I_NCLUDE:
 _s_rc     _n_ote      plant_u_ml      _H_TML:
 _h_tml    ^ ^         ^ ^             _A_SCII:
"
  ("s" (hot-expand "<s"))
  ("E" (hot-expand "<e"))
  ("q" (hot-expand "<q"))
  ("v" (hot-expand "<v"))
  ("n" (hot-expand "<not"))
  ("c" (hot-expand "<c"))
  ("l" (hot-expand "<l"))
  ("h" (hot-expand "<h"))
  ("a" (hot-expand "<a"))
  ("L" (hot-expand "<L"))
  ("i" (hot-expand "<i"))
  ("e" (hot-expand "<s" "emacs-lisp"))
  ("p" (hot-expand "<s" "perl"))
  ("u" (hot-expand "<s" "plantuml :file CHANGE.png"))
  ("P" (hot-expand "<s" "perl" ":results output :exports both :shebang \"#!/usr/bin/env perl\"\n"))
  ("I" (hot-expand "<I"))
  ("H" (hot-expand "<H"))
  ("A" (hot-expand "<A"))
  ("<" self-insert-command "ins")
  ("o" nil "quit")
  )

(require 'org-tempo)
;; Reset the org-template expnsion system, this is need after upgrading to org 9 for some reason
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
    (when header (insert "#+HEADER: " header) (forward-line))
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
      (hydra-org-template/body)
      (self-insert-command 1)
      )
    )
  )

;; TODO Bind the "org-table-*" command ONLY when the point is in an Org table.
    ;; http://emacs.stackexchange.com/a/22457/115
    (bind-keys
     :map org-mode-map
     :filter (org-at-table-p)
     ("C-c ?" . org-table-field-info)
     ("C-c SPC" . org-table-blank-field)
     ("C-c +" . org-table-sum)
     ("C-c =" . org-table-eval-formula)
     ("C-c `" . org-table-edit-field)
     ("C-#" . org-table-rotate-recalc-marks)
     ("C-c }" . org-table-toggle-coordinate-overlays)
     ("C-c {" . org-table-toggle-formula-debugger)
     ;; Add the <return> variant of bindings so that they work on
     ;; Emacs GUI too.
     ("S-<return>" . org-table-copy-down))

(provide 'dz-config-org)
