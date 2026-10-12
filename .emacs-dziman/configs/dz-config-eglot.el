;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Eglot (Language Server Protocol client) settings shared by all languages
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package eglot
  :ensure nil
  :defer t
  :bind
  (:map eglot-mode-map
    ("M-p r" . eglot-rename)
    ("M-p a" . eglot-code-actions)
    ("M-p s" . consult-eglot-symbols)
    )
  :custom
  (eglot-autoshutdown t)
  (eglot-extend-to-xref t)
  )

;; Diagnostics go to flycheck (fringe marks, flycheck-inline, `M-g e') instead of flymake.
;; Not exclusive, so a language's own flycheck checker (e.g. SwiftLint) runs after the server's.
(use-package flycheck-eglot
  :after eglot
  :custom
  (flycheck-eglot-exclusive nil)
  :config
  (global-flycheck-eglot-mode 1)
  )

(use-package consult-eglot
  :defer t
  :commands consult-eglot-symbols
  )

(provide 'dz-config-eglot)
