;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Read-only pull request view, filled from the forge CLIs (fj, gh).
;;;;;; SCOPE is the plist `dziman/git-pr-at-line' builds:
;;;;;; (:tool :root :host :repo-path :remote :number :url).
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'dz-config-git-pr)
(require 'diff-mode)
(require 'markdown-mode)

;;;;;;;; Reading the CLIs
(defun dziman/git-pr--json (text)
  (json-parse-string text :object-type 'alist :array-type 'list :null-object nil :false-object nil)
  )

(defun dziman/git-pr--parse-fj-commits (text)
  "Commits from `fj pr view N commits' TEXT, as ((SHA . SUBJECT) ...)."
  (let (commits)
    (with-temp-buffer
      (insert text)
      (goto-char (point-min))
      (while (re-search-forward "^commit \\([0-9a-f]+\\)" nil t)
        (let ((sha (match-string 1)))
          (when (re-search-forward "^    \\(.*\\)$" nil t)
            (push (cons sha (match-string 1)) commits)
            )
          )
        )
      )
    (nreverse commits)
    )
  )

(defun dziman/git-pr--parse-fj-files (text)
  "Changed files from `fj pr view N files' TEXT, as ((PATH ADDED DELETED) ...)."
  (let (files)
    (dolist (line (split-string text "\n" t))
      (when (string-match "\\`\\+\\([0-9]+\\) +-\\([0-9]+\\) +\\(.+\\)\\'" line)
        (push (list (match-string 3 line)
                (string-to-number (match-string 1 line)) (string-to-number (match-string 2 line)))
          files)
        )
      )
    (nreverse files)
    )
  )

(defun dziman/git-pr--fj (scope &rest args)
  "Run `fj pr view' on SCOPE's pull request with ARGS."
  (apply #'dziman/git-pr--run "fj" "pr" "-R" (plist-get scope :remote)
    "view" (number-to-string (plist-get scope :number)) args)
  )

(defun dziman/git-pr--gh (scope command &rest args)
  "Run `gh pr COMMAND' on SCOPE's pull request with ARGS."
  (apply #'dziman/git-pr--run "gh" "pr" command (number-to-string (plist-get scope :number))
    "-R" (plist-get scope :repo-path) args)
  )

