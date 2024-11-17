;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Apperance customizations (like themes, etc.)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package labburn-theme :ensure t)
(use-package powerline :ensure t)

(load-theme 'labburn t)

(set-face-attribute 'avy-lead-face nil :background "#00CED1" :foreground "#00008B" :weight 'bold)
(set-face-attribute 'avy-lead-face-0 nil :background "#00CED1" :foreground "#FE0000" :weight 'bold)
(set-face-attribute 'avy-lead-face-2 nil :background "#00CED1" :foreground "#00008B" :weight 'bold)

(set-face-attribute 'mode-line nil :background "#5F5F5F")

(provide 'dz-config-appearance)
