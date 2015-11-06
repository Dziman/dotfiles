(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   (quote
    ("3c83b3676d796422704082049fc38b6966bcad960f896669dfc21a7a37a748fa" "a27c00821ccfd5a78b01e4f35dc056706dd9ede09a8b90c6955ae6a390eb1c1e" default))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

;; Cask
(require 'cask "/usr/local/Cellar/cask/0.7.3/cask.el")
(cask-initialize)

;; Load Go support mode and customization for it
(defun custom-go-mode-hook ()
  (setq tab-width 4)
)
(add-hook 'go-mode-hook 'custom-go-mode-hook)
(add-hook 'go-mode-hook (lambda() (local-set-key (kbd "C-c C-r") 'go-remove-unused-imports)))
(add-hook 'go-mode-hook (lambda() (local-set-key (kbd "C-c i") 'go-goto-imports)))
;; Autocomplete
(global-auto-complete-mode 1)
;; Compile and check on fly
(add-to-list 'load-path "~/Development/src/go/src/github.com/dougm/goflymake")
(require 'go-flymake)
(require 'go-flycheck)
;; Show params info
(add-hook 'go-mode-hook 'go-eldoc-setup)

;; Projectile
(projectile-global-mode)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;  Scala
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(require 'ensime)
(add-hook 'scala-mode-hook 'ensime-scala-mode-hook)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;  Editor tweaks
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Show column position
(column-number-mode 1)

;; Highlite current line
(global-hl-line-mode 1)

;; Show line numbers
(global-linum-mode 1)
(setq linum-format "%4d \u2502 ")

;; Show number of search result
(global-anzu-mode 1)

;; Move selected text by M-Up M-Down
(move-text-default-bindings)

;; Undo tree
(global-undo-tree-mode)

;; rainbow parentheses
(add-hook 'prog-mode-hook 'rainbow-delimiters-mode)
(add-hook 'prog-mode-hook 'highlight-parentheses-mode)

;; Use spaces for indent
(setq indent-tabs-mode nil)
(setq tab-width 4)
(setq tab-stop-list (number-sequence 4 120 4))

;; Show whitespaces
;(require 'whitespace)
;(setq-default whitespace-line-column 120)
;(global-whitespace-mode 1)

;; Show right margin [Disabled due to empty line jump bug]
;(setq fci-rule-use-dashes nil)
;(setq fci-rule-column 140)
;(setq fci-rule-width 1)
;(setq fci-rule-color "black")
;(define-globalized-minor-mode global-fci-mode fci-mode (lambda () (fci-mode 1)))
;(global-fci-mode 1)

;; Highlite word under caret
(define-globalized-minor-mode global-idle-highlite-mode idle-highlight-mode (lambda () (idle-highlight-mode 1)))
(global-idle-highlite-mode 1)

;; Autoclose parentheses
(smartparens-global-mode 1)

;; Highlite TODOs
(define-globalized-minor-mode global-fic-mode fic-mode (lambda () (fic-mode 1)))
(global-fic-mode 1)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;  Custom keybindings
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(global-set-key (kbd "C-c l") 'goto-line)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;change default shell to zsh
(setq shell-file-name "zsh")

;; M-x enhancer
(smex-initialize)
(global-set-key (kbd "M-x") 'smex)
(global-set-key (kbd "M-X") 'smex-major-mode-commands)
;; This is old M-x
(global-set-key (kbd "C-c C-c M-x") 'execute-extended-command)

;; IDO customization
(ido-mode 1)
(ido-everywhere 1)
(flx-ido-mode 1)
;; disable ido faces to see flx highlights.
(setq ido-enable-flex-matching t)
(setq ido-use-faces nil)
(ido-vertical-mode)

;; Themes
(load-theme 'solarized t)
(set-frame-parameter nil 'background-mode 'dark)
(set-terminal-parameter nil 'background-mode 'dark)

;; Customize status line
(sml/setup)
(sml/apply-theme 'dark)
(setq sml/hidden-modes '(" Anzu" " Undo-Tree" " SP" " FIC" " AC" " MRev" " Hi" " hl-p" " ElDoc" " Flymake"))

