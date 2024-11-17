(use-package smart-mode-line :ensure t)

(setq sml/mode-width 'right)
(sml/setup)
;;; Hide minor modes which mostly enabled all the time
(setq sml/hidden-modes '(" Undo-Tree" " SP" " AC" " MRev" " Hi" " hl-p" " ElDoc" " Flymake" " Server" " WK" " company" " Helm" " yas" " EditorConfig" " company-dabbrev"))

(provide 'dz-config-smart-mode-line)
