;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Git menu on C-. g: file, repository and pull request actions that apply
;;;;;; in the current buffer. Loaded on first use, see `dz-config-git'.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'magit)
(require 'git-link)
(require 'dired)
(require 'smerge-mode)

;;;;;;;; Remote and default branch
(defun dziman/git-remote-host-and-path (url)
  "Remote URL as (HOST . \"owner/repo\"), HOST without user or port.
Nil for a local path."
  (when (or
          (string-match
            "\\`[a-z+]+://\\(?:[^@/]+@\\)?\\([^:/]+\\)\\(?::[0-9]+\\)?/\\(.+?\\)\\(?:\\.git\\)?/?\\'" url)
          (string-match "\\`\\(?:[^@/]+@\\)?\\([^:/]+\\):\\([^/].*?\\)\\(?:\\.git\\)?/?\\'" url)
          )
    (cons (match-string 1 url) (match-string 2 url))
    )
  )

(defun dziman/git-default-remote ()
  "The remote the default branch is read from: the current branch's push remote,
else `upstream', else `origin'. Nil when none of them exists."
  (let ((remotes (magit-list-remotes)))
    (seq-find (lambda (remote) (and remote (member remote remotes)))
      (list (magit-get-push-remote) "upstream" "origin"))
    )
  )

(defun dziman/git-default-branch ()
  "The default branch as a revision, or nil if none is found.
The default remote's HEAD as recorded at clone time (\"origin/main\"),
else the first local `develop', `main' or `master'."
  (let ((remote (dziman/git-default-remote)))
    (or
      (and remote
        (magit-git-string "symbolic-ref" "--quiet" "--short" (format "refs/remotes/%s/HEAD" remote)))
      (seq-find (lambda (branch) (magit-rev-verify (concat "refs/heads/" branch)))
        '("develop" "main" "master"))
      )
    )
  )

;;;;;;;; Context the menu reads
(defvar dziman/git--context nil
  "Context of the buffer the git menu was opened from, see `dziman/git-context'.")

(defun dziman/git--ctx (key)
  (plist-get dziman/git--context key)
  )

(defun dziman/git--context-file ()
  "The file git actions apply to.
The visited file, or the regular file under the dired cursor."
  (if (derived-mode-p 'dired-mode)
    (let ((file (dired-get-filename nil t)))
      (and file (file-regular-p file) file)
      )
    buffer-file-name
    )
  )

(defun dziman/git--commit-at-point ()
  (or (magit-commit-at-point)
    (let ((word (thing-at-point 'word t)))
      (and word (string-match-p "\\`[0-9a-f]\\{7,40\\}\\'" word) (magit-commit-p word) word)
      )
    )
  )

(defun dziman/git-context ()
  "What the git menu needs to know about the current buffer, as a plist.
Outside a repository only `:repo' is present, and it is nil."
  (let ((repo (magit-toplevel)))
    (if (not repo)
      (list :repo nil)
      (let* ((file (dziman/git--context-file))
             (file-buffer (and file (not (derived-mode-p 'dired-mode))))
             (region (and file-buffer (use-region-p)))
             (commit-at-point (dziman/git--commit-at-point))
             (default-directory repo)
             (relative (and file (file-in-directory-p file repo) (file-relative-name file repo)))
             (tracked (and relative (magit-file-tracked-p relative)))
             (untracked (and relative (not tracked) (not (magit-git-success "check-ignore" "-q" relative))))
             (has-commits (and (magit-rev-verify "HEAD") t))
             (branch (magit-get-current-branch))
             (remote (dziman/git-default-remote))
             (host-and-path (and remote (dziman/git-remote-host-and-path (or (magit-get "remote" remote "url") ""))))
             (host (car host-and-path))
             (default-branch (and has-commits (dziman/git-default-branch)))
             (web-link (and host (seq-some (lambda (entry) (string-match-p (car entry) host)) git-link-remote-alist) t))
             (off-default (and branch default-branch
                            (not (equal branch (if remote (string-remove-prefix (concat remote "/") default-branch) default-branch)))))
             )
        (list
          :repo repo
          :file (and relative file)
          :file-buffer (and relative file-buffer t)
          :tracked (and tracked t)
          :untracked (and untracked t)
          :unstaged (and tracked (magit-anything-unstaged-p nil relative) t)
          :staged (and tracked has-commits (magit-anything-staged-p nil relative) t)
          :conflicted (and relative (member relative (magit-unmerged-files)) t)
          :region (and relative region t)
          :branch branch
          :remote remote
          :remote-host host
          :remote-path (cdr host-and-path)
          :default-branch default-branch
          :off-default (and off-default t)
          :upstream (and branch (magit-get-upstream-branch branch) t)
          :stash (and (magit-rev-verify "refs/stash") t)
          :staged-any (and has-commits (magit-anything-staged-p) t)
          :modified-any (and has-commits (magit-anything-modified-p) t)
          :has-commits has-commits
          :web-link web-link
          :commit-at-point (and web-link commit-at-point)
          )
        )
      )
    )
  )

;;;;;;;; When a menu key applies
(defmacro dziman/git--define-flag-predicates (&rest pairs)
  "Define each (NAME KEY) as a predicate: true when the menu context has KEY set."
  `(progn
     ,@(mapcar (lambda (pair) `(defun ,(car pair) () (dziman/git--ctx ,(cadr pair)))) pairs)
     )
  )

(dziman/git--define-flag-predicates
  (dziman/git--repo-p :repo)
  (dziman/git--tracked-p :tracked)
  (dziman/git--untracked-p :untracked)
  (dziman/git--unstaged-p :unstaged)
  (dziman/git--staged-p :staged)
  (dziman/git--conflicted-p :conflicted)
  (dziman/git--region-p :region)
  (dziman/git--off-default-p :off-default)
  (dziman/git--branch-p :branch)
  (dziman/git--upstream-p :upstream)
  (dziman/git--stash-p :stash)
  (dziman/git--staged-any-p :staged-any)
  (dziman/git--modified-any-p :modified-any)
  (dziman/git--has-commits-p :has-commits)
  (dziman/git--remote-p :remote)
  (dziman/git--web-link-p :web-link)
  (dziman/git--commit-at-point-p :commit-at-point)
  )

(defun dziman/git--modified-p ()
  (or (dziman/git--unstaged-p) (dziman/git--staged-p))
  )

(defun dziman/git--file-buffer-tracked-p ()
  (and (dziman/git--ctx :file-buffer) (dziman/git--tracked-p))
  )

(defun dziman/git--file-buffer-modified-p ()
  (and (dziman/git--ctx :file-buffer) (dziman/git--modified-p))
  )

(defun dziman/git--tracked-off-default-p ()
  (and (dziman/git--tracked-p) (dziman/git--off-default-p))
  )

(defun dziman/git--branch-remote-p ()
  (and (dziman/git--branch-p) (dziman/git--remote-p))
  )

;;;;;;;; File actions, on the visited file or the one under the dired cursor
(defmacro dziman/git--in-repo (&rest body)
  `(let ((default-directory (dziman/git--ctx :repo)))
     ,@body
     )
  )

(defun dziman/git--relative-file ()
  (file-relative-name (dziman/git--ctx :file) (dziman/git--ctx :repo))
  )

(defun dziman/git--visit-file ()
  "Make the context's file the current buffer, visiting it from dired if needed."
  (unless (dziman/git--ctx :file-buffer)
    (find-file (dziman/git--ctx :file))
    )
  )

(defun dziman/git-file-log ()
  "History of the file, following renames."
  (interactive)
  (if (dziman/git--ctx :file-buffer)
    (magit-log-buffer-file t)
    (dziman/git--in-repo (magit-log-other '("HEAD") '("--follow") (list (dziman/git--relative-file))))
    )
  )

(defun dziman/git-file-blame ()
  (interactive)
  (dziman/git--visit-file)
  (call-interactively #'magit-blame-addition)
  )

(defun dziman/git-file-diff-last-commit ()
  (interactive)
  (dziman/git--in-repo (magit-diff-working-tree "HEAD" nil (list (dziman/git--relative-file))))
  )

(defun dziman/git-file-diff-default ()
  "What this branch changed in the file since it left the default branch."
  (interactive)
  (dziman/git--in-repo
    (magit-diff-range (concat (dziman/git--ctx :default-branch) "...HEAD") nil (list (dziman/git--relative-file)))
    )
  )

(defun dziman/git-file-stage ()
  (interactive)
  (dziman/git--in-repo (magit-stage-files (list (dziman/git--relative-file))))
  )

(defalias 'dziman/git-file-add #'dziman/git-file-stage)

(defun dziman/git-file-unstage ()
  (interactive)
  (dziman/git--in-repo (magit-unstage-files (list (dziman/git--relative-file))))
  )

(defun dziman/git-file-discard ()
  "Throw away the file's staged and unstaged changes, after asking."
  (interactive)
  (let ((relative (dziman/git--relative-file)))
    (when (yes-or-no-p (format "Discard all local changes to %s? " relative))
      (dziman/git--in-repo (magit-file-checkout "HEAD" relative))
      )
    )
  )

(defun dziman/git-file-open-from-branch ()
  "Open the file as it is on another branch, read-only."
  (interactive)
  (dziman/git--in-repo
    (magit-find-file (magit-read-branch-or-commit "Open from branch") (dziman/git--relative-file))
    )
  )

(defun dziman/git-file-rename ()
  (interactive)
  (let ((file (dziman/git--ctx :file)))
    (magit-file-rename file
      (read-file-name (format "Rename %s to: " (dziman/git--relative-file)) (file-name-directory file)))
    )
  )

(defun dziman/git-file-delete ()
  (interactive)
  (dziman/git--in-repo (magit-file-delete (list (dziman/git--relative-file))))
  )

;;;;;;;; Repository actions against the default branch
(defun dziman/git-log-not-on-default ()
  (interactive)
  (dziman/git--in-repo (magit-log-other (list (concat (dziman/git--ctx :default-branch) "..HEAD"))))
  )

(defun dziman/git-diff-branch-default ()
  "What this branch changed since it left the default branch."
  (interactive)
  (dziman/git--in-repo (magit-diff-range (concat (dziman/git--ctx :default-branch) "...HEAD")))
  )

(defun dziman/git-rebase-onto-default ()
  (interactive)
  (dziman/git--in-repo (magit-rebase-branch (dziman/git--ctx :default-branch) nil))
  )

(defun dziman/git-refresh-default-branch ()
  "Ask the remote for its default branch again.
It may have changed since the clone."
  (interactive)
  (dziman/git--in-repo
    (magit-run-git "remote" "set-head" (dziman/git--ctx :remote) "--auto")
    (message "Default branch: %s" (or (dziman/git-default-branch) "none"))
    )
  )

;;;;;;;; Merge conflicts
(defun dziman/git-conflict-sides ()
  "Smerge commands that keep each side of a conflict, as (MINE . THEIRS).
In a merge, the upper part is the current branch. In a rebase, git replays your
commits onto the other branch, so yours is the lower part."
  (if (magit-rebase-in-progress-p)
    (cons #'smerge-keep-lower #'smerge-keep-upper)
    (cons #'smerge-keep-upper #'smerge-keep-lower)
    )
  )

(defun dziman/git-conflict-keep-mine ()
  "Resolve the conflict at point with your side."
  (interactive)
  (funcall (car (dziman/git-conflict-sides)))
  )

(defun dziman/git-conflict-keep-theirs ()
  "Resolve the conflict at point with the other side."
  (interactive)
  (funcall (cdr (dziman/git-conflict-sides)))
  )

(transient-define-prefix dziman/git-conflict-menu ()
  "Merge conflicts of the visited file. Stays open until q."
  ["Merge conflicts"
    ("n" "next" smerge-next :transient t)
    ("p" "previous" smerge-prev :transient t)
    ("m" "keep mine" dziman/git-conflict-keep-mine :transient t)
    ("t" "keep theirs" dziman/git-conflict-keep-theirs :transient t)
    ("a" "keep both" smerge-keep-all :transient t)
    ("q" "quit" transient-quit-one)
    ]
  )

(defun dziman/git-conflicts ()
  "Step through and resolve the merge conflicts of the file."
  (interactive)
  (dziman/git--visit-file)
  (smerge-mode 1)
  (transient-setup 'dziman/git-conflict-menu)
  )

;;;;;;;; Menus
(transient-define-prefix dziman/git-hunks-menu ()
  "Changed hunks of the visited file. Stays open until q."
  ["Changed hunks"
    ("n" "next" git-gutter:next-hunk :transient t)
    ("p" "previous" git-gutter:previous-hunk :transient t)
    ("e" "end of hunk" git-gutter:end-of-hunk :transient t)
    ("d" "show diff" git-gutter:popup-hunk :transient t)
    ("s" "stage" git-gutter:stage-hunk :transient t)
    ("r" "revert" git-gutter:revert-hunk :transient t)
    ("R" "refresh" git-gutter:update-all-windows :transient t)
    ("S" "set start revision" git-gutter:set-start-revision :transient t)
    ("q" "quit" transient-quit-one)
    ]
  )

(transient-define-prefix dziman/git--menu ()
  "File, repository and pull request actions that apply in the current buffer."
  [(:info "Not a git repo" :if-not dziman/git--repo-p)]
  [["File"
     ("l" "history" dziman/git-file-log :if dziman/git--tracked-p)
     ("L" "history of selected lines" magit-log-buffer-file :if dziman/git--region-p)
     ("b" "blame" dziman/git-file-blame :if dziman/git--tracked-p)
     ("d" "diff with last commit" dziman/git-file-diff-last-commit :if dziman/git--modified-p)
     ("D" "diff with default branch" dziman/git-file-diff-default :if dziman/git--tracked-off-default-p)
     ("s" "stage" dziman/git-file-stage :if dziman/git--unstaged-p)
     ("u" "unstage" dziman/git-file-unstage :if dziman/git--staged-p)
     ("a" "add to git" dziman/git-file-add :if dziman/git--untracked-p)
     ("k" "discard changes" dziman/git-file-discard :if dziman/git--modified-p)
     ("o" "open from branch" dziman/git-file-open-from-branch :if dziman/git--tracked-p)
     ("R" "rename" dziman/git-file-rename :if dziman/git--tracked-p)
     ("K" "delete" dziman/git-file-delete :if dziman/git--tracked-p)
     ("t" "step through history" git-timemachine :if dziman/git--file-buffer-tracked-p)
     ("h" "changed hunks…" dziman/git-hunks-menu :if dziman/git--file-buffer-modified-p)
     ("!" "merge conflicts…" dziman/git-conflicts :if dziman/git--conflicted-p)
     ]
    ["Repository"
      ("g" "status" magit-status :if dziman/git--repo-p)
      ("c" "commit" magit-commit-create :if dziman/git--staged-any-p)
      ("C" "amend last commit" magit-commit-amend :if dziman/git--has-commits-p)
      ("B" "switch branch" magit-branch-checkout :if dziman/git--has-commits-p)
      ("N" "new branch" magit-branch-and-checkout :if dziman/git--has-commits-p)
      ("f" "fetch" magit-fetch-all :if dziman/git--remote-p)
      ("F" "pull" magit-pull-from-upstream :if dziman/git--upstream-p)
      ("P" "push" magit-push-current-to-pushremote :if dziman/git--branch-remote-p)
      ("z" "stash" magit-stash-both :if dziman/git--modified-any-p)
      ("Z" "pop stash" magit-stash-pop :if dziman/git--stash-p)
      ]
    ["Default branch"
      ("r l" "branch log" magit-log-current :if dziman/git--has-commits-p)
      ("r m" "commits not on default branch" dziman/git-log-not-on-default :if dziman/git--off-default-p)
      ("r d" "branch diff with default branch" dziman/git-diff-branch-default :if dziman/git--off-default-p)
      ("r r" "rebase onto default branch" dziman/git-rebase-onto-default :if dziman/git--off-default-p)
      ("r h" "refresh default branch" dziman/git-refresh-default-branch :if dziman/git--remote-p)
      ]
    ]
  ["Web link"
    ("w f" "file and lines" git-link :if dziman/git--web-link-p)
    ("w c" "commit at point" git-link-commit :if dziman/git--commit-at-point-p)
    ("w h" "repo home page" git-link-homepage :if dziman/git--web-link-p)
    ]
  )

(defun dziman/git-menu ()
  "File, repository and pull request actions that apply here."
  (interactive)
  ;; Not a `let': suffixes run after `transient-setup' returns
  (setq dziman/git--context (dziman/git-context))
  (transient-setup 'dziman/git--menu)
  )

(provide 'dz-config-git-menu)
