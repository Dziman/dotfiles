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

(defun dziman/git-pr--fj-hosts (&optional reread)
  "Hosts `fj' is logged into; empty when `fj' fails, e.g. logged out.
Read once and cached, or read again with REREAD."
  (when (or reread (not dziman/git-pr--fj-hosts-cache))
    (setq dziman/git-pr--fj-hosts-cache
      (condition-case nil
        (split-string (dziman/git-pr--run "fj" "auth" "list") "\n" t "[ \t]+")
        (user-error nil)
        )
      )
    )
  dziman/git-pr--fj-hosts-cache
  )

(defun dziman/git-pr-host-tool (host)
  "The CLI that serves HOST, or nil.
`gh' for github.com, `fj' for a host fj is logged into."
  (cond
    ((not host) nil)
    ((equal host "github.com") (and (executable-find "gh") 'gh))
    ((and (executable-find "fj")
       ;; Read again for a host not seen yet: fj may have logged into it since
       (or (member host (dziman/git-pr--fj-hosts)) (member host (dziman/git-pr--fj-hosts t))))
      'fj)
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
Only heads on the current branch's history from SHA on count. A later PR built
on top also contains SHA, so the PR whose last commit is closest to SHA wins."
  (let ((descendants (cons sha (magit-git-lines "rev-list" "--ancestry-path" "--reverse" (concat sha "..HEAD"))))
        best best-distance)
    (pcase-dolist (`(,number . ,head) heads)
      (let ((distance (seq-position descendants head)))
        (when (and distance (or (not best) (< distance best-distance) (and (= distance best-distance) (< number best))))
          (setq best number best-distance distance)
          )
        )
      )
    best
    )
  )

(defvar dziman/git-pr--skipped nil
  "Lookup steps the last `dziman/git-pr-find' skipped, as \"STEP: REASON\" strings.")

(defun dziman/git-pr--asking (what lookup)
  "Call LOOKUP, which may reach the network; on failure note it and return :failed."
  (condition-case err
    (funcall lookup)
    (user-error
      (push (format "%s: %s" what (error-message-string err)) dziman/git-pr--skipped)
      :failed
      )
    )
  )

(defun dziman/git-pr-find (sha remote)
  "Number of the pull request that brought commit SHA in, or nil.
Tries each merge style in turn: squash and merge commits from local history,
then GitHub's lookup, then the PR heads REMOTE publishes."
  (setq dziman/git-pr--skipped nil)
  (let* ((url (and remote (magit-git-string "remote" "get-url" remote)))
         (host-and-path (and url (dziman/git-remote-host-and-path url)))
         (github (and (equal (car host-and-path) "github.com") (eq (dziman/git-pr-host-tool "github.com") 'gh)))
         (local (or (dziman/git-pr-number-in-subject (dziman/git-pr--subject sha))
                  (let ((merge (dziman/git-pr--merge-commit sha)))
                    (and merge (dziman/git-pr-number-in-subject (dziman/git-pr--subject merge)))
                    )))
         (asked-github (and (not local) github
                         (dziman/git-pr--asking "GitHub lookup"
                           (lambda () (dziman/git-pr--github-number (cdr host-and-path) sha))))))
    (cond
      (local local)
      ((integerp asked-github) asked-github)
      ;; GitHub's answer covers every merge style, so its "none" is final
      ((and github (not (eq asked-github :failed))) nil)
      (host-and-path
        (let ((number (dziman/git-pr--asking "PR heads"
                        (lambda () (dziman/git-pr--number-containing sha (dziman/git-pr--pull-heads remote))))))
          (and (integerp number) number)
          )
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
         (file (file-relative-name (buffer-file-name (buffer-base-buffer)) root))
         (line (line-number-at-pos nil t))
         (coding buffer-file-coding-system)
         (text (save-restriction (widen) (buffer-string))))
    (with-temp-buffer
      (insert text)
      (let ((default-directory root))
        (when (eql 0 (let ((coding-system-for-write coding)) (call-process-region (point-min) (point-max) "git" t t nil
                       "blame" "--porcelain" "-L" (format "%d,%d" line line) "--contents" "-" "--" file)))
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
  "True on a visited tracked file whose remote's host a forge CLI serves."
  (and (dziman/git--ctx :file-buffer) (dziman/git--ctx :tracked)
    (dziman/git-pr-host-tool (dziman/git--ctx :remote-host)))
  )

(defun dziman/git-pr-at-line ()
  "Find the pull request that brought in the current line.
When there is none, offer to show the line's commit instead."
  (interactive (dziman/git--context-outside-menu))
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
        (when (y-or-n-p (format "No pull request found for %s%s. Show the commit? " (substring sha 0 7)
                          (if dziman/git-pr--skipped
                            (format " (skipped %s)" (string-join (reverse dziman/git-pr--skipped) "; "))
                            "")))
          (let ((default-directory root)) (magit-show-commit sha))
          )
        )
      )
    )
  )

(defun dziman/git-pr--choice-scope ()
  "The pull request the choice menu is open for."
  (or (transient-scope) (user-error "Open it from the git menu's pull request key"))
  )

(defun dziman/git-pr-copy-link ()
  "Copy the pull request's link."
  (interactive)
  (let ((url (plist-get (dziman/git-pr--choice-scope) :url)))
    (kill-new url)
    (message "Copied %s" url)
    )
  )

(defun dziman/git-pr-browse ()
  (interactive)
  (browse-url (plist-get (dziman/git-pr--choice-scope) :url))
  )

(defun dziman/git-pr-show ()
  "Show the pull request in an Emacs buffer."
  (interactive)
  (dziman/git-pr-view (dziman/git-pr--choice-scope))
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
