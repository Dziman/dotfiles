;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Doom modeline
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package doom-modeline :defer t)

(setq
  doom-modeline-height            30
  doom-modeline-time-icon         nil
  doom-modeline-minor-modes       t
  doom-modeline-buffer-encoding   nil
  doom-modeline-total-line-number t
  )

;;;;;;;
(use-package minions :defer t)
;; minions aliases `minions-mode-line-delimiters' to a built-in variable when it loads;
;; setting it earlier gets the value overwritten
(with-eval-after-load 'minions
  (setq
    minions-mode-line-lighter    "…"
    minions-mode-line-delimiters '("" . "")
    )
  )

(defun dziman/enable-mode-line ()
  (doom-modeline-mode t)
  (minions-mode t)
  )

;; Turned on once the first frame is shown: the default mode line is visible for a moment,
;; but loading doom-modeline no longer delays that frame
(run-with-idle-timer 0 nil #'dziman/enable-mode-line)

(provide 'dz-config-doom-modeline)
