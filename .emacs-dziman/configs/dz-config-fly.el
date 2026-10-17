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

(defun dziman/spell-face-inherits-p (face targets)
  "Whether FACE is one of TARGETS or inherits from one of them.
The inheritance may go through other faces."
  (or (memq face targets)
    (seq-some (lambda (parent) (and (facep parent) (dziman/spell-face-inherits-p parent targets)))
      (ensure-list (face-attribute face :inherit)))
    )
  )

(defun dziman/spell-prog-text-faces-setup ()
  "Also spell-check faces a mode derives from the comment, doc and string faces."
  ;; `flyspell-prog-mode' checks only the exact faces listed, so a mode's own
  ;; comment face (e.g. `swift-mode:comment-face') would go unchecked
  (require 'flyspell)
  (let ((base-faces (default-value 'flyspell-prog-text-faces)))
    (setq-local flyspell-prog-text-faces
      (seq-filter (lambda (face)
                    ;; Regex literal faces inherit the string face, but hold no words
                    (and (not (string-match-p "regex" (symbol-name face)))
                      (dziman/spell-face-inherits-p face base-faces)))
        (face-list)))
    )
  )

(add-hook 'prog-mode-hook 'dziman/spell-prog-text-faces-setup)

(defvar dziman/aspell-personal-dictionary (expand-file-name "aspell.en.pws" dziman/settings-base-dir)
  "Aspell word list kept with these settings.
Every machine then accepts the same words.")

(defun dziman/spell-aspell-setup ()
  "Use the shared word list and split camelCase words.
Applies only when the spell checker is aspell."
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
(eval-after-load "flyspell"
  '(define-key flyspell-mode-map (kbd "C-;") nil)) ;; Remove conflicting keybinding. See `dz-config-vertico`

;; The left margin belongs to `git-gutter`
(setq-default flycheck-indication-mode 'right-fringe)

(provide 'dz-config-fly)
