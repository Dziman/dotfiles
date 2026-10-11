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
;; Comments and strings only: checking code itself flags every language keyword
(add-hook 'prog-mode-hook 'flyspell-prog-mode)

(defvar dziman/aspell-personal-dictionary (expand-file-name "aspell.en.pws" dziman/settings-base-dir)
  "Aspell word list kept with these settings, so every machine accepts the same words.")

(defun dziman/spell-aspell-setup ()
  "Use the shared word list and split camelCase words when the spell checker is aspell."
  ;; ispell and hunspell reject --camel-case and read a different word-list format
  (when (string-match-p "aspell" (file-name-nondirectory ispell-program-name))
    (setq ispell-personal-dictionary dziman/aspell-personal-dictionary)
    (add-to-list 'ispell-extra-args "--camel-case")
    )
  )

(with-eval-after-load 'ispell
  (dziman/spell-aspell-setup)
  )

(eval-after-load "flyspell"
  '(define-key flyspell-mode-map (kbd "C-.") nil)) ;; Remove conflicting keybinding. See `dz-config-hydra`

;; TODO Slightly conflicting with `git-gutter`. Reconfigure for better UI
(setq-default flycheck-indication-mode 'left-margin)

(provide 'dz-config-fly)
