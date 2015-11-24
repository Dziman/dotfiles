(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   (quote
    ("c74e83f8aa4c78a121b52146eadb792c9facc5b1f02c917e3dbb454fca931223" "3c83b3676d796422704082049fc38b6966bcad960f896669dfc21a7a37a748fa" "a27c00821ccfd5a78b01e4f35dc056706dd9ede09a8b90c6955ae6a390eb1c1e" default))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

;; Cask
(require 'cask "/usr/local/Cellar/cask/0.7.4/cask.el")
(cask-initialize)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;  Global settings
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Set up mouse selection
(unless window-system
  (require 'mouse)
  (xterm-mouse-mode t)
  (global-set-key [mouse-4] (lambda ()
			      (interactive)
			      (scroll-down 1)))
  (global-set-key [mouse-5] (lambda ()
			      (interactive)
			      (scroll-up 1)))
)

;; Projectile
(projectile-global-mode)

;change default shell to zsh
(setq shell-file-name "zsh")

;; M-x enhancer
(smex-initialize)

;; IDO customization
(ido-mode 1)
(ido-everywhere 1)
(flx-ido-mode 1)
;; disable ido faces to see flx highlights.
(setq ido-enable-flex-matching t)
(setq ido-use-faces nil)
(ido-vertical-mode)

;; Themes
;;(load-theme 'darcula t)
;;(load-theme 'zerodark t)
(load-theme 'zenburn t)

;; Customize status line
(sml/setup)
(sml/apply-theme 'respectful)
(setq sml/hidden-modes '(" Anzu" " Undo-Tree" " SP" " FIC" " AC" " MRev" " Hi" " hl-p" " ElDoc" " Flymake"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;  Editor tweaks
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Do not show top menu
(menu-bar-mode 0)

;; Show column position
(column-number-mode 1)

;; Highlite current line
(global-hl-line-mode 1)
(set-face-background 'hl-line "#3e4446")

;; Show line numbers
(global-linum-mode 1)
(setq linum-format "%4d \u2502 ")

;; Show number of search result
(global-anzu-mode 1)

;; Undo tree
(global-undo-tree-mode)

;; rainbow parentheses
(add-hook 'prog-mode-hook 'rainbow-delimiters-mode)
;;(add-hook 'prog-mode-hook 'highlight-parentheses-mode)

;; Use spaces for indent
(setq indent-tabs-mode nil)
(setq tab-width 4)
(setq tab-stop-list (number-sequence 4 120 4))

;; Highlite word under caret
(define-globalized-minor-mode global-idle-highlite-mode idle-highlight-mode (lambda () (idle-highlight-mode 1)))
(global-idle-highlite-mode 1)

;; Autoclose parentheses
(smartparens-global-mode 1)

;; Highlite TODOs
(define-globalized-minor-mode global-fic-mode fic-mode (lambda () (fic-mode 1)))
(global-fic-mode 1)

;; Git settings
(setq magit-last-seen-setup-instructions "1.4.0")
(add-to-list 'auto-mode-alist '("COMMIT_EDITMSG\\'" . global-magit-file-mode))

;; Check spelling in text edit modes
(add-hook 'text-mode-hook 'flyspell-mode)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;  Go
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Load Go support mode and customization for it
(defun custom-go-mode-hook ()
  (setq tab-width 4)
)
(add-hook 'go-mode-hook 'custom-go-mode-hook)
(add-hook 'go-mode-hook (lambda() (local-set-key (kbd "C-c C-r") 'go-remove-unused-imports)))
(add-hook 'go-mode-hook (lambda() (local-set-key (kbd "C-c i") 'go-goto-imports)))

;; Autocomplete
;;(global-auto-complete-mode 1)

;; Compile and check on fly
(add-to-list 'load-path "~/Development/src/go/src/github.com/dougm/goflymake")
(require 'go-flymake)
(require 'go-flycheck)

;; Show params info
(add-hook 'go-mode-hook 'go-eldoc-setup)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;  Scala
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(require 'ensime)
(add-hook 'scala-mode-hook 'ensime-scala-mode-hook)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;  Custom keybindings
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(bind-key "C-c l" 'goto-line)
(bind-key "C-c e" 'er/expand-region)
(bind-key "M-x" 'smex)
(bind-key "M-X" 'smex-major-mode-commands)
;; This is old M-x
(bind-key "C-c C-c M-x" 'execute-extended-command)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

