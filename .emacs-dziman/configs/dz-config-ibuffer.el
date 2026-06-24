;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; ibuffer packages and their configs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; TODO Check what these settings mean :)
(setq ibuffer-saved-filter-groups
  (quote (
    ("default-dziman"
      ("dired" (mode . dired-mode))
      ("emacs" (or
       (name . "^\\*scratch\\*$")
       (name . "^\\*Messages\\*$")
       (name . "^\\*Warnings\\*$")
       (name . "^\\*Help\\*$")
      ))
      ("helm" (or
       (name . "^\\*helm.*$")
       (mode . helm-mode)
      ))
    )
  ))
)

(setq ibuffer-formats
      `((mark
         modified
         read-only
;;         vc-status-mini
         " "
         (name 60 60 :left :elide)
         ,(propertize "| " 'font-lock-face ibuffer-title-face)
         (mode 15 15 :left)
         ,(propertize " | " 'font-lock-face ibuffer-title-face)
         filename)))

(provide 'dz-config-ibuffer)
