;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Settings overrides for graphic emacs (Emacs.app)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(when (or
        (display-graphic-p)
        (string= (getenv "DZIMAN_EMACSCLIENT_MODE") "ui")
        )
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Show top menu
  (menu-bar-mode t)

  ;; Use icons in LSP breadcrumbs
  (setq lsp-headerline-breadcrumb-icons-enable t)

  ;; ------------------------------------------------------------
  ;; Platform-Specific Configuration
  ;; ------------------------------------------------------------
  (when (eq system-type 'darwin)
    ;; macOS-specific settings
    (push '(ns-use-native-fullscreen . nil) default-frame-alist)
    (push '(ns-transparent-titlebar . t) default-frame-alist)
    (push '(ns-appearance . dark) default-frame-alist)
    (push '(ns-use-srgb-colorspace . t) default-frame-alist)

    (setq
      ns-use-proxy-icon nil
      mac-command-modifier 'super
      mac-option-modifier 'meta
      mac-right-option-modifier nil
      )
    )

  ;; Font settings
  (setq use-default-font-for-symbols t)
  (let (
         ;;(mono-font "JetBrainsMono Nerd Font Mono")
         (mono-font "Cascadia Code NF")
         (variable-font "SF Pro")
         )

    (set-face-attribute 'default nil :family mono-font :height 170 :weight 'ultra-light)
    (set-face-attribute 'fixed-pitch nil :family mono-font :height 1.0)
    (set-face-attribute 'variable-pitch nil :family variable-font :height 1.0)
    )

  (use-package ligature
  :config
  ;; Enable the "www" ligature in every possible major mode
  (ligature-set-ligatures 't '("www"))
  ;; Enable traditional ligature support in eww-mode, if the
  ;; `variable-pitch' face supports it
  (ligature-set-ligatures 'eww-mode '("ff" "fi" "ffi"))
  ;; Enable all Cascadia Code ligatures in programming modes
  (ligature-set-ligatures 'prog-mode '("|||>" "<|||" "<==>" "<!--" "####" "~~>" "***" "||=" "||>"
                                       ":::" "::=" "=:=" "===" "==>" "=!=" "=>>" "=<<" "=/=" "!=="
                                       "!!." ">=>" ">>=" ">>>" ">>-" ">->" "->>" "-->" "---" "-<<"
                                       "<~~" "<~>" "<*>" "<||" "<|>" "<$>" "<==" "<=>" "<=<" "<->"
                                       "<--" "<-<" "<<=" "<<-" "<<<" "<+>" "</>" "###" "#_(" "..<"
                                       "..." "+++" "/==" "///" "_|_" "www" "&&" "^=" "~~" "~@" "~="
                                       "~>" "~-" "**" "*>" "*/" "||" "|}" "|]" "|=" "|>" "|-" "{|"
                                       "[|" "]#" "::" ":=" ":>" ":<" "$>" "==" "=>" "!=" "!!" ">:"
                                       ">=" ">>" ">-" "-~" "-|" "->" "--" "-<" "<~" "<*" "<|" "<:"
                                       "<$" "<=" "<>" "<-" "<<" "<+" "</" "#{" "#[" "#:" "#=" "#!"
                                       "##" "#(" "#?" "#_" "%%" ".=" ".-" ".." ".?" "+>" "++" "?:"
                                       "?=" "?." "??" ";;" "/*" "/=" "/>" "//" "__" "~~" "(*" "*)"
                                       "\\\\" "://"))
  ;; Enables ligature checks globally in all buffers. You can also do it
  ;; per mode with `ligature-mode'.
  (global-ligature-mode t))

  ;;Doesn't work but keep it for now. TODO Fix or remove
  ;;(set-font t 'unicode (font-spec :family "Apple Color Emoji") nil 'append)

  ;; Disable font size changes
  (global-unset-key (kbd "C-<wheel-up>"))
  (global-unset-key (kbd "C-<wheel-down>"))
  (global-unset-key [C-wheel-up])
  (global-unset-key [C-wheel-down])

  (tool-bar-mode 0)

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  )

(provide 'dz-config-emacs-graphic)
