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

;;;;;;;; Agenda files
(defmacro dziman-org-test-with-wiki (&rest body)
  "Run BODY with `dziman/org-directory' bound to a fresh wiki folder `wiki'."
  (declare (indent 0))
  `(let* ((wiki (file-name-as-directory (make-temp-file "dziman-wiki" t)))
           (dziman/org-directory wiki)
           (org-agenda-files nil))
     (unwind-protect (progn ,@body) (delete-directory wiki t))
     )
  )

(defun dziman-org-test-refresh-and-wait ()
  "Refresh the agenda folders and wait for the listing to finish."
  (let ((process (dziman/refresh-agenda-files)))
    (while (and process (process-live-p process)) (accept-process-output process 0.05))
    ;; The sentinel runs after the process exits
    (accept-process-output nil 0.05)
    )
  )

(ert-deftest dziman-org-agenda/file-added-to-a-known-folder-is-an-agenda-file ()
  (dziman-org-test-with-wiki
    (make-directory (expand-file-name "projects" wiki))
    (dziman-org-test-refresh-and-wait)
    (write-region "* Task\n" nil (expand-file-name "projects/new.org" wiki))
    (should (member (expand-file-name "projects/new.org" wiki) (org-agenda-files)))
    )
  )

(ert-deftest dziman-org-agenda/hidden-folders-are-skipped ()
  (dziman-org-test-with-wiki
    (make-directory (expand-file-name ".org-roam" wiki))
    (write-region "* Task\n" nil (expand-file-name ".org-roam/cache.org" wiki))
    (dziman-org-test-refresh-and-wait)
    (should-not (member (expand-file-name ".org-roam/cache.org" wiki) (org-agenda-files)))
    )
  )

(ert-deftest dziman-org-agenda/missing-wiki-leaves-the-agenda-files-alone ()
  (let ((dziman/org-directory "/no/such/wiki")
         (org-agenda-files '("/notes/inbox.org")))
    (dziman/refresh-agenda-files)
    (should (equal org-agenda-files '("/notes/inbox.org")))
    )
  )

(ert-deftest dziman-org-agenda/failed-listing-keeps-the-previous-folders ()
  (dziman-org-test-with-wiki
    (setq org-agenda-files '("/notes"))
    (cl-letf (((symbol-function 'dziman/agenda-folders-command) (lambda (_root) '("false"))))
      (dziman-org-test-refresh-and-wait)
      )
    (should (equal org-agenda-files '("/notes")))
    )
  )

(ert-deftest dziman-org-agenda/listing-uses-fd-when-installed ()
  (cl-letf (((symbol-function 'executable-find) (lambda (name &rest _) (and (equal name "fd") "/opt/homebrew/bin/fd"))))
    (should (equal (car (dziman/agenda-folders-command "/wiki/")) "/opt/homebrew/bin/fd"))
    )
  )

(ert-deftest dziman-org-agenda/listing-falls-back-to-find-without-fd ()
  (cl-letf (((symbol-function 'executable-find) (lambda (_name &rest _) nil)))
    (should (equal (car (dziman/agenda-folders-command "/wiki/")) "find"))
    )
  )

(ert-deftest dziman-org-agenda/find-listing-skips-hidden-folders ()
  (dziman-org-test-with-wiki
    (make-directory (expand-file-name "projects" wiki))
    (make-directory (expand-file-name ".git" wiki))
    (cl-letf (((symbol-function 'executable-find) (lambda (_name &rest _) nil)))
      (dziman-org-test-refresh-and-wait)
      )
    (should (equal org-agenda-files (list (directory-file-name wiki) (expand-file-name "projects" wiki))))
    )
  )

(ert-deftest dziman-org-agenda/folder-listing-includes-the-wiki-itself ()
  (should (equal (dziman/agenda-folders-from-output "/wiki/" "/wiki/b/\n/wiki/a/\n")
            '("/wiki" "/wiki/a" "/wiki/b")))
  )

(ert-deftest dziman-org-agenda/opening-an-org-file-does-not-rescan ()
  (should-not (memq 'dziman/refresh-agenda-files org-mode-hook))
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

(ert-deftest dziman-org-hydra/link-view-toggle-shows-whether-links-are-rendered ()
  (let ((hint (symbol-value 'major-mode-hydras/org-mode/hint)))
    (should-not (equal (let ((org-link-descriptive t)) (eval hint t))
                  (let ((org-link-descriptive nil)) (eval hint t))))
    )
  )

(provide 'dz-config-org-test)
