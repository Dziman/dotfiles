;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; ERT tests for dz-config-prog-mode. Run from the repo root:
;;;;;;   emacs --batch -f package-initialize -L .emacs-dziman/configs -L .emacs-dziman/tests \
;;;;;;     -l dz-config-prog-mode-test -f ert-run-tests-batch-and-exit
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'ert)
(require 'dz-config-bind-maps)
(require 'dz-config-prog-mode)
(require 'hideshow)

;;;;;;;; Folding
(ert-deftest dziman-prog-folding/code-buffers-can-fold-blocks ()
  (should (memq 'hs-minor-mode prog-mode-hook))
  )

(ert-deftest dziman-prog-folding/fold-triangles-show-in-the-fringe ()
  (should hs-show-indicators)
  (should (eq hs-indicator-type 'fringe))
  )

(ert-deftest dziman-prog-folding/folded-block-shows-its-line-count ()
  (should hs-display-lines-hidden)
  )

(provide 'dz-config-prog-mode-test)
