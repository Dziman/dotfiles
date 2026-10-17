;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; ERT tests for dz-config-git-pr. Run from the repo root:
;;;;;;   emacs --batch -f package-initialize -L .emacs-dziman/configs -L .emacs-dziman/tests \
;;;;;;     -l dz-config-git-pr-test -f ert-run-tests-batch-and-exit
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'ert)
(require 'dz-git-test-fixtures)
(require 'dz-config-git-pr)

(defmacro dziman-git-test-with-cli (handler &rest body)
  "Run BODY with forge CLI and network calls answered by HANDLER.
HANDLER gets the program and its argument list. `gh' and `fj' count as installed."
  `(cl-letf (((symbol-function 'dziman/git-pr--run) (lambda (program &rest args) (funcall ,handler program args)))
             ((symbol-function 'executable-find) (lambda (name &rest _) (and (member name '("gh" "fj")) name))))
     (setq dziman/git-pr--fj-hosts-cache nil)
     ,@body
     )
  )

(defun dziman-git-test-no-network (program args)
  (ert-fail (list "network used" program args))
  )

(defun dziman-git-test-pull-heads (&rest numbers-and-shas)
  "A handler answering `git ls-remote' with pull request heads NUMBER SHA ..."
  (lambda (program _args)
    (unless (equal program "git") (user-error "%s failed: not installed" program))
    (mapconcat (lambda (pair) (format "%s\trefs/pull/%d/head\n" (cadr pair) (car pair)))
      (seq-partition numbers-and-shas 2) "")
    )
  )

;;;;;;;; PR number in a commit subject
(ert-deftest dziman-git-pr-subject/squash-subject-names-pr ()
  (should (eql (dziman/git-pr-number-in-subject "Fix login (#42)") 42))
  )

(ert-deftest dziman-git-pr-subject/github-merge-subject ()
  (should (eql (dziman/git-pr-number-in-subject "Merge pull request #42 from me/fix") 42))
  )

(ert-deftest dziman-git-pr-subject/forgejo-merge-subject ()
  (should (eql (dziman/git-pr-number-in-subject "Merge pull request 'Fix login' (#42) from fix into main") 42))
  )

(ert-deftest dziman-git-pr-subject/plain-subject-names-none ()
  (should-not (dziman/git-pr-number-in-subject "Fix login"))
  )

;;;;;;;; Which CLI serves a host
(ert-deftest dziman-git-pr-host/github-needs-gh-installed ()
  (cl-letf (((symbol-function 'executable-find) (lambda (_name &rest _) nil)))
    (should-not (dziman/git-pr-host-tool "github.com"))
    )
  )

(ert-deftest dziman-git-pr-host/forgejo-host-is-one-fj-is-logged-into ()
  (dziman-git-test-with-cli (lambda (_program _args) "git.example.org\n")
    (should (eq (dziman/git-pr-host-tool "git.example.org") 'fj))
    )
  )

(ert-deftest dziman-git-pr-host/unknown-host-has-no-tool ()
  (dziman-git-test-with-cli (lambda (_program _args) "git.example.org\n")
    (should-not (dziman/git-pr-host-tool "gitlab.com"))
    )
  )

(ert-deftest dziman-git-pr-host/logged-out-fj-serves-no-host ()
  (dziman-git-test-with-cli (lambda (program _args) (user-error "%s failed: not logged in" program))
    (should-not (dziman/git-pr-host-tool "git.example.org"))
    )
  )

(ert-deftest dziman-git-pr-host/new-fj-login-is-seen-without-restart ()
  (dziman-git-test-with-cli (lambda (_program _args) "a.example.org\nb.example.org\n")
    (setq dziman/git-pr--fj-hosts-cache '("a.example.org"))
    (should (eq (dziman/git-pr-host-tool "b.example.org") 'fj))
    )
  )

;;;;;;;; Finding the PR of a commit
(ert-deftest dziman-git-pr-find/squash-commit-found-without-network ()
  (dziman-git-test-with-repo
    (let ((commit (dziman-git-test-commit "b.txt" "b\n" "Fix (#5)")))
      (dziman-git-test-with-cli #'dziman-git-test-no-network
        (should (eql (dziman/git-pr-find commit "origin") 5))
        )
      )
    )
  )

(ert-deftest dziman-git-pr-find/merge-commit-found-without-network ()
  (dziman-git-test-with-repo
    (dziman-git-test-git "switch" "-q" "-c" "feature")
    (let ((commit (dziman-git-test-commit "b.txt" "b\n" "Add b")))
      (dziman-git-test-git "switch" "-q" "main")
      (dziman-git-test-git "merge" "-q" "--no-ff" "-m" "Merge pull request #7 from me/feature" "feature")
      (dziman-git-test-with-cli #'dziman-git-test-no-network
        (should (eql (dziman/git-pr-find commit "origin") 7))
        )
      )
    )
  )

(ert-deftest dziman-git-pr-find/github-asks-gh ()
  (dziman-git-test-with-repo
    (dziman-git-test-fake-remote "origin" "git@github.com:me/repo.git")
    (let ((commit (dziman-git-test-commit "b.txt" "b\n" "Add b")))
      (dziman-git-test-with-cli (lambda (program _args) (if (equal program "gh") "9\n" (user-error "unexpected")))
        (should (eql (dziman/git-pr-find commit "origin") 9))
        )
      )
    )
  )

(ert-deftest dziman-git-pr-find/fast-forward-pr-found-from-pull-heads ()
  (dziman-git-test-with-repo
    (dziman-git-test-fake-remote "origin" "ssh://git@git.example.org/me/repo.git")
    (let* ((first (dziman-git-test-commit "b.txt" "b\n" "Add b"))
           (second (dziman-git-test-commit "c.txt" "c\n" "Add c")))
      (dziman-git-test-with-cli (dziman-git-test-pull-heads 3 first 4 second)
        (should (eql (dziman/git-pr-find first "origin") 3))
        )
      )
    )
  )

(ert-deftest dziman-git-pr-find/later-pr-does-not-claim-earlier-commit ()
  (dziman-git-test-with-repo
    (dziman-git-test-fake-remote "origin" "ssh://git@git.example.org/me/repo.git")
    (let* ((first (dziman-git-test-commit "b.txt" "b\n" "Add b"))
           (second (dziman-git-test-commit "c.txt" "c\n" "Add c")))
      (dziman-git-test-with-cli (dziman-git-test-pull-heads 3 first 4 second)
        (should (eql (dziman/git-pr-find second "origin") 4))
        )
      )
    )
  )

(ert-deftest dziman-git-pr-find/pull-head-not-fetched-is-skipped ()
  (dziman-git-test-with-repo
    (dziman-git-test-fake-remote "origin" "ssh://git@git.example.org/me/repo.git")
    (let ((commit (dziman-git-test-commit "b.txt" "b\n" "Add b")))
      (dziman-git-test-with-cli (dziman-git-test-pull-heads 3 "0123456789abcdef0123456789abcdef01234567")
        (should-not (dziman/git-pr-find commit "origin"))
        )
      )
    )
  )

(ert-deftest dziman-git-pr-find/github-answer-is-final ()
  (dziman-git-test-with-repo
    (dziman-git-test-fake-remote "origin" "git@github.com:me/repo.git")
    (let ((commit (dziman-git-test-commit "b.txt" "b\n" "Add b")))
      (dziman-git-test-with-cli (lambda (program args) (if (equal program "gh") "" (dziman-git-test-no-network program args)))
        (should-not (dziman/git-pr-find commit "origin"))
        )
      )
    )
  )

(ert-deftest dziman-git-pr-find/offline-falls-back-to-no-pr ()
  (dziman-git-test-with-repo
    (dziman-git-test-fake-remote "origin" "ssh://git@git.example.org/me/repo.git")
    (let ((commit (dziman-git-test-commit "b.txt" "b\n" "Add b")))
      (dziman-git-test-with-cli (lambda (_program _args) (user-error "git failed: Could not resolve host"))
        (should-not (dziman/git-pr-find commit "origin"))
        )
      )
    )
  )

;;;;;;;; PR links
(ert-deftest dziman-git-pr-url/github-link ()
  (should (equal (dziman/git-pr-url "github.com" "me/repo" 42) "https://github.com/me/repo/pull/42"))
  )

(ert-deftest dziman-git-pr-url/forgejo-link ()
  (should (equal (dziman/git-pr-url "git.example.org" "me/repo" 42) "https://git.example.org/me/repo/pulls/42"))
  )

;;;;;;;; Commit of the current line
(defun dziman-git-test-b-txt-commit ()
  "Commit b.txt holding lines x and y; return the commit id."
  (dziman-git-test-commit "b.txt" "x\ny\n" "Add b")
  )

(ert-deftest dziman-git-pr-line/committed-line-gives-its-commit ()
  (dziman-git-test-with-repo
    (let ((commit (dziman-git-test-b-txt-commit)))
      (with-current-buffer (find-file-noselect (expand-file-name "b.txt"))
        (goto-char (point-min))
        (forward-line 1)
        (should (equal (dziman/git-pr--line-commit) commit))
        )
      )
    )
  )

(ert-deftest dziman-git-pr-line/new-line-has-no-commit ()
  (dziman-git-test-with-repo
    (dziman-git-test-b-txt-commit)
    (with-current-buffer (find-file-noselect (expand-file-name "b.txt"))
      (goto-char (point-min))
      (insert "z\n")
      (goto-char (point-min))
      (should-not (dziman/git-pr--line-commit))
      )
    )
  )

(ert-deftest dziman-git-pr-line/unsaved-edits-above-keep-the-right-commit ()
  (dziman-git-test-with-repo
    (let ((commit (dziman-git-test-b-txt-commit)))
      (with-current-buffer (find-file-noselect (expand-file-name "b.txt"))
        (goto-char (point-min))
        (insert "new 1\nnew 2\n")
        (search-forward "y")
        (should (equal (dziman/git-pr--line-commit) commit))
        )
      )
    )
  )

;;;;;;;; PR key and the one-key choice
(defconst dziman-git-test-sha "0123456789abcdef0123456789abcdef01234567")

(defconst dziman-git-test-scope
  '(:tool fj :root "/tmp/repo/" :host "git.example.org" :repo-path "me/repo" :remote "origin"
     :number 3 :url "https://git.example.org/me/repo/pulls/3"))

(defmacro dziman-git-test-on-a-txt-of-forgejo-repo (&rest body)
  "Run BODY in a.txt of a repo whose origin is a Forgejo host fj is logged into,
with the menu context set from that buffer."
  `(dziman-git-test-with-repo
     (dziman-git-test-fake-remote "origin" "ssh://git@git.example.org/me/repo.git")
     (dziman-git-test-with-cli (lambda (_program _args) "git.example.org\n")
       (with-current-buffer (find-file-noselect (expand-file-name "a.txt"))
         (setq dziman/git--context (dziman/git-context))
         ,@body
         )
       )
     )
  )

(ert-deftest dziman-git-pr-at-line/found-pr-opens-the-choice ()
  (dziman-git-test-on-a-txt-of-forgejo-repo
    (let (scope)
      (cl-letf (((symbol-function 'dziman/git-pr--line-commit) (lambda () dziman-git-test-sha))
                ((symbol-function 'dziman/git-pr-find) (lambda (_sha _remote) 3))
                ((symbol-function 'transient-setup) (lambda (&rest args) (setq scope (plist-get (cdddr args) :scope)))))
        (dziman/git-pr-at-line)
        )
      (should (equal (plist-get scope :url) "https://git.example.org/me/repo/pulls/3"))
      )
    )
  )

(ert-deftest dziman-git-pr-at-line/no-pr-offers-the-commit ()
  (dziman-git-test-on-a-txt-of-forgejo-repo
    (let (shown)
      (cl-letf (((symbol-function 'dziman/git-pr--line-commit) (lambda () dziman-git-test-sha))
                ((symbol-function 'dziman/git-pr-find) (lambda (_sha _remote) nil))
                ((symbol-function 'y-or-n-p) (lambda (_prompt) t))
                ((symbol-function 'magit-show-commit) (lambda (sha &rest _) (setq shown sha))))
        (dziman/git-pr-at-line)
        )
      (should (equal shown dziman-git-test-sha))
      )
    )
  )

(ert-deftest dziman-git-pr-at-line/uncommitted-line-says-so ()
  (dziman-git-test-on-a-txt-of-forgejo-repo
    (cl-letf (((symbol-function 'dziman/git-pr--line-commit) (lambda () nil)))
      (should-error (dziman/git-pr-at-line) :type 'user-error)
      )
    )
  )

(ert-deftest dziman-git-pr-at-line/offline-lookup-says-what-was-skipped ()
  (dziman-git-test-with-repo
    (dziman-git-test-fake-remote "origin" "ssh://git@git.example.org/me/repo.git")
    (let (prompt)
      (cl-letf (((symbol-function 'dziman/git-pr--run)
                  (lambda (program &rest args)
                    (if (equal args '("auth" "list")) "git.example.org\n" (user-error "%s failed: Could not resolve host" program))))
                ((symbol-function 'executable-find) (lambda (name &rest _) name))
                ((symbol-function 'y-or-n-p) (lambda (question) (setq prompt question) nil)))
        (setq dziman/git-pr--fj-hosts-cache nil)
        (with-current-buffer (find-file-noselect (expand-file-name "a.txt"))
          (setq dziman/git--context (dziman/git-context))
          (dziman/git-pr-at-line)
          )
        )
      (should (string-match-p "Could not resolve host" (or prompt "")))
      )
    )
  )

(ert-deftest dziman-git-pr-choice/link-outside-the-pr-menu-says-so ()
  (cl-letf (((symbol-function 'transient-scope) (lambda (&rest _) nil)))
    (should-error (dziman/git-pr-copy-link) :type 'user-error)
    )
  )

(ert-deftest dziman-git-pr-choice/link-is-copied ()
  (cl-letf (((symbol-function 'transient-scope) (lambda (&rest _) dziman-git-test-scope)))
    (dziman/git-pr-copy-link)
    )
  (should (equal (car kill-ring) "https://git.example.org/me/repo/pulls/3"))
  )

(ert-deftest dziman-git-pr-choice/browser-gets-the-link ()
  (let (opened)
    (cl-letf (((symbol-function 'transient-scope) (lambda (&rest _) dziman-git-test-scope))
              ((symbol-function 'browse-url) (lambda (url &rest _) (setq opened url))))
      (dziman/git-pr-browse)
      )
    (should (equal opened "https://git.example.org/me/repo/pulls/3"))
    )
  )

(ert-deftest dziman-git-pr-choice/emacs-shows-the-pr-view ()
  (let (viewed)
    (cl-letf (((symbol-function 'transient-scope) (lambda (&rest _) dziman-git-test-scope))
              ((symbol-function 'dziman/git-pr-view) (lambda (scope) (setq viewed scope))))
      (dziman/git-pr-show)
      )
    (should (equal viewed dziman-git-test-scope))
    )
  )

(ert-deftest dziman-git-pr-choice/keys-are-link-browser-and-emacs ()
  (dolist (binding '(("l" . dziman/git-pr-copy-link) ("b" . dziman/git-pr-browse) ("e" . dziman/git-pr-show)))
    (should (eq (plist-get (cdr (ignore-errors (transient-get-suffix 'dziman/git-pr-choice (car binding)))) :command)
              (cdr binding)))
    )
  )

(ert-deftest dziman-git-pr-available/directory-listing-has-no-pr-key ()
  (dziman-git-test-with-repo
    (dziman-git-test-fake-remote "origin" "ssh://git@git.example.org/me/repo.git")
    (dziman-git-test-with-cli (lambda (_program _args) "git.example.org\n")
      (with-current-buffer (dired-noselect default-directory)
        (dired-goto-file (expand-file-name "a.txt"))
        (setq dziman/git--context (dziman/git-context))
        (should-not (dziman/git-pr-available-p))
        )
      )
    )
  )

(ert-deftest dziman-git-pr-available/visited-file-on-forgejo-has-pr-key ()
  (dziman-git-test-on-a-txt-of-forgejo-repo
    (should (dziman/git-pr-available-p))
    )
  )

(ert-deftest dziman-git-pr-line/narrowed-buffer-blames-the-right-line ()
  (dziman-git-test-with-repo
    (dziman-git-test-b-txt-commit)
    (with-current-buffer (find-file-noselect (expand-file-name "b.txt"))
      (goto-char (point-max))
      (insert "z\n")
      (forward-line -1)
      (narrow-to-region (line-beginning-position) (point-max))
      (should-not (dziman/git-pr--line-commit))
      )
    )
  )

(ert-deftest dziman-git-pr-line/windows-line-endings-keep-the-commit ()
  (dziman-git-test-with-repo
    (let ((coding-system-for-write 'no-conversion))
      (with-temp-file "w.txt" (insert "x\r\ny\r\n"))
      )
    (let ((commit (progn (dziman-git-test-git "add" "w.txt")
                    (dziman-git-test-git "commit" "-q" "-m" "Add w")
                    (dziman-git-test-git "rev-parse" "HEAD"))))
      (with-current-buffer (find-file-noselect (expand-file-name "w.txt"))
        (goto-char (point-min))
        (forward-line 1)
        (should (equal (dziman/git-pr--line-commit) commit))
        )
      )
    )
  )

(provide 'dz-config-git-pr-test)
