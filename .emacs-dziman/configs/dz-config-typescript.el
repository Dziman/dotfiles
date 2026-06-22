;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; TypeScript, JavaScript, Vue and related web development ;; TODO Rewview, improve, cleanup
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;(defvar apheleia-formatters)
;;(defvar projectile-project-root)
;;(defvar vue-mode-line)
;;(defvar lsp-typescript-suggest-complete-jsdocs)
;;(defvar lsp-javascript-suggest-complete-jsdocs)
;;(defvar lsp-typescript-format-enable)
;;(defvar lsp-javascript-format-enable)
;;(defvar lsp-eslint-enable)
;;(defvar lsp-eslint-auto-fix-on-save)
;;(defvar lsp-eslint-run)
;;(defvar lsp-completion-provider)
;;(defvar lsp-language-id-configuration)

;;;;;; Major modes
;;(use-package typescript-ts-mode
;;  :ensure nil
;;  :mode (("\\.ts\\'" . typescript-ts-mode)
;;         ("\\.tsx\\'" . tsx-ts-mode)
;;         ("\\.mts\\'" . typescript-ts-mode)
;;         ("\\.cts\\'" . typescript-ts-mode)))

;(use-package js
;  :ensure nil
;  :mode (("\\.js\\'" . js-ts-mode)
;         ("\\.jsx\\'" . js-ts-mode)
;         ("\\.mjs\\'" . js-ts-mode)
;         ("\\.cjs\\'" . js-ts-mode)))

(use-package vue-mode
                                         :mode "\\.vue\\'"
  :config
  (setq vue-mode-line
        '(:eval (format " [vue+%s]"
                        (if (bound-and-true-p typescript-mode)
                            "ts"
                          "js")))))

