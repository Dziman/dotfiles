;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Programming languages packages and their configs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package pyenv-mode :ensure t)
(use-package python-mode :ensure t)
(use-package company-anaconda :ensure t)
(use-package flycheck-pycheckers :ensure t)
(use-package elpy :ensure t)

(use-package web-mode :ensure t)
(use-package json-mode :ensure t)
(use-package json-reformat :ensure t)
(use-package markdown-mode :ensure t)
(use-package yaml-mode :ensure t)
(use-package gradle-mode :ensure t)
(use-package dockerfile-mode :ensure t)
(use-package terraform-mode :ensure t)
(use-package company-terraform :ensure t)
(use-package kotlin-mode :ensure t)

(provide 'dz-config-prog-languages)
