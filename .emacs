(custom-set-variables
 '(custom-safe-themes
   '("3c83b3676d796422704082049fc38b6966bcad960f896669dfc21a7a37a748fa" default))
 '(package-selected-packages
   '(rainbow-delimiters which-key smartparens smart-mode-line magit labburn-theme idle-highlight-mode helm-projectile editorconfig)))
(custom-set-faces)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;  Install packages ;; TODO Move to separate file?
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'package)

(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))
(dolist (package '(use-package))
   (unless (package-installed-p package)
       (package-install package)))

(package-initialize)

(use-package labburn-theme :ensure t)
(use-package which-key :ensure t)
(use-package bind-key :ensure t)
(use-package expand-region :ensure t)
(use-package smart-mode-line :ensure t)
(use-package hl-todo :ensure t)
(use-package undo-tree :ensure t)
(use-package company :ensure t)
(use-package editorconfig :ensure t)
(use-package idle-highlight-mode :ensure t)
(use-package smartparens :ensure t)
(use-package rainbow-delimiters :ensure t)

(use-package helm :ensure t)
(use-package helm-swoop :ensure t)
(use-package helm-projectile :ensure t)
(use-package helm-company :ensure t)
(use-package helm-mode-manager :ensure t) ;; TODO Add keybindings/hydra?

(use-package projectile :ensure t)

;; Git extended support TODO Revisit?
(use-package magit :ensure t)

;; TODO Revisit
(use-package org-roam :ensure t)
(use-package org-rainbow-tags :ensure t)

;; TODO Revisit
(use-package hydra :ensure t)

;; Check buffer on the fly
(use-package flycheck :ensure t) ;; TODO Setup checks for all(?) prog-modes
(use-package flycheck-color-mode-line :ensure t)
(use-package helm-flycheck :ensure t)
(use-package flyspell-correct-helm :ensure t)

;; Python related
(use-package pyenv-mode :ensure t)
(use-package python-mode :ensure t)
(use-package company-anaconda :ensure t)
(use-package flycheck-pycheckers :ensure t)

;; Mostly programming related modes
(use-package json-mode :ensure t)
(use-package json-reformat :ensure t)
(use-package markdown-mode :ensure t)
(use-package yaml-mode :ensure t)
(use-package gradle-mode :ensure t)
(use-package dockerfile-mode :ensure t)
(use-package terraform-mode :ensure t)
(use-package company-terraform :ensure t)
(use-package swift-mode :ensure t)
(use-package kotlin-mode :ensure t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;  Global settings
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; change default shell to zsh
(setq shell-file-name "zsh")

(load-theme 'labburn t)

;; Customize status line
(setq sml/mode-width 'right)
(sml/setup)
(setq sml/hidden-modes '(" Undo-Tree" " SP" " AC" " MRev" " Hi" " hl-p" " ElDoc" " Flymake" " Server" " WK" " company" " Helm" " yas" " EditorConfig" " company-dabbrev"))

;; Show column position
(column-number-mode 1)

;; Do not show top menu
(menu-bar-mode 0)

;; Highlight current line
(global-hl-line-mode 1)
(set-face-background 'hl-line "#3e4446")

;; Highlight word under caret
(define-globalized-minor-mode global-idle-highlite-mode idle-highlight-mode (lambda () (idle-highlight-mode 1)))
(global-idle-highlite-mode 1)

;; Highlight TODOs
(setq hl-todo-keyword-faces
  '(
     ("TODO" warning bold)
     ("FIXME"  error bold)
     ("NOTE"  success bold)
   )
)
(add-hook 'prog-mode-hook 'hl-todo-mode)

;; rainbow parentheses
(add-hook 'prog-mode-hook 'rainbow-delimiters-mode)

;; Show line numbers
(global-display-line-numbers-mode 1)

;; helm
(setq helm-ff-transformer-show-only-basename nil
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
      )
(helm-mode 1)
(helm-autoresize-mode 1)
(setq helm-ff-skip-boring-files t)

;; helm-swoop (search improvement)
(setq helm-swoop-split-direction 'split-window-horizontally)
(setq helm-swoop-move-to-line-cycle t)

;; Projectile
(projectile-mode)
(setq projectile-completion-system 'helm)
(helm-projectile-on)
(define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map)

;; Undo tree
(global-undo-tree-mode)

;; Use spaces for indent
(setq indent-tabs-mode nil)
(setq tab-width 4)
(setq tab-stop-list (number-sequence 4 120 4))

;; Autoclose parentheses
(smartparens-global-mode 1)

;; Completion
(add-hook 'after-init-hook 'global-company-mode)
(setq company-tooltip-align-annotations t)

;; Check spelling in text edit modes
(add-hook 'text-mode-hook 'flyspell-mode)

;; do not follow symlinks
(setq vc-follow-symlinks t)

;; Help to learn keys
(which-key-mode)
(which-key-setup-side-window-bottom)

;; quick jump to windows
(setq aw-scope 'frame)

;; Enable editorconfig
(editorconfig-mode 1)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; Git
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(setq magit-last-seen-setup-instructions "1.4.0")
(magit-commit) ;; FIXME

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;  Custom keybindings
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(bind-key "C-c l" 'goto-line)
(bind-key "C-c e" 'er/expand-region)
(bind-key "M-p" 'ace-window)

;;;;;;;;;;;;;;;
;;; Helm keys
(bind-key "M-x" 'helm-M-x)
;;; This is old M-x
(bind-key "C-c C-c M-x" 'execute-extended-command)
(bind-key "C-x b" 'helm-mini)
(bind-key "C-x C-b" 'helm-buffers-list)
(bind-key "C-x C-f" 'helm-find-files)
(bind-key "C-x C-r" 'helm-recentf)
(bind-key "C-x r l" 'helm-filtered-bookmarks)
(bind-key "M-y" 'helm-show-kill-ring)
(bind-key "C-x C-d" 'helm-browse-project)

;;;;;;;;;;;;;;;
;;; helm-swoop (improved search)
(bind-key "M-i" 'helm-swoop)
(bind-key "M-s o" 'helm-swoop)
(bind-key "M-I" 'helm-swoop-back-to-last-point)
(bind-key "C-c M-i" 'helm-multi-swoop)
(bind-key "M-s /" 'helm-multi-swoop)
(bind-key "C-x M-i" 'helm-multi-swoop-all)
(define-key isearch-mode-map (kbd "M-i") 'helm-swoop-from-isearch)

;;;;;;;;;;;;;;;
;;; Completion
(eval-after-load 'company
  '(progn
     (define-key company-mode-map (kbd "C-c c") 'helm-company)
       (define-key company-active-map (kbd "C-c c") 'helm-company)))

;;;;;;;;;;;;;;;
;;; Duplicate current line
(bind-key "C-c C-d" "\C-a\C- \C-n\M-w\C-y\C-b")
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;
;;; ibuffer settings ;; TODO Revisit
(setq ibuffer-saved-filter-groups
  (quote (
    ("default-dziman"
      ("dired" (mode . dired-mode))
      ("emacs" (or
       (name . "^\\*scratch\\*$")
       (name . "^\\*Messages\\*$")
       (name . "^\\*Warnings\\*$")
       (name . "^\\*Help\\*$")
      ))
      ("helm" (or
       (name . "^\\*helm.*$")
       (mode . helm-mode)
      ))
    )
  ))
)

(setq ibuffer-formats
      `((mark
         modified
         read-only
         vc-status-mini
         " "
         (name 60 60 :left :elide)
         ,(propertize "| " 'font-lock-face ibuffer-title-face)
         (mode 15 15 :left)
         ,(propertize " | " 'font-lock-face ibuffer-title-face)
         filename)))
