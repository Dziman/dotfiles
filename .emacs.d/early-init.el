;;; early-init.el --- Early Init File -*- lexical-binding: t -*-
;;; Commentary:
;; Emacs early initialization file loaded before package system and UI.
;; Optimized for performance and minimal startup time.

;;; Code:

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
