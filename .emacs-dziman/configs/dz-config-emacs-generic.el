;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Generic packages and their configs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(recentf-mode)
(global-hl-line-mode t)
(global-auto-revert-mode t)
(pixel-scroll-precision-mode t)
(global-subword-mode)
(global-display-line-numbers-mode t)
(global-hl-line-mode t)
(menu-bar-mode 0)
(column-number-mode t)

;; Кеep autosave files in temp directory
(setq auto-save-file-name-transforms `((".*" ,temporary-file-directory t)))
(setq create-lockfiles nil)
(setq indent-tabs-mode nil)
(setq tab-width 4)
(setq tab-stop-list (number-sequence 4 120 4))
(setq abbrev-file-name "~/.emacs-dziman/abbrevs.def")
(setq history-delete-duplicates t)
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
(setopt xref-search-program 'ripgrep)
(setopt backup-directory-alist '(("." . ".emacs~")))

(when (eq system-type 'darwin)
  (setq
    dired-use-ls-dired t
    insert-directory-program "/opt/homebrew/bin/gls"
    dired-listing-switches "-aBhl --group-directories-first"
    )
  )

;;;;;;;;
(use-package diredfl)
(use-package nerd-icons-dired)
(setf dired-kill-when-opening-new-dired-buffer t)
(add-hook 'dired-mode-hook 'diredfl-mode)
(add-hook 'dired-mode-hook 'nerd-icons-dired-mode)

;;;;;;;;
(use-package idle-highlight-mode)
;; Highlight word under caret
(define-globalized-minor-mode global-idle-highlite-mode idle-highlight-mode (lambda () (idle-highlight-mode t)))
(global-idle-highlite-mode t)

;;;;;;;;
(use-package editorconfig)
(editorconfig-mode t)

;;;;;;;;
(setq undo-tree-map (make-sparse-keymap)) ;; Trick to prevent `undo-tree` to remap std undo key bindings: must be before 'use-package undo-tree'
(use-package undo-tree)
(global-undo-tree-mode)
(bind-key "C-x u" 'undo-tree-undo)
(bind-key "C-x C-u" 'undo-tree-visualize)
;; Prevent undo tree files from polluting all dirs
(setq undo-tree-history-directory-alist '(("." . ".emacs~/undo")))

;;;;;;;;
(use-package which-key)
(which-key-mode)
(which-key-setup-side-window-bottom)
(setq which-key-compute-remaps t)

;;;;;;;;
(use-package expand-region)
(bind-key "C-c e" 'er/expand-region)

;;;;;;;;
(use-package avy)
(setq avy-timeout-seconds 0.8)

;;;;;;;;
(use-package move-text)
(move-text-default-bindings)

;;;;;;;; Bindings
;; jump to key bindings
(bind-key "n" 'goto-line dziman/bind-map/jump)
(bind-key "c" 'avy-goto-char-timer dziman/bind-map/jump)
(bind-key "w" 'avy-goto-word-1 dziman/bind-map/jump)
(bind-key "l" 'avy-goto-line dziman/bind-map/jump)

(defvar dziman/hydra/window--title (dziman/with-faicon "windows" "Window Management" 1 -0.05))

(use-package pretty-hydra) ;; FIXME
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

;;;;;;;;
(use-package mwim)
(global-set-key [remap move-beginning-of-line] #'mwim-beginning)
(global-set-key [remap move-end-of-line] #'mwim-end)

;;;;;;;;
(use-package bufler)
;; Do not show recent buffers in switch menu. If that param is on/true then menu basially duplicate entries
(setq bufler-switch-buffer-include-recent-buffers nil)

;;;;;;;;
(use-package helpful)
(bind-key "C-h f" 'helpful-callable)
(bind-key "C-h v" 'helpful-variable)
(bind-key "C-h k" 'helpful-key)

;;;;;;;;
(use-package rg)
(rg-enable-menu)

(provide 'dz-config-emacs-generic)
