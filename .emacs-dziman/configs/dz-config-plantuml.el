;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; PlantUML packages and their configs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package plantuml-mode :ensure t)

(setq plantuml-default-exec-mode 'jar)
(setq plantuml-jar-path (expand-file-name "~/.plantuml/plantuml.jar"))
(setq plantuml-indent-level 2)

(add-to-list 'auto-mode-alist '("\\.plantuml\\'" . plantuml-mode))
(add-to-list 'auto-mode-alist '("\\.puml\\'" . plantuml-mode))

(add-to-list 'org-src-lang-modes '("plantuml" . plantuml))

(provide 'dz-config-plantuml)
