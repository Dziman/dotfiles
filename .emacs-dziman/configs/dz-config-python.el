;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Python development
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar apheleia-formatters)
(defvar projectile-project-root)
(defvar lsp-completion-provider)
(defvar lsp-pyls-plugins-jedi-completion-enabled)
(defvar lsp-pyls-plugins-jedi-definition-enabled)
(defvar lsp-pyls-plugins-jedi-hover-enabled)
(defvar lsp-pyls-plugins-jedi-references-enabled)
(defvar lsp-pyls-plugins-jedi-signature-help-enabled)
(defvar lsp-pyls-plugins-jedi-symbols-enabled)
(defvar lsp-pyls-plugins-pylint-enabled)
(defvar lsp-pyls-plugins-pycodestyle-enabled)
(defvar lsp-pyls-plugins-pyflakes-enabled)
(defvar lsp-pyls-plugins-mccabe-enabled)
(defvar lsp-pyls-plugins-pydocstyle-enabled)
(defvar lsp-pyls-plugins-yapf-enabled)
(defvar lsp-pyls-plugins-autopep8-enabled)
(defvar lsp-pyls-plugins-black-enabled)
(defvar lsp-pyls-plugins-isort-enabled)
(defvar lsp-pyls-plugins-ruff-enabled)
(defvar lsp-pyls-plugins-flake8-enabled)
(defvar lsp-pyls-plugins-mypy-enabled)
(defvar lsp-pyls-plugins-pyls-mypy-enabled)
(defvar lsp-pyls-plugins-pyls-black-enabled)
(defvar lsp-pyls-plugins-pyls-isort-enabled)
(defvar lsp-pyls-plugins-pyls-ruff-enabled)
(defvar lsp-pyls-plugins-pyls-flake8-enabled)
(defvar lsp-pyls-plugins-pyls-mypy-ls-enabled)
(defvar lsp-pyls-plugins-pyls-rope-completion-enabled)
(defvar lsp-pyls-plugins-pyls-rope-definition-enabled)
(defvar lsp-pyls-plugins-pyls-rope-hover-enabled)
(defvar lsp-pyls-plugins-pyls-rope-references-enabled)
(defvar lsp-pyls-plugins-pyls-rope-signature-help-enabled)
(defvar lsp-pyls-plugins-pyls-rope-symbols-enabled)
(defvar lsp-pyls-plugins-pyls-rope-autoimport-enabled)
(defvar lsp-pyls-plugins-pyls-rope-completion-enabled)
(defvar lsp-pyls-server-command)

;;;;;; Major modes
(use-package python
  :ensure nil
  :mode (("\\.py\\'" . python-mode)
         ("\\.pyw\\'" . python-mode)
         ("\\.pyi\\'" . python-mode)))

(use-package python-ts-mode
  :ensure nil
  :mode (("\\.py\\'" . python-ts-mode)
         ("\\.pyw\\'" . python-ts-mode)
         ("\\.pyi\\'" . python-ts-mode)))

