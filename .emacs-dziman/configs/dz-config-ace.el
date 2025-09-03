;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; ace packages and their configs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package ace-window :ensure t)

(setq aw-scope 'frame)

(setq aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l))

(bind-key "W" 'ace-window 'dziman/bind-map/jump)

(bind-map dziman/bind-map/window
  :keys ("C-c w")
  :bindings (
              "j" 'ace-select-window
              "k" 'ace-delete-window
              "s" 'ace-swap-window
              "m" 'ace-delete-other-windows
              "f" 'delete-other-windows
              "b" 'split-window-right
              "v" 'split-window-below
              )
  )

(pretty-hydra-define+ dziman/hydra/window
  nil
  (
    "Ace window"
    (
      ("j" ace-select-window "jump")
      ("k" ace-delete-window "kill")
      ("s" ace-swap-window "swap")
      ("m" ace-delete-other-windows "maximize")
      ("f" delete-other-windows "maximize current")
      )
    )
  )

(provide 'dz-config-ace)
