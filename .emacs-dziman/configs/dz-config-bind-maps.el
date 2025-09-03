;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Defining key bind maps
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package bind-key :ensure t)
(use-package bind-map :ensure t)

(bind-map dziman/bind-map/hydra
  :keys ("C-.")
  )

(bind-map dziman/bind-map/jump
  :keys ("C-c j")
  )

(provide 'dz-config-bind-maps)