;;;;;; lsp-mode configuration for TypeScript/JavaScript
;(require 'ht)
;(require 'json)

;(with-eval-after-load 'lsp-mode
;  (setq lsp-typescript-suggest-complete-jsdocs t)
;  (setq lsp-javascript-suggest-complete-jsdocs t)
;  (setq lsp-typescript-format-enable t)
;  (setq lsp-javascript-format-enable t)

;  (setq lsp-eslint-enable t)
;  (setq lsp-eslint-auto-fix-on-save t)
;  (setq lsp-eslint-run "onSave")

;  (setq lsp-completion-provider :none)
;
;  (add-to-list 'lsp-language-id-configuration '(vue-mode . "vue"))

;  (lsp-register-client
;   (make-lsp-client
;    :new-connection (lsp-stdio-connection '("typescript-language-server" "--stdio"))
;    :activation-fn (lsp-activate-on "typescript" "typescriptreact" "javascript" "javascriptreact")
;    :server-id 'ts-ls
;    :priority 1
;    :initialized-fn (lambda (workspace)
;                      (with-lsp-workspace workspace
;                        (lsp--set-configuration
;                         (ht ("typescript" (ht ("format" (ht ("indentSize" 2)))))
;                             ("javascript" (ht ("format" (ht ("indentSize" 2)))))))))))

;  (lsp-register-client
;   (make-lsp-client
;    :new-connection (lsp-stdio-connection '("vue-language-server" "--stdio"))
;    :activation-fn (lsp-activate-on "vue")
;    :server-id 'vue-ls
;    :priority 2
;    :initialized-fn (lambda (workspace)
;                      (with-lsp-workspace workspace
 ;                       (lsp--set-configuration
 ;                        (ht ("typescript" (ht ("tsdk" (lsp-workspace-root)))))))))))

;;;;;; Prettier formatting via apheleia
;(with-eval-after-load 'apheleia
;  (setf (alist-get 'prettier-json apheleia-formatters)
;        '("prettier" "--parser" "json" filepath))
;  (setf (alist-get 'prettier-yaml apheleia-formatters)
;        '("prettier" "--parser" "yaml" filepath)))

;;;;;; Project navigation helpers
;(defun dziman/ts-find-tsconfig ()
;  "Open the nearest tsconfig.json from the current buffer."
;  (interactive)
;  (let ((root (locate-dominating-file default-directory "tsconfig.json")))
;    (if root
;        (find-file (expand-file-name "tsconfig.json" root))
;      (message "No tsconfig.json found in project root or ancestors"))))

;(defun dziman/ts-find-package-json ()
;  "Open the nearest package.json from the current buffer."
;  (interactive)
;  (let ((root (locate-dominating-file default-directory "package.json")))
;    (if root
;        (find-file (expand-file-name "package.json" root))
;      (message "No package.json found in project root or ancestors"))))

;(defun dziman/ts-npm-run (script)
;  "Run an npm/yarn/pnpm script from the nearest package.json."
;  (interactive
;   (list (completing-read "Run script: "
;                          (dziman/--package-scripts))))
;  (let ((default-directory (or (locate-dominating-file default-directory "package.json")
;                               default-directory)))
;    (compile (format "npm run %s" script))))

;(defun dziman/--package-scripts ()
;  "Extract script names from package.json."
;  (let ((pkg (expand-file-name "package.json" default-directory)))
;    (when (file-exists-p pkg)
;      (with-temp-buffer
;        (insert-file-contents pkg)
;        (goto-char (point-min))
;        (let* ((json (json-read))
;               (scripts (cdr (assq 'scripts json))))
;          (when scripts
;            (mapcar #'car scripts)))))))

;(defun dziman/ts-find-component (component-name)
;  "Search for a Vue/React component file by name using rg."
;  (interactive
;   (list (read-string "Component name: " (thing-at-point 'symbol t))))
;  (let ((root (or default-directory)))
;    (grep (format "rg --files %s | grep -E '%s\\.(vue|tsx|ts|jsx|js)$'"
;                  root component-name))))

;(defun dziman/ts-run-vitest ()
;  "Run vitest for the current project."
;  (interactive)
;  (let ((root (or (and (fboundp 'projectile-project-root)
;                       (ignore-errors (projectile-project-root)))
;                  default-directory)))
;    (compile (format "cd %s && npx vitest run" root))))

;(defun dziman/ts-run-vitest-watch ()
;  "Run vitest in watch mode for the current project."
;  (interactive)
;  (let ((root (or (and (fboundp 'projectile-project-root)
;                       (ignore-errors (projectile-project-root)))
;                  default-directory)))
;    (compile (format "cd %s && npx vitest" root))))

;(defun dziman/ts-run-typecheck ()
;  "Run vue-tsc --noEmit (or tsc --noEmit) for the current project."
;  (interactive)
;  (let* ((root (or (and (fboundp 'projectile-project-root)
 ;                       (ignore-errors (projectile-project-root)))
;                   default-directory))
;         (cmd (cond
;               ((file-exists-p (expand-file-name "vue-tsc" (expand-file-name "node_modules/.bin" root)))
 ;               "npx vue-tsc --noEmit")
;               (t "npx tsc --noEmit"))))
;    (compile (format "cd %s && %s" root cmd))))

;;;;;; Hooks
;(defun dziman/ts-mode-setup ()
;  "Setup TypeScript/JavaScript development hooks."
;  (setq-local tab-width 2)
;  (setq-local js-indent-level 2)
;  (setq-local typescript-ts-mode-indent-offset 2)
;  (lsp-deferred))

;(add-hook 'typescript-ts-mode-hook #'dziman/ts-mode-setup)
;(add-hook 'tsx-ts-mode-hook #'dziman/ts-mode-setup)
;(add-hook 'js-ts-mode-hook #'dziman/ts-mode-setup)
;(add-hook 'vue-mode-hook #'dziman/ts-mode-setup)

;;;;;; Key bindings for TypeScript/JS/Vue development
;;(bind-keys
;; :map typescript-ts-mode-map
;; ("C-c t t" . #'dziman/ts-find-tsconfig)
;; ("C-c t p" . #'dziman/ts-find-package-json)
;; ("C-c t r" . #'dziman/ts-npm-run)
;; ("C-c t c" . #'dziman/ts-find-component)
;; ("C-c t v" . #'dziman/ts-run-vitest)
;; ("C-c t w" . #'dziman/ts-run-vitest-watch)
;; ("C-c t C" . #'dziman/ts-run-typecheck))

;;(bind-keys
;; :map tsx-ts-mode-map
;; ("C-c t t" . #'dziman/ts-find-tsconfig)
;; ("C-c t p" . #'dziman/ts-find-package-json)
;; ("C-c t r" . #'dziman/ts-npm-run)
;; ("C-c t c" . #'dziman/ts-find-component)
;; ("C-c t v" . #'dziman/ts-run-vitest)
;; ("C-c t w" . #'dziman/ts-run-vitest-watch)
;; ("C-c t C" . #'dziman/ts-run-typecheck))

;;(bind-keys
;; :map js-ts-mode-map
;; ("C-c t t" . #'dziman/ts-find-tsconfig)
;; ("C-c t p" . #'dziman/ts-find-package-json)
;; ("C-c t r" . #'dziman/ts-npm-run)
;; ("C-c t c" . #'dziman/ts-find-component)
;; ("C-c t v" . #'dziman/ts-run-vitest)
;; ("C-c t w" . #'dziman/ts-run-vitest-watch)
;; ("C-c t C" . #'dziman/ts-run-typecheck))

;;(bind-keys
;; :map vue-mode-map
;; ("C-c t t" . #'dziman/ts-find-tsconfig)
;; ("C-c t p" . #'dziman/ts-find-package-json)
;; ("C-c t r" . #'dziman/ts-npm-run)
;; ("C-c t c" . #'dziman/ts-find-component)
;; ("C-c t v" . #'dziman/ts-run-vitest)
;; ("C-c t w" . #'dziman/ts-run-vitest-watch)
;; ("C-c t C" . #'dziman/ts-run-typecheck))

;;;;;; Spacing and indentation for web modes
;(setq-default js-indent-level 2)
;(setq-default typescript-ts-mode-indent-offset 2)

(use-package web-mode
  :ensure t
  :mode "\\.vue\\'"
  :config
  (setq web-mode-enable-auto-closing t
        web-mode-enable-auto-pairing t))
(use-package eglot-typescript-preset
  :vc (:url "https://github.com/mwolson/eglot-typescript-preset"
       :main-file "eglot-typescript-preset.el"))
(setopt eglot-typescript-preset-vue-lsp-server 'vue-language-server)
;; 2. Install the multi-LSP preset package for Vue
;(use-package eglot-typescript-preset
;  :ensure t
;  :after (eglot web-mode)
                                        ;  :hook (web-mode . eglot-ensure))
(add-to-list 'eglot-server-programs
             '((vue-mode vue3-mode vue-ts-mode)
               "vue-language-server" "--stdio"
               :initializationOptions
               (:typescript (:tsdk nil)
                :vue (:hybridMode t))))

(provide 'dz-config-typescript)
