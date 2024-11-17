;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; ace packages and their configs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package ace-window :ensure t)
(use-package ace-jump-helm-line :ensure t) ;; TODO Learn/config https://github.com/cute-jumper/ace-jump-helm-line?tab=readme-ov-file
(use-package ace-jump-mode :ensure t) ;; TODO Learn/config https://github.com/winterTTr/ace-jump-mode

(setq aw-scope 'frame)

(bind-key "M-o" 'ace-window)
;; TODO Customize ace-window action bindings: https://github.com/abo-abo/ace-window

(provide 'dz-config-ace)
