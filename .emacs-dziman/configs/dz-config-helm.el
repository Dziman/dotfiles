;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Helm packages and their configs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package helm :ensure t)
(use-package helm-swoop :ensure t)
(use-package helm-company :ensure t)
(use-package helm-mode-manager :ensure t) ;; TODO Add keybindings/hydra?
(use-package helm-org :ensure t)
(use-package helm-org-ql :ensure t)
(use-package helm-roam :ensure t)
(use-package helm-mode-manager :ensure t)
(use-package helm-bufler :ensure t)

(setq
  helm-ff-transformer-show-only-basename nil
  helm-adaptive-history-file             "~/.emacs.d/data/helm-history"
  helm-yank-symbol-first                 t
  helm-move-to-line-cycle-in-source      t
  helm-buffers-fuzzy-matching            t
  helm-recentf-fuzzy-match               t
  helm-M-x-fuzzy-match                   t
  helm-semantic-fuzzy-match              t
  helm-ff-auto-update-initial-value      t
  helm-split-window-in-side-p            t
  helm-autoresize-min-height             25
  helm-autoresize-max-height             25
  helm-buffer-max-length                 120
  helm-buffers-column-separator          "  "
  helm-buffers-end-truncated-string      " ~~>"
  )
(helm-mode 1)
(helm-autoresize-mode 1)
(setq helm-ff-skip-boring-files t)

;; helm-swoop (search improvement)
(setq helm-swoop-split-direction 'split-window-horizontally)
(setq helm-swoop-move-to-line-cycle t)

;; TODO Learn how to use: https://github.com/emacs-helm/helm-org
(add-to-list 'helm-completing-read-handlers-alist '(org-capture . helm-org-completing-read-tags))
(add-to-list 'helm-completing-read-handlers-alist '(org-set-tags . helm-org-completing-read-tags))

;; TODO Revisit keybindings
(bind-key "M-x" 'helm-M-x)
;; This is old M-x
(bind-key "C-c C-c M-x" 'execute-extended-command)
(bind-key "C-x b" 'helm-mini)
(bind-key "C-x C-b" 'helm-buffers-list)
(bind-key "C-x C-f" 'helm-find-files)
(bind-key "C-x C-r" 'helm-recentf)
(bind-key "C-x r l" 'helm-filtered-bookmarks)
(bind-key "M-y" 'helm-show-kill-ring)
(bind-key "C-x C-d" 'helm-browse-project)

;; helm-swoop (improved search)
(bind-key "M-i" 'helm-swoop)
(bind-key "M-s o" 'helm-swoop)
(bind-key "M-I" 'helm-swoop-back-to-last-point)
(bind-key "C-c M-i" 'helm-multi-swoop)
(bind-key "M-s /" 'helm-multi-swoop)
(bind-key "C-x M-i" 'helm-multi-swoop-all)
(define-key isearch-mode-map (kbd "M-i") 'helm-swoop-from-isearch)

(setq helm-mini-default-sources
  '(
     helm-bufler-source
;;     helm-source-buffers-list
     helm-source-recentf
     helm-source-buffer-not-found
     )
  )

(provide 'dz-config-helm)
