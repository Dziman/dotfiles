;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Punch line configs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package punch-line
  :ensure nil
  :config
  (setq
    punch-show-project-info t
    punch-show-git-info t
    punch-show-lsp-info t
    punch-show-flycheck-info t
    punch-show-org-info t
    punch-show-misc-info t
    punch-line-show-time-info t
    punch-show-column-info t
    punch-show-buffer-position t

    punch-show-copilot-info nil
    punch-show-battery-info nil
    punch-show-weather-info nil

    punch-line-modal-use-fancy-icon t
    punch-line-modal-divider-style 'arrow
    punch-line-modal-size 'large

    punch-line-left-separator "  "
    punch-line-right-separator "  "
    )
  )

;; Missing very important for me feature: save indicator. Decided not to use (for now)
(punch-line-mode)

(provide 'dz-config-punch-line)