(defun dziman/git-pr-fetch (scope)
  "SCOPE's pull request as a plist: :number :title :author :state (\"open\",
\"merged\" or \"closed\") :base :head :url :body :commits ((SHA . SUBJECT) ...)
:files ((PATH ADDED DELETED) ...)."
  (let ((default-directory (plist-get scope :root)))
    (pcase (plist-get scope :tool)
      ('fj
        (let ((pr (dziman/git-pr--json (dziman/git-pr--fj scope "--json"))))
          (list
            :number (alist-get 'number pr)
            :title (alist-get 'title pr)
            :author (alist-get 'login (alist-get 'user pr))
            :state (if (alist-get 'merged pr) "merged" (alist-get 'state pr))
            :base (alist-get 'ref (alist-get 'base pr))
            :head (alist-get 'label (alist-get 'head pr))
            :url (alist-get 'html_url pr)
            :body (or (alist-get 'body pr) "")
            :commits (dziman/git-pr--parse-fj-commits (dziman/git-pr--fj scope "commits"))
            :files (dziman/git-pr--parse-fj-files (dziman/git-pr--fj scope "files"))
            )
          )
        )
      ('gh
        (let ((pr (dziman/git-pr--json
                    (dziman/git-pr--gh scope "view" "--json"
                      "number,title,author,state,baseRefName,headRefName,url,body,commits,files"))))
          (list
            :number (alist-get 'number pr)
            :title (alist-get 'title pr)
            :author (alist-get 'login (alist-get 'author pr))
            :state (downcase (alist-get 'state pr))
            :base (alist-get 'baseRefName pr)
            :head (alist-get 'headRefName pr)
            :url (alist-get 'url pr)
            :body (or (alist-get 'body pr) "")
            :commits (mapcar (lambda (commit) (cons (alist-get 'oid commit) (alist-get 'messageHeadline commit)))
                       (alist-get 'commits pr))
            :files (mapcar (lambda (file) (list (alist-get 'path file) (alist-get 'additions file) (alist-get 'deletions file)))
                     (alist-get 'files pr))
            )
          )
        )
      )
    )
  )

(defun dziman/git-pr-diff (scope)
  "Unified diff of SCOPE's pull request."
  (let ((default-directory (plist-get scope :root)))
    (if (eq (plist-get scope :tool) 'gh)
      (dziman/git-pr--gh scope "diff")
      (dziman/git-pr--fj scope "diff")
      )
    )
  )

(defun dziman/git-pr--file-diff (diff path)
  "The part of DIFF that changes PATH, or nil.
A renamed file is found by its new name."
  (let ((start (and (string-match (format "^diff --git a/.* b/%s$" (regexp-quote path)) diff)
                 (match-beginning 0))))
    (when start
      (let ((end (string-search "\ndiff --git " diff start)))
        (substring diff start (and end (1+ end)))
        )
      )
    )
  )

(defun dziman/git-pr-conversation (scope)
  "Comments and reviews of SCOPE's pull request, as text."
  (let* ((default-directory (plist-get scope :root))
         (text (string-trim
                 (if (eq (plist-get scope :tool) 'gh)
                   (dziman/git-pr--gh scope "view" "--comments")
                   (dziman/git-pr--fj scope "comments")
                   ))))
    (if (string-empty-p text) "No comments." text)
    )
  )

(defun dziman/git-pr--render-markdown (text)
  "TEXT with Markdown faces, for insertion into a buffer in another mode."
  (with-temp-buffer
    (insert (string-replace "\r\n" "\n" text))
    (delay-mode-hooks (gfm-mode))
    (font-lock-ensure)
    (let ((position (point-min)))
      (while (< position (point-max))
        (let ((next (next-single-property-change position 'face nil (point-max)))
              (face (get-text-property position 'face)))
          (when face
            (put-text-property position next 'font-lock-face face)
            )
          (setq position next)
          )
        )
      )
    (buffer-string)
    )
  )

;;;;;;;; The view buffer
(defvar-local dziman/git-pr--scope nil)
(defvar-local dziman/git-pr--diff nil "The PR's diff, fetched on the first file opened.")
(defvar-local dziman/git-pr--conversation-shown nil)

(defvar-keymap dziman/git-pr-view-mode-map
  :parent special-mode-map
  "c" #'dziman/git-pr-view-conversation
  "b" #'dziman/git-pr-view-browse
  "l" #'dziman/git-pr-view-copy-link
  "g" #'dziman/git-pr-view-refresh
  )

(define-derived-mode dziman/git-pr-view-mode special-mode "PR"
  "Read-only view of a pull request.
\\{dziman/git-pr-view-mode-map}"
  )

(defun dziman/git-pr--show-commit (sha)
  (if (magit-commit-p sha)
    (magit-show-commit sha)
    (message "Commit %s is not fetched" (substring sha 0 7))
    )
  )

(defun dziman/git-pr--show-file-diff (path)
  (let* ((scope dziman/git-pr--scope)
         (diff (or dziman/git-pr--diff (setq dziman/git-pr--diff (dziman/git-pr-diff scope))))
         (buffer (get-buffer-create
                   (format "*PR %s#%d: %s*" (plist-get scope :repo-path) (plist-get scope :number) path))))
    (with-current-buffer buffer
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert (or (dziman/git-pr--file-diff diff path) ""))
        )
      (diff-mode)
      (setq buffer-read-only t)
      (goto-char (point-min))
      )
    (pop-to-buffer buffer)
    )
  )

(defun dziman/git-pr--heading (text)
  (insert (propertize text 'font-lock-face 'bold) "\n")
  )

(defun dziman/git-pr--draw ()
  (let ((pr (dziman/git-pr-fetch dziman/git-pr--scope))
        (inhibit-read-only t))
    (erase-buffer)
    (setq dziman/git-pr--diff nil dziman/git-pr--conversation-shown nil)
    (insert (propertize (plist-get pr :title) 'font-lock-face '(bold :height 1.2)) "\n")
    (insert (format "%s · %s · %s → %s\n" (plist-get pr :author) (plist-get pr :state)
              (plist-get pr :head) (plist-get pr :base)))
    (insert (plist-get dziman/git-pr--scope :url) "\n\n")
    (insert (dziman/git-pr--render-markdown (plist-get pr :body)) "\n\n")
    (dziman/git-pr--heading "Commits")
    (pcase-dolist (`(,sha . ,subject) (plist-get pr :commits))
      (insert-text-button (format "%s %s" (substring sha 0 7) subject)
        'action (lambda (_button) (dziman/git-pr--show-commit sha)) 'follow-link t)
      (insert "\n")
      )
    (insert "\n")
    (dziman/git-pr--heading "Files")
    (pcase-dolist (`(,path ,added ,deleted) (plist-get pr :files))
      (insert-text-button (format "+%d -%d %s" added deleted path)
        'action (lambda (_button) (dziman/git-pr--show-file-diff path)) 'follow-link t)
      (insert "\n")
      )
    (insert "\n" (propertize "c: load conversation" 'font-lock-face 'shadow) "\n")
    (goto-char (point-min))
    )
  )

(defun dziman/git-pr-view (scope)
  "Show SCOPE's pull request in a read-only buffer."
  (let ((buffer (get-buffer-create
                  (format "*PR %s#%d*" (plist-get scope :repo-path) (plist-get scope :number)))))
    (with-current-buffer buffer
      (dziman/git-pr-view-mode)
      (setq dziman/git-pr--scope scope)
      (setq default-directory (plist-get scope :root))
      (dziman/git-pr--draw)
      )
    (pop-to-buffer buffer)
    )
  )

(defun dziman/git-pr-view-conversation ()
  "Append the pull request's comments and reviews, once."
  (interactive)
  (unless dziman/git-pr--conversation-shown
    (let ((inhibit-read-only t))
      (save-excursion
        (goto-char (point-max))
        (insert "\n")
        (dziman/git-pr--heading "Conversation")
        (insert (dziman/git-pr-conversation dziman/git-pr--scope) "\n")
        )
      )
    (setq dziman/git-pr--conversation-shown t)
    )
  )

(defun dziman/git-pr-view-browse ()
  (interactive)
  (browse-url (plist-get dziman/git-pr--scope :url))
  )

(defun dziman/git-pr-view-copy-link ()
  (interactive)
  (kill-new (plist-get dziman/git-pr--scope :url))
  (message "Copied %s" (plist-get dziman/git-pr--scope :url))
  )

(defun dziman/git-pr-view-refresh ()
  "Fetch the pull request again and redraw."
  (interactive)
  (dziman/git-pr--draw)
  )

(provide 'dz-config-git-pr-view)
