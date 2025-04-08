;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Generic packages and their configs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package which-key :ensure t)
(use-package bind-key :ensure t)
(use-package bind-map :ensure t)
(use-package undo-tree :ensure t)
(use-package expand-region :ensure t)
(use-package editorconfig :ensure t)
(use-package idle-highlight-mode :ensure t)
(use-package avy :ensure t)
(use-package move-text :ensure t)
(use-package diminish :ensure t)
(use-package bufler :ensure t)
(use-package nerd-icons-dired :ensure t)
(use-package diredfl :ensure t)

(setf dired-kill-when-opening-new-dired-buffer t)
(add-hook 'dired-mode-hook 'diredfl-mode)
(add-hook 'dired-mode-hook 'nerd-icons-dired-mode)

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
(global-undo-tree-mode)
(bind-key "C-x u" 'undo-tree-undo)
(bind-key "C-x C-u" 'undo-tree-visualize)
;; Prevent undo tree files from polluting all dirs
(setq undo-tree-history-directory-alist '(("." . ".emacs~/undo")))
;; Put emacs backup files into one hidden dir in current dir
(setq backup-directory-alist '(("." . ".emacs~")))
;; Кеep autosave files in temp directory
(setq auto-save-file-name-transforms `((".*" ,temporary-file-directory t)))
;; do not create locks
(setq create-lockfiles nil)

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
(bind-key "n" 'goto-line dziman/bind-map/jump)
(bind-key "c" 'avy-goto-char-timer dziman/bind-map/jump)
(bind-key "w" 'avy-goto-word-1 dziman/bind-map/jump)
(bind-key "l" 'avy-goto-line dziman/bind-map/jump)

(move-text-default-bindings)

(defvar dziman/hydra/window--title (dziman/with-faicon "windows" "Window Management" 1 -0.05))

(pretty-hydra-define dziman/hydra/window
  (:foreign-keys warn :title dziman/hydra/window--title :quit-key "q")
  (
   "Split"
    (
      ("b" split-window-right "horizontally")
      ("v" split-window-below "vertically")
      )
    )
  )

(bind-key "w" 'dziman/hydra/window/body dziman/bind-map/hydra)

(setq abbrev-file-name "~/.emacs-dziman/abbrevs.def")

(provide 'dz-config-emacs-generic)