;;;;;; LSP configuration for Python
(with-eval-after-load 'lsp-mode
  (setq lsp-completion-provider :none)

  (setq lsp-pyls-plugins-jedi-completion-enabled t)
  (setq lsp-pyls-plugins-jedi-definition-enabled t)
  (setq lsp-pyls-plugins-jedi-hover-enabled t)
  (setq lsp-pyls-plugins-jedi-references-enabled t)
  (setq lsp-pyls-plugins-jedi-signature-help-enabled t)
  (setq lsp-pyls-plugins-jedi-symbols-enabled t)

  (setq lsp-pyls-plugins-pylint-enabled nil)
  (setq lsp-pyls-plugins-pycodestyle-enabled nil)
  (setq lsp-pyls-plugins-pyflakes-enabled nil)
  (setq lsp-pyls-plugins-mccabe-enabled nil)
  (setq lsp-pyls-plugins-pydocstyle-enabled nil)

  (setq lsp-pyls-plugins-yapf-enabled nil)
  (setq lsp-pyls-plugins-autopep8-enabled nil)
  (setq lsp-pyls-plugins-black-enabled nil)
  (setq lsp-pyls-plugins-isort-enabled nil)
  (setq lsp-pyls-plugins-ruff-enabled nil)
  (setq lsp-pyls-plugins-flake8-enabled nil)
  (setq lsp-pyls-plugins-mypy-enabled nil)

  (lsp-register-client
   (make-lsp-client
    :new-connection (lsp-stdio-connection '("pylsp"))
    :activation-fn (lsp-activate-on "python")
    :server-id 'pyls
    :priority 1)))

;;;;;; Ruff formatting via apheleia
(with-eval-after-load 'apheleia
  (setf (alist-get 'ruff-format apheleia-formatters)
        '("ruff" "format" "--stdin-filename" filepath "-"))
  (setf (alist-get 'ruff-check apheleia-formatters)
        '("ruff" "check" "--fix" "--stdin-filename" filepath "-")))

;;;;;; Virtual environment support
(use-package pyvenv)

;;;;;; Project navigation helpers
(defun dziman/py-find-pyproject ()
  "Open the nearest pyproject.toml from the current buffer."
  (interactive)
  (let ((root (locate-dominating-file default-directory "pyproject.toml")))
    (if root
        (find-file (expand-file-name "pyproject.toml" root))
      (message "No pyproject.toml found in project root or ancestors"))))

(defun dziman/py-find-setup-cfg ()
  "Open the nearest setup.cfg from the current buffer."
  (interactive)
  (let ((root (locate-dominating-file default-directory "setup.cfg")))
    (if root
        (find-file (expand-file-name "setup.cfg" root))
      (message "No setup.cfg found in project root or ancestors"))))

(defun dziman/py-find-requirements ()
  "Open the nearest requirements*.txt from the current buffer."
  (interactive)
  (let* ((patterns '("requirements.txt" "requirements-dev.txt" "requirements-test.txt"))
         (found (cl-loop for pat in patterns
                         for f = (locate-dominating-file default-directory pat)
                         when f collect (expand-file-name pat f))))
    (if found
        (find-file (completing-read "Open requirements: " found))
      (message "No requirements*.txt found in project root or ancestors"))))

(defun dziman/py-run-pytest ()
  "Run pytest for the current project."
  (interactive)
  (let ((root (or (and (fboundp 'projectile-project-root)
                       (ignore-errors (projectile-project-root)))
                  default-directory)))
    (compile (format "cd %s && python -m pytest" root))))

(defun dziman/py-run-pytest-watch ()
  "Run pytest in watch mode for the current project."
  (interactive)
  (let ((root (or (and (fboundp 'projectile-project-root)
                       (ignore-errors (projectile-project-root)))
                  default-directory)))
    (compile (format "cd %s && ptw" root))))

(defun dziman/py-run-mypy ()
  "Run mypy for the current project."
  (interactive)
  (let ((root (or (and (fboundp 'projectile-project-root)
                       (ignore-errors (projectile-project-root)))
                  default-directory)))
    (compile (format "cd %s && python -m mypy ." root))))

(defun dziman/py-activate-venv ()
  "Activate a Python virtual environment."
  (interactive)
  (let ((venv-dir (read-directory-name "Virtual environment directory: ")))
    (pyvenv-activate venv-dir)))

(defun dziman/py-deactivate-venv ()
  "Deactivate the current Python virtual environment."
  (interactive)
  (pyvenv-deactivate))

;;;;;; Hooks
(defun dziman/py-mode-setup ()
  "Setup Python development hooks."
  (setq-local tab-width 4)
  (setq-local python-indent-offset 4)
  (lsp-deferred))

(add-hook 'python-mode-hook #'dziman/py-mode-setup)
(add-hook 'python-ts-mode-hook #'dziman/py-mode-setup)

(define-minor-mode dziman-py-mode
  "Dziman prog minor mode for customizing key bindings etc"
  :init-value nil
  :lighter " DzPyProgMode")

(add-hook 'python-mode-hook 'dziman-py-mode)
(add-hook 'python-ts-mode-hook 'dziman-py-mode)

(bind-map dz-py-mode-map
  :keys ("C-c p")
  :minor-modes (dziman-py-mode)
  )


;;;;;; Key bindings for Python development
(bind-keys
 :map dz-py-mode-map
 ("p" . #'dziman/py-find-pyproject)
 ("s" . #'dziman/py-find-setup-cfg)
 ("r" . #'dziman/py-find-requirements)
 ("t" . #'dziman/py-run-pytest)
 ("w" . #'dziman/py-run-pytest-watch)
 ("m" . #'dziman/py-run-mypy)
 ("v" . #'dziman/py-activate-venv)
 ("V" . #'dziman/py-deactivate-venv))

;;;;;; Spacing and indentation for Python
(setq-default python-indent-offset 4)

(provide 'dz-config-python)
