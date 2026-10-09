;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Apperance customizations (like themes, etc.)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package labburn-theme)

(load-theme 'labburn t)

(with-eval-after-load "avy"
    (set-face-attribute 'avy-lead-face nil :background "#00CED1" :foreground "#00008B" :weight 'bold)
    (set-face-attribute 'avy-lead-face-0 nil :background "#00CED1" :foreground "#FE0000" :weight 'bold)
    (set-face-attribute 'avy-lead-face-2 nil :background "#00CED1" :foreground "#00008B" :weight 'bold)
  )

(with-eval-after-load "ace-window"
  (set-face-attribute 'aw-leading-char-face nil :background "#FFFFFF" :foreground "#FE0000" :weight 'bold)
  )

(set-face-attribute 'mode-line nil :background "#5F5F5F")

(setq highlight-parentheses-background-colors '("dimgray"))
(setq highlight-parentheses-colors '("firebrick1" "seagreen" "IndianRed3" "forestgreen"))

(provide 'dz-config-appearance)
