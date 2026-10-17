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

;;;;;;;; Which menu keys show where
(defmacro dziman-git-test-key (name prefix key predicate)
  "Define a test that KEY in transient PREFIX shows only when PREDICATE holds."
  `(ert-deftest ,(intern (format "dziman-git-menu-keys/%s" name)) ()
     (should (eq (plist-get (cdr (ignore-errors (transient-get-suffix ',prefix ,key))) :if) ',predicate))
     )
  )

(dziman-git-test-key file-history-needs-a-tracked-file dziman/git--menu "l" dziman/git--tracked-p)
(dziman-git-test-key lines-history-needs-selected-lines dziman/git--menu "L" dziman/git--region-p)
(dziman-git-test-key blame-needs-a-tracked-file dziman/git--menu "b" dziman/git--tracked-p)
(dziman-git-test-key diff-with-last-commit-needs-changes dziman/git--menu "d" dziman/git--modified-p)
(dziman-git-test-key file-diff-with-default-needs-a-feature-branch dziman/git--menu "D" dziman/git--tracked-off-default-p)
(dziman-git-test-key stage-needs-unstaged-changes dziman/git--menu "s" dziman/git--unstaged-p)
(dziman-git-test-key unstage-needs-staged-changes dziman/git--menu "u" dziman/git--staged-p)
(dziman-git-test-key add-needs-an-untracked-file dziman/git--menu "a" dziman/git--untracked-p)
(dziman-git-test-key discard-needs-changes dziman/git--menu "k" dziman/git--modified-p)
(dziman-git-test-key open-from-branch-needs-a-tracked-file dziman/git--menu "o" dziman/git--tracked-p)
(dziman-git-test-key rename-needs-a-tracked-file dziman/git--menu "R" dziman/git--tracked-p)
(dziman-git-test-key delete-needs-a-tracked-file dziman/git--menu "K" dziman/git--tracked-p)
(dziman-git-test-key history-stepping-needs-a-visited-tracked-file dziman/git--menu "t" dziman/git--file-buffer-tracked-p)
(dziman-git-test-key hunks-need-a-visited-changed-file dziman/git--menu "h" dziman/git--file-buffer-modified-p)
(dziman-git-test-key file-link-needs-a-known-forge dziman/git--menu "w f" dziman/git--web-link-p)
(dziman-git-test-key commit-link-needs-a-commit-at-point dziman/git--menu "w c" dziman/git--commit-at-point-p)
(dziman-git-test-key home-page-link-needs-a-known-forge dziman/git--menu "w h" dziman/git--web-link-p)
(dziman-git-test-key status-needs-a-repo dziman/git--menu "g" dziman/git--repo-p)
(dziman-git-test-key commit-needs-staged-changes dziman/git--menu "c" dziman/git--staged-any-p)
(dziman-git-test-key amend-needs-a-commit dziman/git--menu "C" dziman/git--has-commits-p)
(dziman-git-test-key switch-branch-needs-a-commit dziman/git--menu "B" dziman/git--has-commits-p)
(dziman-git-test-key new-branch-needs-a-commit dziman/git--menu "N" dziman/git--has-commits-p)
(dziman-git-test-key fetch-needs-a-remote dziman/git--menu "f" dziman/git--remote-p)
(dziman-git-test-key pull-needs-an-upstream dziman/git--menu "F" dziman/git--upstream-p)
(dziman-git-test-key push-needs-a-branch-and-remote dziman/git--menu "P" dziman/git--branch-remote-p)
(dziman-git-test-key stash-needs-changes dziman/git--menu "z" dziman/git--modified-any-p)
(dziman-git-test-key pop-needs-a-stash dziman/git--menu "Z" dziman/git--stash-p)
(dziman-git-test-key branch-log-needs-a-commit dziman/git--menu "r l" dziman/git--has-commits-p)
(dziman-git-test-key commits-not-on-default-need-a-feature-branch dziman/git--menu "r m" dziman/git--off-default-p)
(dziman-git-test-key branch-diff-needs-a-feature-branch dziman/git--menu "r d" dziman/git--off-default-p)
(dziman-git-test-key rebase-needs-a-feature-branch dziman/git--menu "r r" dziman/git--off-default-p)
(dziman-git-test-key refresh-default-needs-a-remote dziman/git--menu "r h" dziman/git--remote-p)

(ert-deftest dziman-git-menu-keys/not-a-repo-note-shows-only-outside-repos ()
  (let ((note (ignore-errors (transient-get-suffix 'dziman/git--menu '(0 0)))))
    (should (equal (plist-get (cdr note) :description) "Not a git repo"))
    (should (eq (plist-get (cdr note) :if-not) 'dziman/git--repo-p))
    )
  )

;;;;;;;; Hunk menu
(ert-deftest dziman-git-menu-hunks/every-hunk-key-keeps-the-menu-open ()
  (dolist (key '("n" "p" "e" "d" "s" "r" "R" "S"))
    (should (equal (list key (plist-get (cdr (ignore-errors (transient-get-suffix 'dziman/git-hunks-menu key))) :transient))
              (list key t)))
    )
  )

(ert-deftest dziman-git-menu-hunks/hunk-keys-keep-todays-letters ()
  (dolist (binding '(("n" . git-gutter:next-hunk) ("s" . git-gutter:stage-hunk) ("r" . git-gutter:revert-hunk)))
    (should (eq (plist-get (cdr (ignore-errors (transient-get-suffix 'dziman/git-hunks-menu (car binding)))) :command)
              (cdr binding)))
    )
  )

;;;;;;;; File and repository actions
(defmacro dziman-git-test-recording (function &rest body)
  "Run BODY with FUNCTION replaced by one that records its arguments; return them."
  (let ((recorded (make-symbol "recorded")))
    `(let ((,recorded 'not-called))
       (cl-letf (((symbol-function ',function) (lambda (&rest args) (setq ,recorded args))))
         ,@body
         )
       ,recorded
       )
    )
  )

(defun dziman-git-test-on-feature-branch-with-develop-default ()
  (dziman-git-test-fake-remote "origin" "ssh://git@git.example.org/me/repo.git" "develop")
  (dziman-git-test-git "switch" "-q" "-c" "feature")
  )

(defun dziman-git-test-open-menu-context-of (file)
  "Set the menu context as if opened from a buffer visiting FILE."
  (setq dziman/git--context (dziman-git-test-context-of file))
  )

(ert-deftest dziman-git-menu/stage-in-dired-stages-file-under-cursor ()
  (dziman-git-test-with-repo
    (with-temp-file "a.txt" (insert "two\n"))
    (with-current-buffer (dired-noselect default-directory)
      (dired-goto-file (expand-file-name "a.txt"))
      (setq dziman/git--context (dziman/git-context))
      (dziman/git-file-stage)
      )
    (should (equal (dziman-git-test-git "diff" "--cached" "--name-only") "a.txt"))
    )
  )

(ert-deftest dziman-git-menu/discard-asks-first ()
  (dziman-git-test-with-repo
    (with-temp-file "a.txt" (insert "two\n"))
    (dziman-git-test-open-menu-context-of "a.txt")
    (cl-letf (((symbol-function 'yes-or-no-p) (lambda (_prompt) nil)))
      (dziman/git-file-discard)
      )
    (should (equal (with-temp-buffer (insert-file-contents "a.txt") (buffer-string)) "two\n"))
    )
  )

(ert-deftest dziman-git-menu/discard-restores-last-commit ()
  (dziman-git-test-with-repo
    (with-temp-file "a.txt" (insert "two\n"))
    (dziman-git-test-open-menu-context-of "a.txt")
    (cl-letf (((symbol-function 'yes-or-no-p) (lambda (_prompt) t)))
      (dziman/git-file-discard)
      )
    (should (equal (with-temp-buffer (insert-file-contents "a.txt") (buffer-string)) "one\n"))
    )
  )

(ert-deftest dziman-git-menu/file-diff-with-default-starts-where-branch-left ()
  (dziman-git-test-with-repo
    (dziman-git-test-on-feature-branch-with-develop-default)
    (dziman-git-test-open-menu-context-of "a.txt")
    (should (equal (dziman-git-test-recording magit-diff-range (dziman/git-file-diff-default))
              '("origin/develop...HEAD" nil ("a.txt"))))
    )
  )

(ert-deftest dziman-git-menu/rebase-targets-default-branch ()
  (dziman-git-test-with-repo
    (dziman-git-test-on-feature-branch-with-develop-default)
    (dziman-git-test-open-menu-context-of "a.txt")
    (should (equal (dziman-git-test-recording magit-rebase-branch (dziman/git-rebase-onto-default))
              '("origin/develop" nil)))
    )
  )

(ert-deftest dziman-git-menu/refresh-default-asks-remote-for-its-head ()
  (dziman-git-test-with-repo
    (dziman-git-test-on-feature-branch-with-develop-default)
    (dziman-git-test-open-menu-context-of "a.txt")
    (should (equal (dziman-git-test-recording magit-run-git (dziman/git-refresh-default-branch))
              '("remote" "set-head" "origin" "--auto")))
    )
  )

;;;;;;;; Merge conflicts
(defun dziman-git-test-rebase-conflict-on-a-txt ()
  "Make `main' and branch `other' change a.txt differently, then rebase `other' onto `main'."
  (dziman-git-test-git "switch" "-q" "-c" "other")
  (dziman-git-test-commit "a.txt" "theirs\n" "Theirs")
  (dziman-git-test-git "switch" "-q" "main")
  (dziman-git-test-commit "a.txt" "mine\n" "Mine")
  (dziman-git-test-git "switch" "-q" "other")
  (dziman-git-test-git-status "rebase" "main")
  )

(defun dziman-git-test-keep (command)
  "Resolve the first conflict in a.txt with COMMAND; return the buffer's text."
  (with-current-buffer (find-file-noselect (expand-file-name "a.txt"))
    (smerge-mode 1)
    (goto-char (point-min))
    (smerge-next)
    (funcall command)
    (buffer-string)
    )
  )

(ert-deftest dziman-git-conflict/merge-keep-mine-keeps-current-branch ()
  (dziman-git-test-with-repo
    (dziman-git-test-conflict-on-a-txt)
    (should (equal (dziman-git-test-keep #'dziman/git-conflict-keep-mine) "mine\n"))
    )
  )

(ert-deftest dziman-git-conflict/merge-keep-theirs-keeps-merged-branch ()
  (dziman-git-test-with-repo
    (dziman-git-test-conflict-on-a-txt)
    (should (equal (dziman-git-test-keep #'dziman/git-conflict-keep-theirs) "theirs\n"))
    )
  )

(ert-deftest dziman-git-conflict/rebase-keep-mine-keeps-the-replayed-commit ()
  (dziman-git-test-with-repo
    (dziman-git-test-rebase-conflict-on-a-txt)
    (should (equal (dziman-git-test-keep #'dziman/git-conflict-keep-mine) "theirs\n"))
    )
  )

(dziman-git-test-key conflict-key-needs-a-conflicted-file dziman/git--menu "!" dziman/git--conflicted-p)

(ert-deftest dziman-git-conflict/every-conflict-key-keeps-the-menu-open ()
  (dolist (key '("n" "p" "m" "t" "a"))
    (should (equal (list key (plist-get (cdr (ignore-errors (transient-get-suffix 'dziman/git-conflict-menu key))) :transient))
              (list key t)))
    )
  )

(provide 'dz-config-git-menu-test)
