(custom-set-variables
 '(custom-safe-themes
      '("84d2f9eeb3f82d619ca4bfffe5f157282f4779732f48a5ac1484d94d5ff5b279" "b04425cc726711a6c91e8ebc20cf5a3927160681941e06bc7900a5a5bfe1a77f" "c74e83f8aa4c78a121b52146eadb792c9facc5b1f02c917e3dbb454fca931223" "3c83b3676d796422704082049fc38b6966bcad960f896669dfc21a7a37a748fa" "a27c00821ccfd5a78b01e4f35dc056706dd9ede09a8b90c6955ae6a390eb1c1e" default))
)

;; Cask
(require 'cask "$HOMEBREW_PREFIX/Cellar/cask/0.8.8/cask.el")
(cask-initialize)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;  Global settings
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; change default shell to zsh
(setq shell-file-name "zsh")

;; Themes
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

;; Show whitespaces in programming mode
;; (add-hook 'prog-mode-hook 'whitespace-mode) ;; It is braking highlighting so disabled for now

;; Show line numbers
(global-linum-mode 1)
(setq linum-format "%4d \u2502 ")

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

;; Use helm for company
(eval-after-load 'company
  '(progn
     (define-key company-mode-map (kbd "C-:") 'helm-company)
     (define-key company-active-map (kbd "C-:") 'helm-company)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; Git
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(setq magit-last-seen-setup-instructions "1.4.0")
(magit-commit) ;; FIXME

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; TypeScript
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(add-hook 'typescript-mode-hook
  (lambda ()
    (tide-setup)
    (flycheck-mode +1)
    (setq flycheck-check-syntax-automatically '(save mode-enabled))
    (eldoc-mode +1)
    (company-mode-on)))

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
;;; ibuffer settings
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
