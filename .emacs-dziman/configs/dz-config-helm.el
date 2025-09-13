;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Helm packages and their configs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package helm)
(use-package helm-company)
(use-package helm-mode-manager)

(setq helm-ff-transformer-show-only-basename nil
      helm-adaptive-history-file             "~/.emacs.d/data/helm-history"
      helm-yank-symbol-first                 t
      helm-move-to-line-cycle-in-source      t
      helm-buffers-fuzzy-matching            t
      helm-recentf-fuzzy-match               t
      helm-M-x-fuzzy-match                   t
      helm-semantic-fuzzy-match              t
      helm-ff-auto-update-initial-value      t
      helm-split-window-inside-p             t
      helm-autoresize-min-height             25
      helm-autoresize-max-height             25
      helm-buffer-max-length                 120
      helm-buffers-column-separator          "  "
      helm-buffers-end-truncated-string      " ~~>"
      )
(helm-mode 1)
(helm-autoresize-mode 1)
(setq helm-ff-skip-boring-files t)

(add-to-list 'helm-completing-read-handlers-alist '(org-capture . helm-org-completing-read-tags))
(add-to-list 'helm-completing-read-handlers-alist '(org-set-tags . helm-org-completing-read-tags))
(setq helm-org-format-outline-path t)
(setq helm-org-headings-fontify t)
(setq helm-org-ignore-autosaves t)

(bind-key "M-x" 'helm-M-x)
;; This is old M-x
(bind-key "C-c C-c M-x" 'execute-extended-command)
(bind-key "C-x C-b" 'helm-mini)
(bind-key "C-x b" 'bufler-switch-buffer)
(bind-key "C-x C-f" 'helm-find-files)
(bind-key "C-x C-r" 'helm-recentf)
(bind-key "C-x r l" 'helm-filtered-bookmarks)
(bind-key "M-y" 'helm-show-kill-ring)
(bind-key "C-x C-d" 'helm-browse-project)

;; helm-occur (improved search)
(bind-key "M-i" 'helm-occur)
(bind-key "M-s o" 'helm-occur)
(define-key isearch-mode-map (kbd "M-i") 'helm-occur-from-isearch)

(provide 'dz-config-helm)
