;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Git menu on C-. g: file, repository and pull request actions that apply
;;;;;; in the current buffer. Loaded on first use, see `dz-config-git'.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'magit)
(require 'git-link)
(require 'dired)

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
          :web-link (and host (seq-some (lambda (entry) (string-match-p (car entry) host)) git-link-remote-alist) t)
          :commit-at-point (and host commit-at-point)
          )
        )
      )
    )
  )

(provide 'dz-config-git-menu)
