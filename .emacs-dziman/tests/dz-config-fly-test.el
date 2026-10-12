;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; ERT tests for dz-config-fly. Run from the repo root:
;;;;;;   emacs --batch -f package-initialize -L .emacs-dziman/configs -L .emacs-dziman/tests \
;;;;;;     -l dz-config-fly-test -f ert-run-tests-batch-and-exit
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'ert)
(require 'cl-lib)
(require 'ispell)
(require 'flyspell)

;; Set by ~/.emacs before any config loads
(defvar dziman/settings-base-dir (expand-file-name ".emacs-dziman"))

(require 'dz-config-fly)

(defun dziman-fly-test-aspell-misspellings (text)
  "Words in TEXT that aspell, run with the configured arguments and word list, reports as misspelled."
  (with-temp-buffer
    (insert text)
    (apply #'call-process-region (point-min) (point-max) ispell-program-name t t nil
      "list" "-p" ispell-personal-dictionary ispell-extra-args)
    (split-string (buffer-string) "\n" t)
    )
  )

;;;;;;;; Spelling in text and code
(ert-deftest dziman-fly-spelling/check-word-key-opens-suggestions-in-flyspell-buffers ()
  ;; Read the keymap: turning flyspell-mode on needs a spell checker, which this test must not need
  (should (eq (lookup-key flyspell-mode-map [remap ispell-word]) 'flyspell-correct-wrapper))
  )

(ert-deftest dziman-fly-spelling/code-buffers-check-comments-and-strings ()
  (should (memq 'flyspell-prog-mode prog-mode-hook))
  )

(ert-deftest dziman-fly-spelling/aspell-flags-typos-but-not-camel-case-names-or-jargon ()
  (skip-unless (executable-find "aspell"))
  (let ((ispell-program-name (executable-find "aspell"))
        (ispell-extra-args nil)
        (ispell-personal-dictionary nil))
    (dziman/spell-aspell-setup)
    (should (equal (dziman-fly-test-aspell-misspellings "a mispeled note on parseAccountBalance in emacs\n")
              '("mispeled")))
    )
  )

;;;;;;;; Spelling in a mode's own comment and string faces
(defface dziman-fly-test-comment-face '((t :inherit font-lock-comment-face))
  "Comment face of a mode that names its own faces.")

(defface dziman-fly-test-doc-face '((t :inherit dziman-fly-test-comment-face))
  "Face two steps away from the comment face.")

(defface dziman-fly-test-string-face '((t :inherit (bold font-lock-string-face)))
  "Face inheriting from several faces, one of them the string face.")

(defun dziman-fly-test-spell-checked-p (face)
  "Whether spell checking in a code buffer looks at a word painted with FACE."
  (with-temp-buffer
    (let ((prog-mode-hook nil)) (prog-mode))
    (dziman/spell-prog-text-faces-setup)
    (insert (propertize "mispeled" 'face face))
    (goto-char (point-min))
    (flyspell-generic-progmode-verify)
    )
  )

(ert-deftest dziman-fly-faces/standard-comment-face-is-checked ()
  (should (dziman-fly-test-spell-checked-p 'font-lock-comment-face))
  )

(ert-deftest dziman-fly-faces/mode-comment-face-is-checked ()
  (should (dziman-fly-test-spell-checked-p 'dziman-fly-test-comment-face))
  )

(ert-deftest dziman-fly-faces/face-inheriting-through-another-face-is-checked ()
  (should (dziman-fly-test-spell-checked-p 'dziman-fly-test-doc-face))
  )

(ert-deftest dziman-fly-faces/face-inheriting-from-several-faces-is-checked ()
  (should (dziman-fly-test-spell-checked-p 'dziman-fly-test-string-face))
  )

(defface dziman-fly-test-regexp-face '((t :inherit font-lock-string-face))
  "Regex literal face, painted like a string.")

(ert-deftest dziman-fly-faces/regex-literals-are-not-checked ()
  ;; Character classes like [a-z] are not words
  (should-not (dziman-fly-test-spell-checked-p 'dziman-fly-test-regexp-face))
  )

(ert-deftest dziman-fly-faces/code-face-is-not-checked ()
  (should-not (dziman-fly-test-spell-checked-p 'font-lock-keyword-face))
  )

(ert-deftest dziman-fly-faces/code-buffers-set-up-the-faces ()
  (should (memq 'dziman/spell-prog-text-faces-setup prog-mode-hook))
  )

(ert-deftest dziman-fly-faces/swift-comments-are-checked ()
  ;; A real mode that paints comments with its own face
  (skip-unless (require 'swift-mode nil t))
  (with-temp-buffer
    (let ((swift-mode-hook nil)) (swift-mode))
    (dziman/spell-prog-text-faces-setup)
    (insert "// a mispeled note\n")
    (font-lock-ensure)
    (goto-char (point-min))
    (search-forward "mispel")
    (should (flyspell-generic-progmode-verify))
    )
  )

;;;;;;;; Aspell settings
(ert-deftest dziman-fly-aspell/aspell-splits-camel-case-and-uses-the-shared-word-list ()
  (let ((ispell-program-name "/opt/homebrew/bin/aspell")
        (ispell-extra-args nil)
        (ispell-personal-dictionary nil))
    (dziman/spell-aspell-setup)
    (should (member "--camel-case" ispell-extra-args))
    (should (equal ispell-personal-dictionary (expand-file-name "aspell.en.pws" dziman/settings-base-dir)))
    )
  )

(ert-deftest dziman-fly-aspell/other-spell-checkers-keep-their-defaults ()
  ;; ispell and hunspell reject --camel-case and read a different word-list format
  (let ((ispell-program-name "/usr/bin/ispell")
        (ispell-extra-args nil)
        (ispell-personal-dictionary nil))
    (dziman/spell-aspell-setup)
    (should-not ispell-extra-args)
    (should-not ispell-personal-dictionary)
    )
  )

(ert-deftest dziman-fly-aspell/shared-word-list-knows-config-jargon ()
  ;; The rule lives in the word list: jargon common in these configs is accepted
  (let ((words (with-temp-buffer
                 (insert-file-contents (expand-file-name "aspell.en.pws" dziman/settings-base-dir))
                 (cdr (split-string (buffer-string) "\n" t)))))
    (dolist (word '("emacs" "elisp" "todo" "fixme" "configs" "alist" "flycheck" "smartparens" "whitespace"))
      (should (member word words))
      )
    )
  )

(provide 'dz-config-fly-test)
