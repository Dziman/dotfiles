;;; early-init.el --- Early Init File -*- lexical-binding: t -*-
;;; Commentary:
;; Emacs early initialization file loaded before package system and UI.
;; Optimized for performance and minimal startup time.

;;; Code:

;; ------------------------------------------------------------
;; Native compilation
;; Update library path to include homebrew managed folders automatically
;; ------------------------------------------------------------
(defun homebrew-gcc-paths ()
  "Return GCC library paths from Homebrew installations.
 Detects paths for gcc and libgccjit packages to be used in LIBRARY_PATH."
  (let*
    ((paths '())
      (brew-bin
        (or
          (executable-find "brew")
          (let (
                 (arm-path "/opt/homebrew/bin/brew")
                 (intel-path "/usr/local/bin/brew")
                 )
            (cond
              ((file-exists-p arm-path) arm-path)
              ((file-exists-p intel-path) intel-path)
              )
            )
          )
        )
      )

    (when brew-bin
      ;; Get gcc paths.
      (let* (
              (gcc-prefix (string-trim (shell-command-to-string (concat brew-bin " --prefix gcc"))))
              (gcc-lib-current (expand-file-name "lib/gcc/current" gcc-prefix))
              )

        (push gcc-lib-current paths)

        ;; Find apple-darwin directory.
        (let* (
                (default-directory gcc-lib-current)
                (arch-dirs (file-expand-wildcards "gcc/*-apple-darwin*/*[0-9]"))
                )
          (when arch-dirs
            (push
              (expand-file-name (car (sort arch-dirs #'string>)))
              paths
              )
            )
          )
        )

      ;; Get libgccjit paths
      (let* (
              (jit-prefix (string-trim (shell-command-to-string (concat brew-bin " --prefix libgccjit"))))
              (jit-lib-current (expand-file-name "lib/gcc/current" jit-prefix))
              )

        (push jit-lib-current paths)
        )
      )

    (nreverse paths)
    )
  )

(defun setup-macos-native-comp-library-paths ()
  "Set up LIBRARY_PATH for native compilation on macOS.
Includes Homebrew GCC paths and CommandLineTools SDK libraries."
  (let* (
          (existing-paths (split-string (or (getenv "LIBRARY_PATH") "") ":" t))
          (gcc-paths (homebrew-gcc-paths))
          (clt-paths '("/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib"))
          (unique-paths (delete-dups (append existing-paths gcc-paths clt-paths)))
          )
    (setenv "LIBRARY_PATH" (mapconcat #'identity unique-paths ":"))
    )
  )

;; Set up library paths for native compilation on macOS.
(when (eq system-type 'darwin) (setup-macos-native-comp-library-paths))

;; ------------------------------------------------------------
;; Performance Optimizations
;; ------------------------------------------------------------

;; Save original file handlers to restore later
(defvar file-name-handler-alist-original file-name-handler-alist)

;; Disable bidirectional text support for faster display
(setq-default
  bidi-display-reordering 'left-to-right
  bidi-inhibit-bpa t
  )

;; Disable unnecessary UI elements and features for faster startup
(setq-default
  inhibit-startup-screen t
  inhibit-startup-message t
  inhibit-startup-echo-area-message user-login-name
  inhibit-startup-buffer-menu t
  initial-scratch-message nil
  initial-buffer-choice nil
  initial-major-mode 'fundamental-mode
  )

;; Memory and GC settings for faster startup
(setq
  gc-cons-threshold (* 256 1024 1024)  ; 256MB during startup
  gc-cons-percentage 0.6
  inhibit-compacting-font-caches t
  message-log-max 10000
  kill-ring-max 100000
  load-prefer-newer t
  file-name-handler-alist nil
  vc-handled-backends '(Git)
  )

;; Process and I/O optimizations
(setq
  read-process-output-max (* 64 1024)  ; 64k
  process-adaptive-read-buffering nil
  warning-suppress-types '((comp) (lexical-binding))
  )

;; Package system optimizations
;; TODO Revisit: it looks like causing some startup issues
;;(setq
;;  package-enable-at-startup nil
;;  package-native-compile t
;;  package-quickstart t
;;  )

;; Native compilation settings
;; TODO Revisit: it looks like causing some startup issues
;;(when (and
;;        (fboundp 'native-comp-available-p)
;;        (native-comp-available-p)
;;        )
;;  (setq
;;    native-comp-async-report-warnings-errors nil
;;    native-comp-async-query-on-exit t
;;    native-comp-jit-compilation t
;;    )
;;  )

;; UTF-8 everywhere
(set-language-environment "UTF-8")
(set-default-coding-systems 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(set-selection-coding-system 'utf-8)

;; Use setq for buffer-independent variables
;; Use setq-default for buffer-local variables
(setq-default lexical-binding t)

;; Restore file-name-handler-alist after startup
(add-hook 'emacs-startup-hook
          (lambda ()
            (when (file-exists-p custom-file)
              (load custom-file 'noerror 'nomessage)
              )
            (setq
              gc-cons-threshold (* 16 1024 1024)  ; Reset to 16 MB
              gc-cons-percentage 0.2              ; Reset percentage for GC
              )
            (setq file-name-handler-alist file-name-handler-alist-original)
            (run-with-idle-timer 1.2 t 'garbage-collect)
            )
  )

(provide 'early-init)
;;; early-init.el ends here
