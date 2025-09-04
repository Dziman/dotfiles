;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Settings overrides for graphic emacs (Emacs.app)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(when (display-graphic-p)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Show top menu
  (menu-bar-mode t)

  ;; Use icons in LSP breadcrumbs
  (setq lsp-headerline-breadcrumb-icons-enable t)

  ;; ------------------------------------------------------------
  ;; Frame and UI Configuration
  ;; ------------------------------------------------------------

  ;; Frame appearance settings
  (setq
    default-frame-alist
    '(
       (background-color . "#13131a")
       (foreground-color . "#a0a0ae")
       (cursor-type . (box . 4))
       (fullscreen . maximized)
       (inhibit-double-buffering . t)
       (undecorated-round . t)
       (vertical-scroll-bars . nil)
       (horizontal-scroll-bars . nil)
       (tool-bar-lines . 0)
       (menu-bar-lines . 0)
       (scroll-bar-width . 0)
       (internal-border-width . 0)
       (left-fringe . 0)
       (right-fringe . 0)
       (bottom-divider-width . 0)
       (right-divider-width . 0)
       (child-frame-border-width . 0)
       )
    )

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
      )
    )

  ;; Font settings
  (setq use-default-font-for-symbols t)
  (let (
         (mono-font "JetBrainsMono Nerd Font Mono")
         (variable-font "SF Pro")
         )

    (set-face-attribute 'default nil :family mono-font :height 170 :weight 'ultra-light)
    (set-face-attribute 'fixed-pitch nil :family mono-font :height 1.0)
    (set-face-attribute 'variable-pitch nil :family variable-font :height 1.0)
    )

  ;;Doesn't work but keep it for now. TODO Fix or remove
  ;;(set-font t 'unicode (font-spec :family "Apple Color Emoji") nil 'append)

  ;; Disable font size changes
  (global-unset-key (kbd "C-<wheel-up>"))
  (global-unset-key (kbd "C-<wheel-down>"))
  (global-unset-key [C-wheel-up])
  (global-unset-key [C-wheel-down])

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  )

(provide 'dz-config-emacs-graphic)
