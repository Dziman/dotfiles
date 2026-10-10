;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Machine profile overrides: every *.el in
;;;;;; ~/.dziman/profile/.emacs-dziman/configs/
;;;;;; (profile chosen with `config-profile`). Required last from ~/.emacs so
;;;;;; profile files can override the shared configs.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(let ((dir (expand-file-name "~/.dziman/profile/.emacs-dziman/configs/")))
  (when (file-directory-p dir)
    (dolist (file (directory-files dir t "\\`[^.].*\\.el\\'"))
      (load file nil 'nomessage))))

(provide 'dz-config-profile)
