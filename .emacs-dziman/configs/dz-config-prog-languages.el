;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Programming languages packages and their configs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package pyenv-mode)
(use-package python-mode)
(use-package company-anaconda)
(use-package flycheck-pycheckers)
(use-package elpy)

(use-package web-mode)
(use-package json-mode)
(use-package json-reformat)
(use-package markdown-mode)
(use-package yaml-mode)
(use-package gradle-mode)
(use-package dockerfile-mode)
(use-package terraform-mode)
(use-package company-terraform)
(use-package kotlin-mode)

(provide 'dz-config-prog-languages)
