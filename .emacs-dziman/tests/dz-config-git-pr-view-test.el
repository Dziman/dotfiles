;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; ERT tests for dz-config-git-pr-view. Run from the repo root:
;;;;;;   emacs --batch -f package-initialize -L .emacs-dziman/configs -L .emacs-dziman/tests \
;;;;;;     -l dz-config-git-pr-view-test -f ert-run-tests-batch-and-exit
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'ert)
(require 'cl-lib)
(require 'dz-config-git-pr-view)

;;;;;;;; What the forge CLIs answer
(defconst dziman-git-test-fj-pr-json
  "{\"number\": 1, \"title\": \"Add profiles\", \"user\": {\"login\": \"me\"},
    \"state\": \"closed\", \"merged\": true, \"base\": {\"ref\": \"main\"},
    \"head\": {\"label\": \"profile/mechanism\", \"ref\": \"refs/pull/1/head\"},
    \"html_url\": \"https://git.example.org/me/repo/pulls/1\", \"body\": \"## What\\nOne link.\"}")

(defconst dziman-git-test-fj-commits
  "commit cddf088d076081f596ebc99152db813e0c518c23 (+68, -0)
Author: Me <me@example.com>
Date:   Fri Oct 09 19:13:54 2026 -0700

    [profile] Add machine profile mechanism

    Body line.

commit 1111111111111111111111111111111111111111 (+1, -0)
Author: Me <me@example.com>
Date:   Fri Oct 09 19:14:54 2026 -0700

    Second commit
")

(defconst dziman-git-test-fj-files
  "+1  -0 .emacs
+13 -0 .emacs-dziman/configs/dz-config-profile.el
")

(defconst dziman-git-test-gh-pr-json
  "{\"number\": 1, \"title\": \"Add profiles\", \"author\": {\"login\": \"me\"}, \"state\": \"MERGED\",
    \"baseRefName\": \"main\", \"headRefName\": \"profile/mechanism\",
    \"url\": \"https://github.com/me/repo/pull/1\", \"body\": \"## What\\nOne link.\",
    \"commits\": [{\"oid\": \"cddf088d076081f596ebc99152db813e0c518c23\",
                   \"messageHeadline\": \"[profile] Add machine profile mechanism\"}],
    \"files\": [{\"path\": \".emacs\", \"additions\": 1, \"deletions\": 0},
                {\"path\": \".emacs-dziman/configs/dz-config-profile.el\", \"additions\": 13, \"deletions\": 0}]}")

(defconst dziman-git-test-pr-diff
  "diff --git a/.emacs b/.emacs
index 1111111..2222222 100644
--- a/.emacs
+++ b/.emacs
@@ -1 +1,2 @@
 x
+(require 'dz-config-profile)
diff --git a/b.txt b/b.txt
new file mode 100644
--- /dev/null
+++ b/b.txt
@@ -0,0 +1 @@
+b
")

(defvar dziman-git-test-conversation-calls 0)

(defun dziman-git-test-forge (program args)
  "Answer `dziman/git-pr--run' as fj or gh would for PR 1."
  (let ((last (car (last args))))
    (cond
      ((or (equal last "comments") (member "--comments" args))
        (cl-incf dziman-git-test-conversation-calls)
        "me: Looks good\n"
        )
      ((or (equal last "diff") (equal (cadr args) "diff")) dziman-git-test-pr-diff)
      ((equal program "gh") dziman-git-test-gh-pr-json)
      ((equal last "--json") dziman-git-test-fj-pr-json)
      ((equal last "commits") dziman-git-test-fj-commits)
      ((equal last "files") dziman-git-test-fj-files)
      )
    )
  )

(defun dziman-git-test-pr-scope (tool)
  (list :tool tool :root temporary-file-directory :host "git.example.org" :repo-path "me/repo"
    :remote "origin" :number 1 :url "https://git.example.org/me/repo/pulls/1")
  )

(defmacro dziman-git-test-with-forge (&rest body)
  `(cl-letf (((symbol-function 'dziman/git-pr--run) (lambda (program &rest args) (dziman-git-test-forge program args))))
     (setq dziman-git-test-conversation-calls 0)
     ,@body
     )
  )

(defmacro dziman-git-test-in-pr-view (&rest body)
  "Run BODY in the fj PR 1 view buffer, killed after."
  `(dziman-git-test-with-forge
     (dziman/git-pr-view (dziman-git-test-pr-scope 'fj))
     (with-current-buffer "*PR me/repo#1*"
       (unwind-protect
         (progn ,@body)
         (kill-buffer)
         )
       )
     )
  )

;;;;;;;; Reading the CLIs
(ert-deftest dziman-git-pr-view-parse/fj-merged-pr-reads-as-merged ()
  (dziman-git-test-with-forge
    (let ((pr (dziman/git-pr-fetch (dziman-git-test-pr-scope 'fj))))
      (should (equal (plist-get pr :state) "merged"))
      (should (equal (plist-get pr :head) "profile/mechanism"))
      (should (equal (plist-get pr :author) "me"))
      )
    )
  )

(ert-deftest dziman-git-pr-view-parse/fj-commits-give-sha-and-subject ()
  (should (equal (car (dziman/git-pr--parse-fj-commits dziman-git-test-fj-commits))
            '("cddf088d076081f596ebc99152db813e0c518c23" . "[profile] Add machine profile mechanism")))
  )

(ert-deftest dziman-git-pr-view-parse/fj-files-give-counts ()
  (should (member '(".emacs" 1 0) (dziman/git-pr--parse-fj-files dziman-git-test-fj-files)))
  )

(ert-deftest dziman-git-pr-view-parse/gh-pr-reads-the-same ()
  (dziman-git-test-with-forge
    (let ((pr (dziman/git-pr-fetch (dziman-git-test-pr-scope 'gh))))
      (should (equal (plist-get pr :title) "Add profiles"))
      (should (equal (plist-get pr :state) "merged"))
      (should (equal (plist-get pr :files)
                '((".emacs" 1 0) (".emacs-dziman/configs/dz-config-profile.el" 13 0))))
      )
    )
  )

(ert-deftest dziman-git-pr-view-parse/file-diff-is-cut-from-the-pr-diff ()
  (let ((section (dziman/git-pr--file-diff dziman-git-test-pr-diff "b.txt")))
    (should (string-prefix-p "diff --git a/b.txt b/b.txt" section))
    (should-not (string-search ".emacs" section))
    )
  )

(ert-deftest dziman-git-pr-view-parse/renamed-file-diff-is-found ()
  (let ((diff "diff --git a/old.txt b/new.txt\nsimilarity index 100%\nrename from old.txt\nrename to new.txt\n"))
    (should (equal (dziman/git-pr--file-diff diff "new.txt") diff))
    )
  )

(ert-deftest dziman-git-pr-view-parse/windows-line-endings-leave-no-carriage-returns ()
  (should-not (string-search "\r" (dziman/git-pr--render-markdown "## What\r\nOne link.\r\n")))
  )

;;;;;;;; The view buffer
(ert-deftest dziman-git-pr-view/buffer-shows-title-state-branches-commits-files ()
  (dziman-git-test-in-pr-view
    (dolist (text '("Add profiles" "merged" "profile/mechanism → main" "Commits" ".emacs"))
      (should (equal (list text (and (string-search text (buffer-string)) t)) (list text t)))
      )
    )
  )

(ert-deftest dziman-git-pr-view/conversation-waits-for-its-key ()
  (dziman-git-test-in-pr-view
    (should (= dziman-git-test-conversation-calls 0))
    (should (commandp (lookup-key dziman/git-pr-view-mode-map "c")))
    (call-interactively (lookup-key dziman/git-pr-view-mode-map "c"))
    (should (= dziman-git-test-conversation-calls 1))
    (should (string-search "Looks good" (buffer-string)))
    )
  )

(ert-deftest dziman-git-pr-view/unfetched-commit-is-reported-not-fetched ()
  (dziman-git-test-in-pr-view
    (let (said)
      (cl-letf (((symbol-function 'magit-commit-p) (lambda (_rev) nil))
                ((symbol-function 'magit-show-commit) (lambda (&rest _) (ert-fail "showed an unfetched commit")))
                ((symbol-function 'message) (lambda (format &rest args) (setq said (apply #'format format args)))))
        (goto-char (point-min))
        (should (search-forward "cddf088" nil t))
        (push-button)
        )
      (should (string-match-p "not fetched" said))
      )
    )
  )

(ert-deftest dziman-git-pr-view/file-opens-its-diff ()
  (dziman-git-test-in-pr-view
    (goto-char (point-min))
    (should (search-forward "Files" nil t))
    (should (search-forward ".emacs" nil t))
    (beginning-of-line)
    (push-button)
    (with-current-buffer "*PR me/repo#1: .emacs*"
      (unwind-protect
        (progn
          (should (derived-mode-p 'diff-mode))
          (should (string-search "dz-config-profile" (buffer-string)))
          )
        (kill-buffer)
        )
      )
    )
  )

(provide 'dz-config-git-pr-view-test)
