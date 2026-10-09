;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; git-related packages and their configs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package magit)
(use-package git-timemachine)
(use-package git-modes)
(use-package git-gutter)
(use-package git-link)
(use-package magit-todos
  :after magit
  :config (magit-todos-mode 1))

(setq magit-last-seen-setup-instructions "1.4.0")

(global-git-gutter-mode t)
(setq git-gutter:window-width 1)
(setq git-gutter:modified-sign " ")
(setq git-gutter:added-sign " ")
(setq git-gutter:deleted-sign " ")

(set-face-background 'git-gutter:modified "#5586B4")
(set-face-background 'git-gutter:added "#7DCF96")
(set-face-background 'git-gutter:deleted "#CE7666")

(defvar dziman/hydra/git--title (dziman/with-faicon "git" "Git actions" 1 -0.05))

(pretty-hydra-define dziman/hydra/git
  (:color amaranth :quit-key "q" :title dziman/hydra/git--title)
  (
    "Jump"
    (
      ("n" git-gutter:next-hunk "next hunk")
      ("p" git-gutter:previous-hunk "prev hunk")
      ("e" git-gutter:end-of-hunk "end of hunk")
      )

    "Actions"
    (
      ("d" git-gutter:popup-hunk "diff hunk")
      ("s" git-gutter:stage-hunk "stage hunk")
      ("r" git-gutter:revert-hunk "revert hunk")
      ("R" git-gutter:update-all-windows "refresh status")
      ("S" git-gutter:set-start-revision "set start revision")
      ("t" git-timemachine "timemachine" :color blue)
      )

    "Links"
    (
      ("l f" git-link "Current file and line(s)")
      ("l c" git-link-commit "Commit at point")
      ("l h" git-link-homepage "Repo home page")
      )
    )
  )

(bind-key "g" 'dziman/hydra/git/body dziman/bind-map/hydra)

(provide 'dz-config-git)
