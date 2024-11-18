(use-package smart-mode-line :ensure t)
(use-package smart-mode-line-powerline-theme :ensure t)

;; TODO Finetune?
(setq sml/mode-width 'right)
(setq powerline-arrow-shape 'curve)
(setq powerline-default-separator-dir '(right . left))
(setq sml/theme 'powerline)
(sml/setup)
;;; Hide minor modes which mostly enabled all the time
(setq
  sml/hidden-modes
  '(
     " Undo-Tree"
     " SP"
     " AC"
     " MRev"
     " Hi"
     " hl-p"
     " ElDoc"
     " Flymake"
     " Server"
     " WK"
     " company"
     " Helm"
     " yas"
     " EditorConfig"
     " company-dabbrev"
     " abbrev"
     " GitGutter"
     " Fly/--"
     " ARev"
     " h"
     " Abbrev"
     " Rbow"
     )
  )

(provide 'dz-config-smart-mode-line)
