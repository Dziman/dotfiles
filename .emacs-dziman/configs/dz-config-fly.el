;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Fly* packages and their configs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package flycheck :defer t)
(use-package flycheck-color-mode-line :defer t)
(use-package flyspell-correct
  :after flyspell
  :bind (:map flyspell-mode-map ([remap ispell-word] . flyspell-correct-wrapper))
  )

(add-hook 'text-mode-hook 'flyspell-mode)

(eval-after-load "flyspell"
  '(define-key flyspell-mode-map (kbd "C-.") nil)) ;; Remove conflicting keybinding. See `dz-config-hydra`

;; TODO Slightly conflicting with `git-gutter`. Reconfigure for better UI
(setq-default flycheck-indication-mode 'left-margin)

(provide 'dz-config-fly)
