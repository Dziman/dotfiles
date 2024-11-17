;;;;;; Use separate file for `custom` to keep config cleaner
(setq custom-file "~/.emacs-dziman/custom.el")
(load custom-file 'noerror)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Setup `package` to install automatically
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'package)

(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
;;(add-to-list 'package-archives '("melpa-stable" . "https://stable.melpa.org/packages/") t)
(dolist (package '(use-package))
   (unless (package-installed-p package)
       (package-install package)))

(package-initialize)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;; Add personal configs dir to list
(add-to-list 'load-path (expand-file-name "~/.emacs-dziman/configs" user-emacs-directory))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Load configs. Ordiring is important
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'dz-config-emacs-generic)
(require 'dz-config-icons)
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
(require 'dz-config-hydra)
;;(require 'dz-config-spaceline)
(require 'dz-config-appearance)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
