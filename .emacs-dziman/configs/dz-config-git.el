;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; git-related packages and their configs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package magit :defer t)
(use-package git-timemachine :defer t)
(use-package git-modes :defer t)
(use-package git-gutter
  :commands (git-gutter:next-hunk git-gutter:previous-hunk git-gutter:end-of-hunk
             git-gutter:popup-hunk git-gutter:stage-hunk git-gutter:revert-hunk
             git-gutter:update-all-windows git-gutter:set-start-revision))
(use-package git-link :defer t)
(use-package magit-todos
  :after magit
  :config (magit-todos-mode 1))

(setq magit-last-seen-setup-instructions "1.4.0")

(add-hook 'dziman/first-buffer-hook #'global-git-gutter-mode)
(setq git-gutter:window-width 1)
(setq git-gutter:modified-sign " ")
(setq git-gutter:added-sign " ")
(setq git-gutter:deleted-sign " ")

(with-eval-after-load 'git-gutter
  (set-face-background 'git-gutter:modified "#5586B4")
  (set-face-background 'git-gutter:added "#7DCF96")
  (set-face-background 'git-gutter:deleted "#CE7666")
  )

(autoload 'dziman/git-menu "dz-config-git-menu" "File, repository and pull request actions that apply here." t)
(bind-key "g" #'dziman/git-menu dziman/bind-map/hydra)
(which-key-add-key-based-replacements "C-. g" "git menu")

(provide 'dz-config-git)
