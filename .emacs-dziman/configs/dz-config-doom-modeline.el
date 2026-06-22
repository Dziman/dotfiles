;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Doom modeline
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package doom-modeline)
(doom-modeline-mode t)

(setq
  doom-modeline-height            30
  doom-modeline-time-icon         nil
  doom-modeline-minor-modes       t
  doom-modeline-buffer-encoding   nil
  doom-modeline-total-line-number t
  )

;;;;;;;
(use-package minions)
(setq
  minions-mode-line-lighter    "…"
  minions-mode-line-delimiters '("" . "")
  )

(minions-mode t)

(provide 'dz-config-doom-modeline)
