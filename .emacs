;;; -*- lexical-binding: t -*-

;;;;;; Use separate file for `custom` to keep config cleaner
(setq custom-file "~/.emacs-dziman/custom.el")
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

(setq
  package-archives
  '(
     ("melpa-stable" . "https://stable.melpa.org/packages/")
     ("melpa" . "https://melpa.org/packages/")
     ("gnu" . "https://elpa.gnu.org/packages/")
     ("nongnu" . "https://elpa.nongnu.org/nongnu/")
     )
  package-archive-priorities
  '(
     ("gnu" . 99)
     ("nongnu" . 80)
     ("melpa" . 1)
     ("melpa-stable" . 0)
     )
  )
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;; Add personal configs dir to list
(add-to-list 'load-path (expand-file-name "~/.emacs-dziman/configs" user-emacs-directory))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Load configs. Ordiring is important
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'dz-config-icons)
(require 'dz-config-bind-maps)
(require 'dz-config-hydra)
(require 'dz-config-emacs-generic)
(require 'dz-config-crux)
(require 'dz-config-smart-mode-line)
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
(require 'dz-config-ios)
(require 'dz-config-appearance)
(require 'dz-config-emacs-graphic)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
