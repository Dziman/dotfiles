;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Generic packages and their configs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package no-littering)
(use-package which-key)
(use-package bind-key)
(use-package bind-map)
(setq undo-tree-map (make-sparse-keymap)) ;; Trick to prevent `undo-tree` to remap std undo key bindings
(use-package undo-tree)
(use-package expand-region)
(use-package editorconfig)
(use-package idle-highlight-mode)
(use-package avy)
(use-package move-text)
(use-package diminish)
(use-package bufler)
(use-package nerd-icons-dired)
(use-package diredfl)
(use-package mwim)
(use-package info-colors :hook ((Info-selection . info-colors-fontify-node)))
(use-package helpful)

(setf dired-kill-when-opening-new-dired-buffer t)
(add-hook 'dired-mode-hook 'diredfl-mode)
(add-hook 'dired-mode-hook 'nerd-icons-dired-mode)

;; Highlight word under caret
(define-globalized-minor-mode global-idle-highlite-mode idle-highlight-mode (lambda () (idle-highlight-mode t)))
(global-idle-highlite-mode t)

;; Enable editorconfig
(editorconfig-mode t)

;; Undo tree
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

(global-hl-line-mode t)
(global-auto-revert-mode t)
(pixel-scroll-precision-mode t)
(global-subword-mode)
;; Show line numbers
(global-display-line-numbers-mode t)

(setq auto-revert-avoid-polling t) ;; Automatically reread from disk if the underlying file changes
(setq auto-revert-check-vc-info t)
(setq completion-ignore-case t)
(setq backward-delete-char-untabify-method 'hungry)
(setq auto-save-no-message t)
(setq auto-save-timeout 20)
(setq auto-window-vscroll nil)
(setq auto-save-file-name-transforms `((".*" ,(expand-file-name "var/auto-save/" user-emacs-directory) t)))
(setq auto-save-list-file-prefix (expand-file-name "var/auto-save/.saves-" user-emacs-directory))

(setopt history-length 300)
(setopt kept-new-versions 6)
(setopt kept-old-versions 2)
(setopt delete-old-versions t)
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

;; Highlight current line
(global-hl-line-mode t)

;; Do not show top menu bar in terminal
(menu-bar-mode 0)

(provide 'dz-config-emacs-generic)
