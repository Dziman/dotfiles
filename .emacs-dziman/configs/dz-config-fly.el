;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Fly* packages and their configs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package flycheck :ensure t)
(use-package flycheck-color-mode-line :ensure t)
(use-package helm-flycheck :ensure t)
(use-package flyspell-correct-helm :ensure t)

(add-hook 'text-mode-hook 'flyspell-mode)

(eval-after-load "flyspell"
  '(define-key flyspell-mode-map (kbd "C-.") nil)) ;; Remove conflicting keybinding. See `dz-config-hydra`

;; TODO Slightly conflicting with `git-gutter`. Reconfigure for better UI
(setq-default flycheck-indication-mode 'left-margin)

(provide 'dz-config-fly)
