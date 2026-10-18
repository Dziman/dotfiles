;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; ERT tests for dz-config-git, as loaded at startup. Run from the repo root:
;;;;;;   emacs --batch -f package-initialize -L .emacs-dziman/configs -L .emacs-dziman/tests \
;;;;;;     -l dz-config-git-test -f ert-run-tests-batch-and-exit
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'ert)
(require 'dz-config-bind-maps)
(require 'dz-config-git)

;;;;;;;; Startup
(ert-deftest dziman-git-startup/menu-opens-from-C-dot-g ()
  (should (eq (lookup-key dziman/bind-map/hydra "g") 'dziman/git-menu))
  )

(ert-deftest dziman-git-startup/menu-code-loads-on-first-use ()
  (should (autoloadp (symbol-function 'dziman/git-menu)))
  (should-not (featurep 'dz-config-git-menu))
  )

(ert-deftest dziman-git-startup/old-hydra-is-gone ()
  (should-not (fboundp 'dziman/hydra/git/body))
  )

(ert-deftest dziman-git-startup/compiles-without-warnings ()
  ;; A fresh Emacs: this one has already loaded what the file refers to
  (let* ((source (locate-library "dz-config-git.el"))
         (output (with-temp-buffer
                   (call-process (expand-file-name invocation-name invocation-directory) nil t nil
                     "--batch" "-f" "package-initialize" "-L" (file-name-directory source)
                     "--eval" "(setq byte-compile-dest-file-function (lambda (_) (make-temp-file \"dz-git-\" nil \".elc\")))"
                     "-f" "batch-byte-compile" source)
                   (buffer-string))))
    (should-not (string-match-p "Warning" output))
    )
  )

(provide 'dz-config-git-test)
