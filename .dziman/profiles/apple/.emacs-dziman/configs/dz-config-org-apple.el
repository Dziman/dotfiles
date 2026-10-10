;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Apple journal: meeting capture (jm) and the Apple month header (jM)
;;;;;; on top of the shared org config
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defvar dziman/apple-org-templates "~/.dziman/profile/.emacs-dziman/configs/org-templates/")

(add-to-list 'org-capture-templates
  `("jm" "Journal meeting entry" plain (here)
     (file ,(concat dziman/apple-org-templates "journal-apple-meeting.tmpl.org")))
  t)

(setf (alist-get "jM" org-capture-templates nil nil #'equal)
  `("Journal month entry" plain (here)
     (file ,(concat dziman/apple-org-templates "journal-apple-month.tmpl.org"))))

(major-mode-hydra-define+ org-mode
  (:color blue)
  (
    "Capture"
    (
      ("c j m" (lambda () (interactive) (org-capture nil "jm")) "journal meeting header")
      )
    )
  )

(bind-key "j m" (lambda () (interactive) (org-capture nil "jm")) dziman/bind-map/org-capture)
(which-key-add-keymap-based-replacements dziman/bind-map/org-capture
  "j m" "journal meeting header"
  )
