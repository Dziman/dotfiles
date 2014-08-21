(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes (quote ("fc5fcb6f1f1c1bc01305694c59a1a861b008c534cae8d0e48e4d5e81ad718bc6" "8aebf25556399b58091e533e455dd50a6a9cba958cc4ebb0aab175863c25b9a4" "0c311fb22e6197daba9123f43da98f273d2bfaeeaeb653007ad1ee77f0003037" "0e121ff9bef6937edad8dfcff7d88ac9219b5b4f1570fd1702e546a80dba0832" "7ed6913f96c43796aa524e9ae506b0a3a50bfca061eed73b66766d14adfa86d1" "6a37be365d1d95fad2f4d185e51928c789ef7a4ccf17e7ca13ad63a8bf5b922f" "756597b162f1be60a12dbd52bab71d40d6a2845a3e3c2584c6573ee9c332a66e" default))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

;; Cask
(require 'cask "/usr/local/Cellar/cask/0.7.1/cask.el")
(cask-initialize)

;; Load Go support mode and customization for it
(require 'go-mode)
(defun custom-go-mode-hook ()
  (setq tab-width 4)
)
(add-hook 'go-mode-hook 'custom-go-mode-hook)
(add-hook 'go-mode-hook (lambda() (local-set-key (kbd "C-c C-r") 'go-remove-unused-imports)))
(add-hook 'go-mode-hook (lambda() (local-set-key (kbd "C-c i") 'go-goto-imports)))
;; Autocomplete
(require 'go-autocomplete)
(require 'auto-complete-config)
(global-auto-complete-mode 1)
;; Compile and check on fly
(add-to-list 'load-path "~/.go/src/github.com/dougm/goflymake")
(require 'go-flymake)
(require 'go-flycheck)
;; Finding unchecked errors
(require 'go-errcheck)
;; Show params info
(require 'go-eldoc)
(add-hook 'go-mode-hook 'go-eldoc-setup)
;; Show error message in mini buffer
(require 'flymake-cursor)

;; Projectile
(require 'projectile)
(projectile-global-mode)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;  Editor tweaks
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Show column position
(column-number-mode 1)

;; Highlite current line
(global-hl-line-mode 1)

;; Show line numbers
(require 'linum)
(global-linum-mode 1)
(setq linum-format "%4d \u2502 ")

;; Show number of search result
(global-anzu-mode 1)

;; Move selected text by M-Up M-Down
(require 'move-text)
(move-text-default-bindings)

;; Undo tree
(require 'undo-tree)
(global-undo-tree-mode)

;; rainbow parentheses
(require 'rainbow-delimiters)
(add-hook 'prog-mode-hook 'rainbow-delimiters-mode)
(require 'highlight-parentheses)
(add-hook 'prog-mode-hook 'highlight-parentheses-mode)

;; Use spaces for indent
(setq indent-tabs-mode nil)
(setq tab-width 4)
(setq tab-stop-list (number-sequence 4 120 4))

;; Show whitespaces
;(require 'whitespace)
;(setq-default whitespace-line-column 120)
;(global-whitespace-mode 1)

;; Show right margin
(require 'fill-column-indicator)
(setq fci-rule-use-dashes nil)
(setq fci-rule-column 140)
(setq fci-rule-width 1)
(setq fci-rule-color "black")
(define-globalized-minor-mode global-fci-mode fci-mode (lambda () (fci-mode 1)))
(global-fci-mode 1)

;; Highlite word under caret
(define-globalized-minor-mode global-idle-highlite-mode idle-highlight-mode (lambda () (idle-highlight-mode 1)))
(global-idle-highlite-mode 1)

;; Autoclose parentheses
(require 'smartparens)
(require 'smartparens-config)
(smartparens-global-mode 1)

;; Highlite TODOs
(require 'fic-mode)
(define-globalized-minor-mode global-fic-mode fic-mode (lambda () (fic-mode 1)))
(global-fic-mode 1)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; M-x enhancer
(require 'smex)
(smex-initialize)
(global-set-key (kbd "M-x") 'smex)
(global-set-key (kbd "M-X") 'smex-major-mode-commands)
;; This is old M-x
(global-set-key (kbd "C-c C-c M-x") 'execute-extended-command)

;; Git extended integration
(require 'magit)

;; IDO customization
(require 'flx-ido)
(ido-mode 1)
(ido-everywhere 1)
(flx-ido-mode 1)
;; disable ido faces to see flx highlights.
(setq ido-enable-flex-matching t)
(setq ido-use-faces nil)

;; Customize status line
(require 'smart-mode-line)
(sml/setup)
(sml/apply-theme 'dark)

;; Customize status line
;(require 'powerline)
;(require 'powerline-separators)
;(powerline-default-theme)
;(powerline-center-theme)

;; Themes
(load-theme 'solarized-dark)
;(load-theme 'ample)
;(load-theme 'grandshell)
;(load-theme 'molokai)
;(load-theme 'noctilux)
;(require 'moe-theme)
;(moe-dark)
