;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Fly* packages and their configs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package flycheck :ensure t) ;; TODO Setup checks for all(?) prog-modes
(use-package flycheck-color-mode-line :ensure t)
(use-package helm-flycheck :ensure t)
(use-package flyspell-correct-helm :ensure t)

(add-hook 'text-mode-hook 'flyspell-mode)

(provide 'dz-config-fly)
