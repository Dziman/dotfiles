;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; ERT tests for dz-config-org. Run from the repo root:
;;;;;;   emacs --batch -f package-initialize -L .emacs-dziman/configs -L .emacs-dziman/tests \
;;;;;;     -l dz-config-org-test -f ert-run-tests-batch-and-exit
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'ert)
(require 'cl-lib)
(require 'dz-config-icons)
(require 'dz-config-bind-maps)
(require 'dz-config-hydra)
(require 'dz-config-org)
;; Loaded up front so `org-mode-hook' is special when tests let-bind it
(require 'org)

(defconst dziman-org-test-outline
  "* Projects\n** Emacs\n*** Swift\nNotes here\n** Other\n* Inbox\n"
  "Outline whose third-level heading has two ancestors.")

(defmacro dziman-org-test-at (text &rest body)
  "Run BODY in an org buffer holding the outline, with point at the line matching TEXT."
  (declare (indent 1))
  `(with-temp-buffer
     (let ((org-mode-hook nil)) (org-mode))
     (insert dziman-org-test-outline)
     (goto-char (point-min))
     (re-search-forward (regexp-quote ,text))
     (beginning-of-line)
     ,@body
     )
  )

;;;;;;;; Parent headings
(ert-deftest dziman-org-parents/nested-heading-lists-its-ancestors-nearest-first ()
  (dziman-org-test-at "Notes here"
    (should (equal (mapcar #'car (dziman/org-parent-headings)) '("** Emacs" "* Projects")))
    )
  )

(ert-deftest dziman-org-parents/top-level-heading-has-no-parents ()
  (dziman-org-test-at "* Inbox"
    (should-not (dziman/org-parent-headings))
    )
  )

(ert-deftest dziman-org-parents/text-before-the-first-heading-has-no-parents ()
  (with-temp-buffer
    (let ((org-mode-hook nil)) (org-mode))
    (insert "Preamble\n" dziman-org-test-outline)
    (goto-char (point-min))
    (should-not (dziman/org-parent-headings))
    )
  )

(ert-deftest dziman-org-parents/picked-parent-is-where-point-lands ()
  (dziman-org-test-at "*** Swift"
    (cl-letf (((symbol-function 'completing-read) (lambda (&rest _) "* Projects")))
      (dziman/org-jump-to-parent-heading)
      )
    (should (looking-at-p (regexp-quote "* Projects")))
    )
  )

(ert-deftest dziman-org-parents/jump-without-parents-is-refused ()
  (dziman-org-test-at "* Inbox"
    (should-error (dziman/org-jump-to-parent-heading) :type 'user-error)
    )
  )

;;;;;;;; Org hydra
(ert-deftest dziman-org-hydra/browse-keys-run-existing-commands ()
  (dolist (key '("b a" "b b" "b p"))
    (let ((command (cadr (assoc key (symbol-value 'major-mode-hydras/org-mode/heads)))))
      (should (and command (fboundp command)))
      )
    )
  )

(provide 'dz-config-org-test)
