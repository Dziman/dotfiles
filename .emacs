;;; -*- lexical-binding: t -*-

(setq dziman/settings-base-dir (or (getenv "DZIMAN_EMACS_SETTINGS_DIR") "~/.emacs-dziman"))

;;;;;; Use separate file for `custom` to keep config cleaner
(setq custom-file (expand-file-name "custom.el" dziman/settings-base-dir))
(load custom-file :noerror :nomessage)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Setup `package`
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Packages are already activated before init (`package-enable-at-startup' +
;; `package-quickstart' in early-init), so no explicit `package-initialize' here.

(with-eval-after-load 'package
  (add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t))

;; install packages automatically
(dolist (package '(use-package))
  (unless (package-installed-p package)
    (package-install package)
    )
  )

(defun dziman/use-package-ensure (name args state &optional no-refresh)
  "Skip `use-package-ensure-elpa' for installed packages.
It always requires the whole of package.el (~80 ms); `package-installed-p'
alone needs only the small package-activate.el."
  (unless (and (equal args '(t)) (package-installed-p (use-package-as-symbol name)))
    (use-package-ensure-elpa name args state no-refresh)
    )
  )

(setq use-package-ensure-function #'dziman/use-package-ensure)

(use-package use-package
  :custom
  (use-package-verbose nil)
  (use-package-expand-minimally t)
  (use-package-always-ensure t)
  ;; Set DZIMAN_EMACS_PROFILE=1 and run `M-x use-package-report' to profile startup
  (use-package-compute-statistics (and (getenv "DZIMAN_EMACS_PROFILE") t))
  (use-package-minimum-reported-time 0.02)
  )

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
(require 'dz-config-mermaid)
(require 'dz-config-prog-mode)
(require 'dz-config-git)
(require 'dz-config-org)
(require 'dz-config-projectile)
(require 'dz-config-fly)
(require 'dz-config-completion)
(require 'dz-config-vertico)
(require 'dz-config-prog-languages)
(require 'dz-config-eglot)
(require 'dz-config-swift)
(require 'dz-config-ibuffer)
(require 'dz-config-ace)
(require 'dz-config-appearance)
(require 'dz-config-emacs-graphic)
(require 'dz-config-doom-modeline)
(require 'dz-config-preload)
(require 'dz-config-profile)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
