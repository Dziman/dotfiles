;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Pull request for the current line, through the forge CLIs (gh, fj),
;;;;;; which own login. Loaded on first use from the git menu.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'dz-config-git-menu)

(autoload 'dziman/git-pr-view "dz-config-git-pr-view")

;;;;;;;; Forge CLIs
(defvar dziman/git-pr--fj-hosts-cache nil
  "Hosts `fj' is logged into, read once per session.")

(defun dziman/git-pr--run (program &rest args)
  "Run PROGRAM with ARGS in `default-directory'; return its stdout.
Signals `user-error' with the first line of stderr when PROGRAM fails."
  (let ((stderr (make-temp-file "dz-git-pr-")))
    (unwind-protect
      (with-temp-buffer
        (let ((status (apply #'process-file program nil (list t stderr) nil args)))
          (unless (eql status 0)
            (user-error "%s failed: %s" program
              (with-temp-buffer
                (insert-file-contents stderr)
                (string-trim (buffer-substring (point-min) (line-end-position)))
                )
              )
            )
          (buffer-string)
          )
        )
      (delete-file stderr)
      )
    )
  )

(defun dziman/git-pr--fj-hosts ()
  "Hosts `fj' is logged into; empty when `fj' fails, e.g. logged out."
  (or dziman/git-pr--fj-hosts-cache
    (setq dziman/git-pr--fj-hosts-cache
      (condition-case nil
        (split-string (dziman/git-pr--run "fj" "auth" "list") "\n" t "[ \t]+")
        (user-error nil)
        )
      )
    )
  )

(defun dziman/git-pr-host-tool (host)
  "The CLI that serves HOST, or nil.
`gh' for github.com, `fj' for a host fj is logged into."
  (cond
    ((not host) nil)
    ((equal host "github.com") (and (executable-find "gh") 'gh))
    ((and (executable-find "fj") (member host (dziman/git-pr--fj-hosts))) 'fj)
    )
  )

;;;;;;;; Finding the pull request of a commit, cheapest way first
(defun dziman/git-pr-number-in-subject (subject)
  "PR number a commit SUBJECT names, or nil.
Matches \"(#42)\" and \"Merge pull request #42\"."
  (when (or (string-match "Merge pull request #\\([0-9]+\\)" subject)
          (string-match "(#\\([0-9]+\\))" subject))
    (string-to-number (match-string 1 subject))
    )
  )

(defun dziman/git-pr--subject (sha)
  (or (magit-git-string "log" "-1" "--format=%s" sha) "")
  )

(defun dziman/git-pr--merge-commit (sha)
  "The merge commit that brought SHA into the current branch, or nil."
  (let ((range (concat sha "..HEAD")))
    (let ((first-parent (magit-git-lines "rev-list" "--first-parent" "--merges" range)))
      (seq-find (lambda (commit) (member commit first-parent))
        (magit-git-lines "rev-list" "--ancestry-path" "--merges" "--reverse" range))
      )
    )
  )

(defun dziman/git-pr--github-number (repo-path sha)
  (let ((number (string-trim
                  (dziman/git-pr--run "gh" "api" (format "repos/%s/commits/%s/pulls" repo-path sha)
                    "--jq" ".[0].number"))))
    (and (string-match-p "\\`[0-9]+\\'" number) (string-to-number number))
    )
  )

(defun dziman/git-pr--pull-heads (remote)
  "Every PR's last commit as published by REMOTE: alist (NUMBER . SHA)."
  (let (heads)
    (dolist (line (split-string (dziman/git-pr--run "git" "ls-remote" remote "refs/pull/*/head") "\n" t))
      (when (string-match "\\`\\([0-9a-f]+\\)\trefs/pull/\\([0-9]+\\)/head\\'" line)
        (push (cons (string-to-number (match-string 2 line)) (match-string 1 line)) heads)
        )
      )
    (nreverse heads)
    )
  )

(defun dziman/git-pr--number-containing (sha heads)
  "Number of the PR in HEADS whose commits include SHA, or nil.
A later PR built on top of the branch also contains SHA, so the PR whose last
commit is closest to SHA wins."
  (let (candidates)
    (pcase-dolist (`(,number . ,head) heads)
      (when (and (magit-commit-p head) (magit-git-success "merge-base" "--is-ancestor" sha head))
        (push (list (string-to-number (magit-git-string "rev-list" "--count" (concat sha ".." head))) number)
          candidates)
        )
      )
    (cadr (car (sort candidates (lambda (a b) (or (< (car a) (car b))
                                                 (and (= (car a) (car b)) (< (cadr a) (cadr b))))))))
    )
  )

(defun dziman/git-pr--asking (what lookup)
  "Call LOOKUP, which may reach the network; on failure note it and return nil."
  (condition-case err
    (funcall lookup)
    (user-error (message "Skipped %s: %s" what (error-message-string err)) nil)
    )
  )

(defun dziman/git-pr-find (sha remote)
  "Number of the pull request that brought commit SHA in, or nil.
Tries each merge style in turn: squash and merge commits from local history,
then GitHub's lookup, then the PR heads REMOTE publishes."
  (let* ((url (and remote (magit-get "remote" remote "url")))
         (host-and-path (and url (dziman/git-remote-host-and-path url))))
    (or
      (dziman/git-pr-number-in-subject (dziman/git-pr--subject sha))
      (let ((merge (dziman/git-pr--merge-commit sha)))
        (and merge (dziman/git-pr-number-in-subject (dziman/git-pr--subject merge)))
        )
      (and (equal (car host-and-path) "github.com") (eq (dziman/git-pr-host-tool "github.com") 'gh)
        (dziman/git-pr--asking "GitHub lookup"
          (lambda () (dziman/git-pr--github-number (cdr host-and-path) sha)))
        )
      (and host-and-path
        (dziman/git-pr--asking "PR heads"
          (lambda () (dziman/git-pr--number-containing sha (dziman/git-pr--pull-heads remote))))
        )
      )
    )
  )

(defun dziman/git-pr-url (host repo-path number)
  (if (equal host "github.com")
    (format "https://github.com/%s/pull/%d" repo-path number)
    (format "https://%s/%s/pulls/%d" host repo-path number)
    )
  )

(defun dziman/git-pr--line-commit ()
  "Commit of the current line, or nil when the line is not committed.
Blames the buffer's text, so unsaved edits do not shift lines."
  (let* ((root (magit-toplevel))
         (file (file-relative-name buffer-file-name root))
         (line (line-number-at-pos))
         (text (save-restriction (widen) (buffer-string))))
    (with-temp-buffer
      (insert text)
      (let ((default-directory root))
        (when (eql 0 (call-process-region (point-min) (point-max) "git" t t nil
                       "blame" "--porcelain" "-L" (format "%d,%d" line line) "--contents" "-" "--" file))
          (goto-char (point-min))
          (let ((sha (current-word)))
            (and sha (not (string-match-p "\\`0+\\'" sha)) sha)
            )
          )
        )
      )
    )
  )

;;;;;;;; PR key and the one-key choice
(defun dziman/git-pr-available-p ()
  "True when the menu was opened on a visited tracked file.
And when a CLI serves the remote's host."
  (and (dziman/git--ctx :file-buffer) (dziman/git--ctx :tracked)
    (dziman/git-pr-host-tool (dziman/git--ctx :remote-host)))
  )

(defun dziman/git-pr-at-line ()
  "Find the pull request that brought in the current line.
When there is none, offer to show the line's commit instead."
  (interactive)
  (let ((sha (dziman/git-pr--line-commit)))
    (unless sha
      (user-error "This line is not committed yet")
      )
    (message "Looking for the pull request…")
    (let* ((root (dziman/git--ctx :repo))
           (remote (dziman/git--ctx :remote))
           (host (dziman/git--ctx :remote-host))
           (repo-path (dziman/git--ctx :remote-path))
           (number (let ((default-directory root)) (dziman/git-pr-find sha remote))))
      (if number
        (transient-setup 'dziman/git-pr-choice nil nil
          :scope (list :tool (dziman/git-pr-host-tool host) :root root :host host :repo-path repo-path
                   :remote remote :number number :url (dziman/git-pr-url host repo-path number)))
        (when (y-or-n-p (format "No pull request found for %s. Show the commit? " (substring sha 0 7)))
          (let ((default-directory root)) (magit-show-commit sha))
          )
        )
      )
    )
  )

(defun dziman/git-pr-copy-link ()
  "Copy the pull request's link."
  (interactive)
  (let ((url (plist-get (transient-scope) :url)))
    (kill-new url)
    (message "Copied %s" url)
    )
  )

(defun dziman/git-pr-browse ()
  (interactive)
  (browse-url (plist-get (transient-scope) :url))
  )

(defun dziman/git-pr-show ()
  "Show the pull request in an Emacs buffer."
  (interactive)
  (dziman/git-pr-view (transient-scope))
  )

(transient-define-prefix dziman/git-pr-choice ()
  "What to do with the pull request found for the line."
  [:description (lambda () (format "Pull request #%d" (plist-get (transient-scope) :number)))
    ("l" "copy link" dziman/git-pr-copy-link)
    ("b" "open in browser" dziman/git-pr-browse)
    ("e" "show in Emacs" dziman/git-pr-show)
    ]
  )

(provide 'dz-config-git-pr)
