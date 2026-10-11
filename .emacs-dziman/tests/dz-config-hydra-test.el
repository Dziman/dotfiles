;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; ERT tests for dz-config-hydra and dz-config-fly. Run from the repo root:
;;;;;;   emacs --batch -f package-initialize -L .emacs-dziman/configs -L .emacs-dziman/tests \
;;;;;;     -l dz-config-hydra-test -f ert-run-tests-batch-and-exit
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'ert)
(require 'cl-lib)
(require 'dz-config-icons)
(require 'dz-config-bind-maps)
(require 'dz-config-hydra)
(require 'dz-config-fly)

;;;;;;;; Switching major mode
(ert-deftest dziman-hydra-major-modes/derived-mode-is-offered ()
  (should (memq 'emacs-lisp-mode (dziman/major-modes)))
  )

(ert-deftest dziman-hydra-major-modes/mode-for-a-file-type-is-offered ()
  (let ((auto-mode-alist (cons '("\\.dztest\\'" . dziman-test-file-mode) auto-mode-alist)))
    (cl-letf (((symbol-function 'dziman-test-file-mode) (lambda () (interactive))))
      (should (memq 'dziman-test-file-mode (dziman/major-modes)))
      )
    )
  )

(ert-deftest dziman-hydra-major-modes/fundamental-mode-is-offered ()
  (should (memq 'fundamental-mode (dziman/major-modes)))
  )

(ert-deftest dziman-hydra-major-modes/minor-mode-is-not-offered ()
  (should-not (memq 'flyspell-mode (dziman/major-modes)))
  )

(ert-deftest dziman-hydra-major-modes/chosen-mode-becomes-the-buffer-mode ()
  (with-temp-buffer
    (dziman/switch-major-mode 'emacs-lisp-mode)
    (should (eq major-mode 'emacs-lisp-mode))
    )
  )

;;;;;;;; Toggles hydra
(ert-deftest dziman-hydra-toggles/all-modes-keys-run-existing-commands ()
  (dolist (key '("M" "m"))
    (let ((command (cadr (assoc key dziman/hydra/toggles/heads))))
      (should (and command (fboundp command)))
      )
    )
  )

;;;;;;;; Spelling
(ert-deftest dziman-hydra-spelling/check-word-key-opens-suggestions-in-flyspell-buffers ()
  ;; Read the keymap: turning flyspell-mode on needs an ispell program, which the test must not need
  (require 'flyspell)
  (should (eq (lookup-key flyspell-mode-map [remap ispell-word]) 'flyspell-correct-wrapper))
  )

(provide 'dz-config-hydra-test)
