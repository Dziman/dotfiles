;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; ERT tests for dz-config-emacs-generic. Run from the repo root:
;;;;;;   emacs --batch -f package-initialize -L .emacs-dziman/configs -L .emacs-dziman/tests \
;;;;;;     -l dz-config-emacs-generic-test -f ert-run-tests-batch-and-exit
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'ert)
(require 'cl-lib)

;; Key labels sit next to their bindings in many configs, so the whole config is loaded
(setenv "DZIMAN_EMACS_SETTINGS_DIR" (expand-file-name ".emacs-dziman"))
(load (expand-file-name ".emacs") nil t)

;;;;;;;; which-key settings
(ert-deftest dziman-which-key-settings/popup-opens-after-a-short-pause ()
  (should (< which-key-idle-delay 1.0))
  (should which-key-idle-secondary-delay)
  )

(ert-deftest dziman-which-key-settings/commands-show-their-description ()
  (should (eq which-key-show-docstrings t))
  )

(ert-deftest dziman-which-key-settings/buffer-mode-keys-come-first ()
  (should (eq which-key-sort-order 'which-key-local-then-key-order))
  )

(ert-deftest dziman-which-key-settings/help-key-shows-all-keys-of-the-buffer-mode ()
  (should (eq (key-binding (kbd "C-h M")) 'which-key-show-major-mode))
  )

;;;;;;;; Key labels
(defun dziman-which-key-test-descriptions (prefix)
  "Keys and descriptions the which-key popup lists under PREFIX in a Swift buffer."
  (with-temp-buffer
    ;; The language server is not needed to list keys
    (cl-letf (((symbol-function 'dziman/swift-start-eglot) #'ignore))
      (swift-mode)
      )
    (mapcar (lambda (binding) (cons (car binding) (substring-no-properties (car (last binding)))))
      (which-key--get-bindings (kbd prefix)))
    )
  )

(defun dziman-which-key-test-unnamed (prefix)
  "Keys under PREFIX that the popup shows as a bare \"+prefix\"."
  (seq-keep (lambda (entry) (and (string-prefix-p "+prefix" (cdr entry)) (concat prefix " " (car entry))))
    (dziman-which-key-test-descriptions prefix))
  )

(ert-deftest dziman-which-key-labels/prefixes-say-what-they-hold ()
  ;; C-c ^ is an empty keymap: nothing in it to name
  (should-not (remove "C-c ^"
                (mapcan #'dziman-which-key-test-unnamed '("C-c" "C-x" "C-c p" "C-c c" "M-s" "C-h"))))
  )

(ert-deftest dziman-which-key-labels/own-keys-do-not-show-internal-names ()
  (should-not
    (seq-filter (lambda (entry) (string-match-p "dziman/\\|bind-map\\|/body" (cdr entry)))
      (mapcan #'dziman-which-key-test-descriptions '("C-c" "C-." "M-p" "C-c j" "C-c w"))))
  )

(ert-deftest dziman-which-key-labels/menus-say-what-they-hold ()
  ;; hydra's generated docstring says only which hydra the key opens
  (should-not
    (seq-filter (lambda (entry) (string-match-p "Call the body" (cdr entry)))
      (dziman-which-key-test-descriptions "C-.")))
  )

(ert-deftest dziman-which-key-labels/prefix-labels-get-a-single-plus ()
  ;; which-key adds the + to prefixes itself
  (should-not
    (seq-filter (lambda (entry) (string-prefix-p "++" (cdr entry)))
      (mapcan #'dziman-which-key-test-descriptions '("C-c" "C-x" "C-c p"))))
  )

(provide 'dz-config-emacs-generic-test)
