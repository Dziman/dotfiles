;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; hydra packages and their configs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package hydra)
(use-package major-mode-hydra)
(use-package pretty-hydra)

(setq major-mode-hydra-invisible-quit-key "q")

(defun dziman/major-modes ()
  "Major mode commands known to this Emacs, sorted by name.
Modes named for file types in `auto-mode-alist' and `interpreter-mode-alist',
plus loaded modes made by `define-derived-mode', plus `fundamental-mode'."
  (let ((modes (list 'fundamental-mode)))
    (dolist (entry (append auto-mode-alist interpreter-mode-alist))
      (let ((mode (cdr entry)))
        (when (and (symbolp mode) (fboundp mode))
          (push mode modes)
          )
        )
      )
    (mapatoms
      (lambda (symbol)
        ;; `define-derived-mode' records the parent, nil included, for every mode it defines
        (when (and (fboundp symbol) (plist-member (symbol-plist symbol) 'derived-mode-parent))
          (push symbol modes)
          )
        )
      )
    (sort (delete-dups modes) #'string<)
    )
  )

(defun dziman/switch-major-mode (mode)
  "Switch the current buffer to major MODE, picked from `dziman/major-modes'."
  (interactive
    (list
      (intern
        (completing-read "Major mode: " (dziman/major-modes) nil t nil nil (symbol-name major-mode))
        )
      )
    )
  (funcall mode)
  )

(defvar dziman/hydra/toggles--title (dziman/with-faicon "toggle-on" "Toggles" 1 -0.05))

(pretty-hydra-define dziman/hydra/toggles
  (:color amaranth :quit-key "q" :title dziman/hydra/toggles--title)
  (
    "Basic"
    (
      ("n" global-display-line-numbers-mode "line number" :toggle t)
      ("w" whitespace-mode "whitespace" :toggle t)
      ("r" rainbow-mode "rainbow" :toggle t)
      ("d" git-gutter-mode "git gutter" :toggle t)
      ("a" abbrev-mode "abbrev" :toggle t)
      )

    "Highlight"
    (
      ("l" hl-line-mode "line" :toggle t)
      ("t" hl-todo-mode "todo" :toggle t)
      ("(" highlight-parentheses-mode "parentheses" :toggle t)
      )

    "Coding"
    (
      ("p" smartparens-mode "smartparens" :toggle t)
      ("P" smartparens-strict-mode "smartparens strict" :toggle t)
      ("S" show-smartparens-mode "show smartparens" :toggle t)
      ("f" flycheck-mode "flycheck" :toggle t)
      ("z" hs-minor-mode "folding" :toggle t)
      )

    "All modes"
    (
      ("M" dziman/switch-major-mode "major")
      ("m" consult-minor-mode-menu "minor on/off")
      )
    )
  )

(bind-key "t" 'dziman/hydra/toggles/body dziman/bind-map/hydra)

(setq major-mode-hydra-title-generator
  '(lambda (mode)
     (s-concat "\n"
       (s-repeat 10 " ")
       (all-the-icons-icon-for-mode mode :v-adjust 0.05)
       " "
       (symbol-name mode)
       " commands"
       )
     )
  )

(bind-key "h" 'major-mode-hydra dziman/bind-map/hydra)

(provide 'dz-config-hydra)
