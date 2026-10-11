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
