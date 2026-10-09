;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Preload heavy deferred packages: all at once in a daemon, one per idle
;;;;;; tick otherwise, so their first use is instant without slowing startup
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defvar dziman/preload-features
  '(magit org org-roam org-super-agenda org-project-capture treemacs-projectile helpful bufler)
  "Features loaded after startup so their first use is instant.")

(defvar dziman/preload-idle-delay 2
  "Seconds of idle time before preloading starts.")

(defvar dziman/preload--pending nil
  "Features not preloaded yet.")

(defun dziman/preload--load (feature)
  (with-demoted-errors "Preload error: %S"
    (require feature)
    )
  )

(defun dziman/preload--next ()
  (when-let* ((feature (pop dziman/preload--pending)))
    (dziman/preload--load feature)
    ;; Re-arm relative to the current idle period; after user input it waits that same idle time again
    (run-with-idle-timer (+ (float-time (or (current-idle-time) 0)) 0.1) nil #'dziman/preload--next)
    )
  )

(defun dziman/preload-start ()
  (setq dziman/preload--pending (copy-sequence dziman/preload-features))
  (if (daemonp)
    (while dziman/preload--pending
      (dziman/preload--load (pop dziman/preload--pending))
      )
    (run-with-idle-timer dziman/preload-idle-delay nil #'dziman/preload--next)
    )
  )

(add-hook 'emacs-startup-hook #'dziman/preload-start)

(provide 'dz-config-preload)
