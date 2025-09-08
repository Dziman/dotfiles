;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Generic packages and their configs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package no-littering :ensure t)
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
(use-package mwim :ensure t)
(use-package info-colors
  :ensure t
  :hook ((Info-selection . info-colors-fontify-node)))
(use-package helpful :ensure t)

(setf dired-kill-when-opening-new-dired-buffer t)
(add-hook 'dired-mode-hook 'diredfl-mode)
(add-hook 'dired-mode-hook 'nerd-icons-dired-mode)

;; Highlight word under caret
(define-globalized-minor-mode global-idle-highlite-mode idle-highlight-mode (lambda () (idle-highlight-mode t)))
(global-idle-highlite-mode t)

;; Enable editorconfig
(editorconfig-mode t)

;; Undo tree
(setq undo-tree-map (make-sparse-keymap)) ;; Trick to prevent `undo-tree` to remap std undo key bindings
(global-undo-tree-mode)
(bind-key "C-x u" 'undo-tree-undo)
(bind-key "C-x C-u" 'undo-tree-visualize)
;; Prevent undo tree files from polluting all dirs
(setq undo-tree-history-directory-alist '(("." . ".emacs~/undo")))
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
      ("b" split-window-right "║ horizontally")
      ("v" split-window-below "══ vertically")
      )
    )
  )

(bind-key "w" 'dziman/hydra/window/body dziman/bind-map/hydra)

(setq abbrev-file-name "~/.emacs-dziman/abbrevs.def")

(global-set-key [remap move-beginning-of-line] #'mwim-beginning)
(global-set-key [remap move-end-of-line] #'mwim-end)

;; Do not show recent buffers in switch menu. If that param is on/true then menu basially duplicate entries
(setq bufler-switch-buffer-include-recent-buffers nil)

(setq history-delete-duplicates t)

;; key bindings for `helpful`
;; TODO Keep original help bindings?
(bind-key "C-h f" 'helpful-callable)
(bind-key "C-h v" 'helpful-variable)
(bind-key "C-h k" 'helpful-key)

(recentf-mode)

(use-package emacs
  :hook (after-init .
          (lambda ()
            (global-hl-line-mode t)
            (global-auto-revert-mode t)
            (pixel-scroll-precision-mode t)
            (global-subword-mode)
            ;; Show line numbers
            (global-display-line-numbers-mode t)
            ;; Do not show top menu bar in terminal
            (menu-bar-mode 0)
            ;; Highlight current line
            (global-hl-line-mode t)
            (set-face-background 'hl-line "#3e4446")
            )
          )
  :custom
  (auto-revert-avoid-polling t) ;; Automatically reread from disk if the underlying file changes
  (auto-revert-check-vc-info t)
  (completion-ignore-case t)
  (backward-delete-char-untabify-method 'hungry)
    (auto-save-no-message t)
  (auto-save-timeout 20)
  (auto-window-vscroll nil)
  (auto-save-file-name-transforms `((".*" ,(expand-file-name "var/auto-save/" user-emacs-directory) t)))
  (auto-save-list-file-prefix (expand-file-name "var/auto-save/.saves-" user-emacs-directory))
  :config
  (setopt history-length 300)
  (setopt kept-new-versions 6)
  (setopt kept-old-versions 2)
  (setopt kill-do-not-save-duplicates t)
  (setopt large-file-warning-threshold (* 15 1024 1024))
  (setopt recentf-auto-cleanup (if (daemonp) 300 'never))
  (setopt recentf-max-menu-items 15)
  (setopt recentf-max-saved-items 300)
  (setopt use-short-answers t)
  (setopt version-control t)
;  (setopt warning-minimum-level :emergency)
  (setopt xref-search-program 'ripgrep)
  ;; Put emacs backup files into one hidden dir in current dir
  (setopt backup-directory-alist '(("." . ".emacs~")))

  (when (eq system-type 'darwin)
    (setq
      dired-use-ls-dired t
      insert-directory-program "/opt/homebrew/bin/gls"
      dired-listing-switches "-aBhl --group-directories-first"
      )
    )
  )

(provide 'dz-config-emacs-generic)
