;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; git-related packages and their configs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package magit :ensure t)
(use-package git-timemachine :ensure t)
(use-package git-modes :ensure t)
(use-package git-gutter :ensure t)
(use-package magit-todos
  :ensure t
  :after magit
  :config (magit-todos-mode 1)) ;; Revisit: it looks broken

(setq magit-last-seen-setup-instructions "1.4.0")

(global-git-gutter-mode t)
(setq git-gutter:window-width 1)
(setq git-gutter:modified-sign " ")
(setq git-gutter:added-sign " ")
(setq git-gutter:deleted-sign " ")

(set-face-background 'git-gutter:modified "#5586B4")
(set-face-background 'git-gutter:added "#7DCF96")
(set-face-background 'git-gutter:deleted "#CE7666")

(provide 'dz-config-git)
