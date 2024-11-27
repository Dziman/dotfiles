;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Generic packages and their configs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package which-key :ensure t)
(use-package bind-key :ensure t)
(use-package expand-region :ensure t)
(use-package editorconfig :ensure t)
(use-package idle-highlight-mode :ensure t)
(use-package avy :ensure t)
(use-package bind-map :ensure t)
(use-package move-text :ensure t)
(use-package diminish :ensure t)
(use-package bufler :ensure t)
;; (use-package helm-bufler :ensure t) ;; TODO Learn/configure

;; Highlight word under caret
(define-globalized-minor-mode global-idle-highlite-mode idle-highlight-mode (lambda () (idle-highlight-mode 1)))
(global-idle-highlite-mode 1)

;; Enable editorconfig
(editorconfig-mode 1)

;; Show column position
(column-number-mode 1)

;; Do not show top menu
(menu-bar-mode 0)

;; Highlight current line
(global-hl-line-mode 1)
(set-face-background 'hl-line "#3e4446")

;; Show line numbers
(global-display-line-numbers-mode 1)

;; Undo tree
(setq undo-tree-map (make-sparse-keymap)) ;; Trick to prevent `undo-tree` to remap std undo key bindings
(use-package undo-tree :ensure t)
(global-undo-tree-mode)
(bind-key "C-x u" 'undo-tree-undo)
(bind-key "C-x C-u" 'undo-tree-visualize)
;; Prevent undo tree files from polluting all dirs
(setq undo-tree-history-directory-alist '(("." . ".emacs~/undo")))
;; Put emacs backup files into one hidden dir in current dir
(setq backup-directory-alist '(("." . ".emacs~")))
;; Кеep autosave files in temp directory
(setq auto-save-file-name-transforms `((".*" ,temporary-file-directory t)))

;; Use spaces for indent
(setq indent-tabs-mode nil)
(setq tab-width 4)
(setq tab-stop-list (number-sequence 4 120 4))

;; do not follow symlinks
(setq vc-follow-symlinks t)

;; Help to learn keys
(which-key-mode)
(which-key-setup-side-window-bottom)
(setq which-key-compute-remaps t)

(bind-key "C-c e" 'er/expand-region)
;; Duplicate current line
(bind-key "C-c C-d" "\C-a\C- \C-n\M-w\C-y\C-b")

(setq avy-timeout-seconds 0.8)

;; jump to key bindings
(bind-key "C-c j n" 'goto-line)
(bind-key "C-c j c" 'avy-goto-char-timer)
(bind-key "C-c j W" 'avy-goto-word-1)
(bind-key "C-c j l" 'avy-goto-line)

(move-text-default-bindings)

;; TODO Learn how to use workspaces https://github.com/alphapapa/bufler.el?tab=readme-ov-file
;; (bufler-workspace-mode t)

;; TODO Move to line start/end enhancments: https://d12frosted.io/posts/2020-06-04-beginning-of-line.html and/or https://github.com/alezost/mwim.el

(provide 'dz-config-emacs-generic)
