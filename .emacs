;;; -*- lexical-binding: t -*-

(setq dziman/settings-base-dir (or (getenv "DZIMAN_EMACS_SETTINGS_DIR") "~/.emacs-dziman"))

;;;;;; Use separate file for `custom` to keep config cleaner
(setq custom-file (expand-file-name "custom.el" dziman/settings-base-dir))
(load custom-file :noerror :nomessage)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Setup `package`
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; install packages automatically
(dolist (package '(use-package))
  (unless (package-installed-p package)
    (package-install package)
    )
  )

(package-initialize)

(use-package use-package
  :custom
  (use-package-verbose nil)
  (use-package-expand-minimally t)
  (use-package-always-ensure t)
  (use-package-compute-statistics t)
  (use-package-minimum-reported-time 0.02)
  )

(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;; Add personal configs dir and subdirs to list
(let ((dir (expand-file-name "configs" dziman/settings-base-dir)))
  (when (file-directory-p dir)
    (add-to-list 'load-path dir)
    (let ((default-directory dir))
      (normal-top-level-add-subdirs-to-load-path))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Load configs. Ordiring is important in some cases
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'dz-config-icons)
(require 'dz-config-bind-maps)
(require 'dz-config-hydra)
(require 'dz-config-emacs-generic)
(require 'dz-config-crux)
(require 'dz-config-prog-mode)
(require 'dz-config-git)
(require 'dz-config-org)
(require 'dz-config-plantuml)
(require 'dz-config-helm)
(require 'dz-config-projectile)
(require 'dz-config-fly)
(require 'dz-config-completion)
(require 'dz-config-prog-languages)
(require 'dz-config-ibuffer)
(require 'dz-config-ace)
(require 'dz-config-eglot)
(require 'dz-config-ios)
(require 'dz-config-appearance)
(require 'dz-config-emacs-graphic)
(require 'dz-config-doom-modeline)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
