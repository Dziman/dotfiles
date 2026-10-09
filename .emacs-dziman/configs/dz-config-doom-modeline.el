;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Doom modeline
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package doom-modeline)
(use-package minions)

(setq minions-mode-line-lighter "…")
(setq minions-mode-line-delimiters '("" . ""))

(minions-mode t)

(doom-modeline-mode t)

(setq doom-modeline-height 30)
(setq doom-modeline-time-icon nil)
(setq doom-modeline-minor-modes t)
(setq doom-modeline-buffer-encoding nil)
(setq doom-modeline-total-line-number t)

(provide 'dz-config-doom-modeline)
