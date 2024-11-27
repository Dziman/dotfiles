;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; ace packages and their configs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package ace-window :ensure t)

(setq aw-scope 'frame)

(setq aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l))

(bind-key "C-c j w" 'ace-window)

(bind-key "C-c w j" 'ace-window)
(bind-key "C-c w k" 'aw-delete-window)
(bind-key "C-c w s" 'aw-swap-window)
(bind-key "C-c w m" 'aw-move-window)
(bind-key "C-c w v" 'aw-split-window-vert)
(bind-key "C-c w h" 'aw-split-window-horz)
(bind-key "C-c w o" 'delete-other-windows)

(provide 'dz-config-ace)
