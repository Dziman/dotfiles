;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Shared fixtures for the git menu tests: throwaway repos with commits
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'cl-lib)
(require 'subr-x)

(defun dziman-git-test-git (&rest args)
  "Run git with ARGS in `default-directory'; return trimmed stdout. Errors on failure."
  (with-temp-buffer
    (let ((status (apply #'process-file "git" nil t nil args)))
      (unless (zerop status)
        (error "git %S failed: %s" args (buffer-string))
        )
      (string-trim (buffer-string))
      )
    )
  )

(defun dziman-git-test-git-status (&rest args)
  "Run git with ARGS in `default-directory', ignoring failure. Return the exit status."
  (apply #'process-file "git" nil nil nil args)
  )

(defun dziman-git-test-commit (file content message)
  "Write CONTENT to FILE and commit it with MESSAGE. Return the commit id."
  (with-temp-file file (insert content))
  (dziman-git-test-git "add" file)
  (dziman-git-test-git "commit" "-q" "-m" message)
  (dziman-git-test-git "rev-parse" "HEAD")
  )

(defun dziman-git-test-fake-remote (name url &optional default-branch)
  "Add remote NAME with URL, no network. With DEFAULT-BRANCH, record it as the remote's HEAD."
  (dziman-git-test-git "remote" "add" name url)
  (when default-branch
    (dziman-git-test-git "update-ref" (format "refs/remotes/%s/%s" name default-branch) "HEAD")
    (dziman-git-test-git "symbolic-ref" (format "refs/remotes/%s/HEAD" name)
      (format "refs/remotes/%s/%s" name default-branch))
    )
  )

(defmacro dziman-git-test-with-dir (&rest body)
  "Run BODY with `default-directory' a new empty directory, deleted after.
The user's git config and hooks are ignored; buffers BODY opens are killed after."
  (let ((buffers (make-symbol "buffers")))
    `(let* ((process-environment
              (append '("GIT_CONFIG_GLOBAL=/dev/null" "GIT_CONFIG_NOSYSTEM=1") process-environment))
            (default-directory (file-name-as-directory (file-truename (make-temp-file "dz-git-" t))))
            (,buffers (buffer-list)))
       (unwind-protect
           (progn ,@body)
         (dolist (buffer (buffer-list))
           (unless (memq buffer ,buffers)
             (with-current-buffer buffer (set-buffer-modified-p nil))
             (kill-buffer buffer)
             )
           )
         (delete-directory default-directory t)
         )
       )
    )
  )

(defmacro dziman-git-test-with-repo (&rest body)
  "Run BODY in a new repo on branch main whose one commit adds a.txt.
`default-directory' is the repo root."
  `(dziman-git-test-with-dir
     (dziman-git-test-git "init" "-q" "-b" "main")
     (dziman-git-test-git "config" "user.name" "Test")
     (dziman-git-test-git "config" "user.email" "test@example.com")
     (dziman-git-test-commit "a.txt" "one\n" "Initial")
     ,@body
     )
  )

(provide 'dz-git-test-fixtures)
