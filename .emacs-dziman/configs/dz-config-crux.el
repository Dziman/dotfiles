;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Generic packages and their configs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package crux)

(bind-key "C-c C-d" 'crux-duplicate-current-line-or-region)
(bind-key "C-<return>" 'crux-smart-open-line)
(bind-key "M-<return>" 'crux-smart-open-line-above)
(bind-key "M-k" 'crux-smart-kill-line)
;; `keyboard-quit` close the minibuffer or completions buffer even without focusing it.
(bind-key "C-g" 'crux-keyboard-quit-dwim)

;;;; Hydra to learn ~crux~
;;;; TODO Remove it later?
(pretty-hydra-define dziman/hydra/crux
  (:foreign-keys warn :exit t :title " Collection of Ridiculously Useful eXtensions" :quit-key "q")
  (
    "File"
    (
      ("f o" crux-open-with "open with")
      ("f d" crux-delete-file-and-buffer "delete")
      ("f c" crux-copy-file-preserve-attributes "copy file")
      ("f R" crux-rename-file-and-buffer "rename")
      ("f r" crux-recentf-find-file "open recent")
      ("d r" crux-recentf-find-directory "open recent dir")
      )
    "Line"
    (
      ("l k k" crux-smart-kill-line "smart kill")
      ("l k S" crux-kill-whole-line "kill whole")
      ("l k s" crux-kill-line-backwards "kill to start")
      ("l k j" crux-kill-and-join-forward "kill and join")
      ("l j" crux-top-join-line "join")
      ("l i b" crux-smart-open-line "insert below")
      ("l i a" crux-smart-open-line-above "insert above")
      ("l d" crux-duplicate-current-line-or-region "duplicate")
      ("l c" crux-duplicate-and-comment-current-line-or-region "duplicate and comment")
      )
    "Other"
    (
      ("I b" crux-cleanup-buffer-or-region "indent buffer/region")
      ("I d" crux-indent-defun "indent definition")
      ("v" crux-view-url "view url")
      ("e" crux-eval-and-replace "eval and replace elisp")
      ("K" crux-kill-other-buffers "kill other buffers")
      )
    )
  )

(bind-key "c" 'dziman/hydra/crux/body dziman/bind-map/hydra)

(provide 'dz-config-crux)
