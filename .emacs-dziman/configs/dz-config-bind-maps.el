;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Defining key bind maps
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package bind-key)
(use-package bind-map)

(bind-map dziman/bind-map/hydra
  :keys ("C-.")
  )

(bind-map dziman/bind-map/jump
  :keys ("C-c j")
  )

(provide 'dz-config-bind-maps)
