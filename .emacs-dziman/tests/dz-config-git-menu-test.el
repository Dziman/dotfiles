;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; ERT tests for dz-config-git-menu. Run from the repo root:
;;;;;;   emacs --batch -f package-initialize -L .emacs-dziman/configs -L .emacs-dziman/tests \
;;;;;;     -l dz-config-git-menu-test -f ert-run-tests-batch-and-exit
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'ert)
(require 'dz-git-test-fixtures)
(require 'dz-config-git-menu)

(defun dziman-git-test-context-of (file)
  "The git context of a buffer visiting FILE, relative to `default-directory'."
  (with-current-buffer (find-file-noselect (expand-file-name file))
    (dziman/git-context)
    )
  )

(defun dziman-git-test-dired-context-on (file)
  "The git context of a dired buffer on `default-directory' with the cursor on FILE."
  (with-current-buffer (dired-noselect default-directory)
    (dired-goto-file (expand-file-name file))
    (dziman/git-context)
    )
  )

(defun dziman-git-test-conflict-on-a-txt ()
  "Make `main' and branch `other' change a.txt differently, then merge `other' into `main'."
  (dziman-git-test-git "switch" "-q" "-c" "other")
  (dziman-git-test-commit "a.txt" "theirs\n" "Theirs")
  (dziman-git-test-git "switch" "-q" "main")
  (dziman-git-test-commit "a.txt" "mine\n" "Mine")
  (dziman-git-test-git-status "merge" "other")
  )

;;;;;;;; Remote URLs
(ert-deftest dziman-git-remote/ssh-url-with-port ()
  (should (equal (dziman/git-remote-host-and-path "ssh://git@git.example.org:2222/me/repo.git")
            '("git.example.org" . "me/repo")))
  )

(ert-deftest dziman-git-remote/scp-style-url ()
  (should (equal (dziman/git-remote-host-and-path "git@github.com:me/repo.git")
            '("github.com" . "me/repo")))
  )

(ert-deftest dziman-git-remote/https-url ()
  (should (equal (dziman/git-remote-host-and-path "https://github.com/me/repo")
            '("github.com" . "me/repo")))
  )

(ert-deftest dziman-git-remote/local-path-has-no-host ()
  (should-not (dziman/git-remote-host-and-path "/tmp/repo.git"))
  )

;;;;;;;; Default branch
(ert-deftest dziman-git-default-branch/remote-default-wins-over-local-names ()
  (dziman-git-test-with-repo
    (dziman-git-test-fake-remote "origin" "ssh://git@git.example.org/me/repo.git" "develop")
    (should (equal (dziman/git-default-branch) "origin/develop"))
    )
  )

(ert-deftest dziman-git-default-branch/push-remote-chosen-before-upstream-and-origin ()
  (dziman-git-test-with-repo
    (dziman-git-test-fake-remote "origin" "ssh://git@git.example.org/me/repo.git")
    (dziman-git-test-fake-remote "upstream" "ssh://git@git.example.org/them/repo.git")
    (dziman-git-test-fake-remote "fork" "ssh://git@git.example.org/fork/repo.git")
    (dziman-git-test-git "config" "branch.main.pushRemote" "fork")
    (should (equal (dziman/git-default-remote) "fork"))
    )
  )

(ert-deftest dziman-git-default-branch/upstream-chosen-before-origin ()
  (dziman-git-test-with-repo
    (dziman-git-test-fake-remote "origin" "ssh://git@git.example.org/me/repo.git")
    (dziman-git-test-fake-remote "upstream" "ssh://git@git.example.org/them/repo.git")
    (should (equal (dziman/git-default-remote) "upstream"))
    )
  )

(ert-deftest dziman-git-default-branch/no-remote-default-falls-back-to-develop ()
  (dziman-git-test-with-repo
    (dziman-git-test-git "branch" "develop")
    (should (equal (dziman/git-default-branch) "develop"))
    )
  )

(ert-deftest dziman-git-default-branch/no-known-branch-gives-none ()
  (dziman-git-test-with-repo
    (dziman-git-test-git "branch" "-m" "main" "trunk")
    (should-not (dziman/git-default-branch))
    )
  )

;;;;;;;; Context
(ert-deftest dziman-git-context/outside-repo-has-no-repo ()
  (dziman-git-test-with-dir
    (with-temp-buffer
      (should-not (plist-get (dziman/git-context) :repo))
      )
    )
  )

(ert-deftest dziman-git-context/file-buffer-gives-its-file ()
  (dziman-git-test-with-repo
    (let ((context (dziman-git-test-context-of "a.txt")))
      (should (equal (plist-get context :file) (expand-file-name "a.txt")))
      (should (plist-get context :file-buffer))
      (should (plist-get context :tracked))
      )
    )
  )

(ert-deftest dziman-git-context/dired-gives-the-file-under-cursor ()
  (dziman-git-test-with-repo
    (let ((context (dziman-git-test-dired-context-on "a.txt")))
      (should (equal (plist-get context :file) (expand-file-name "a.txt")))
      (should-not (plist-get context :file-buffer))
      )
    )
  )

(ert-deftest dziman-git-context/dired-on-a-directory-gives-no-file ()
  (dziman-git-test-with-repo
    (make-directory "sub")
    (should-not (plist-get (dziman-git-test-dired-context-on "sub") :file))
    )
  )

(ert-deftest dziman-git-context/new-file-is-untracked ()
  (dziman-git-test-with-repo
    (with-temp-file "b.txt" (insert "new\n"))
    (let ((context (dziman-git-test-context-of "b.txt")))
      (should (plist-get context :untracked))
      (should-not (plist-get context :tracked))
      )
    )
  )

(ert-deftest dziman-git-context/unchanged-file-has-nothing-to-stage ()
  (dziman-git-test-with-repo
    (let ((context (dziman-git-test-context-of "a.txt")))
      (should-not (plist-get context :unstaged))
      (should-not (plist-get context :staged))
      )
    )
  )

(ert-deftest dziman-git-context/edited-file-has-unstaged-changes ()
  (dziman-git-test-with-repo
    (with-temp-file "a.txt" (insert "two\n"))
    (should (plist-get (dziman-git-test-context-of "a.txt") :unstaged))
    )
  )

(ert-deftest dziman-git-context/staged-file-has-staged-changes ()
  (dziman-git-test-with-repo
    (with-temp-file "a.txt" (insert "two\n"))
    (dziman-git-test-git "add" "a.txt")
    (let ((context (dziman-git-test-context-of "a.txt")))
      (should (plist-get context :staged))
      (should (plist-get context :staged-any))
      )
    )
  )

(ert-deftest dziman-git-context/conflicted-file-is-flagged ()
  (dziman-git-test-with-repo
    (dziman-git-test-conflict-on-a-txt)
    (should (plist-get (dziman-git-test-context-of "a.txt") :conflicted))
    )
  )

(ert-deftest dziman-git-context/stash-is-seen ()
  (dziman-git-test-with-repo
    (with-temp-file "a.txt" (insert "two\n"))
    (dziman-git-test-git "stash" "-q")
    (should (plist-get (dziman-git-test-context-of "a.txt") :stash))
    )
  )

(ert-deftest dziman-git-context/feature-branch-is-off-default ()
  (dziman-git-test-with-repo
    (dziman-git-test-git "switch" "-q" "-c" "feature")
    (should (plist-get (dziman-git-test-context-of "a.txt") :off-default))
    )
  )

(ert-deftest dziman-git-context/default-branch-is-not-off-default ()
  (dziman-git-test-with-repo
    (should-not (plist-get (dziman-git-test-context-of "a.txt") :off-default))
    )
  )

(ert-deftest dziman-git-context/detached-head-has-no-branch ()
  (dziman-git-test-with-repo
    (dziman-git-test-git "switch" "-q" "--detach")
    (let ((context (dziman-git-test-context-of "a.txt")))
      (should-not (plist-get context :branch))
      (should-not (plist-get context :off-default))
      )
    )
  )

(ert-deftest dziman-git-context/empty-repo-has-no-commits ()
  (dziman-git-test-with-dir
    (dziman-git-test-git "init" "-q" "-b" "main")
    (with-temp-buffer
      (let ((context (dziman/git-context)))
        (should (plist-get context :repo))
        (should-not (plist-get context :has-commits))
        (should-not (plist-get context :default-branch))
        )
      )
    )
  )

(ert-deftest dziman-git-context/known-forge-host-allows-web-links ()
  (dziman-git-test-with-repo
    (dziman-git-test-fake-remote "origin" "git@github.com:me/repo.git")
    (should (plist-get (dziman-git-test-context-of "a.txt") :web-link))
    )
  )

(ert-deftest dziman-git-context/unknown-host-has-no-web-links ()
  (dziman-git-test-with-repo
    (dziman-git-test-fake-remote "origin" "ssh://git@git.example.org/me/repo.git")
    (should-not (plist-get (dziman-git-test-context-of "a.txt") :web-link))
    )
  )

(provide 'dz-config-git-menu-test)
