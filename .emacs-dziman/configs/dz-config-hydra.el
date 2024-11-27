;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; hydra packages and their configs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package hydra :ensure t) ;; TODO Learn https://github.com/abo-abo/hydra
(use-package major-mode-hydra :ensure t)
(use-package pretty-hydra :ensure t)

;; TODO Split into multiple files?
(defvar dz-window--title (with-faicon "windows" "Window Management" 1 -0.05))

(pretty-hydra-define dz-window
  (:foreign-keys warn :title dz-window--title :quit-key "q")
  (
    "Actions"
    (
      ("TAB" other-window "switch")
      ("x" ace-delete-window "delete")
      ("m" ace-delete-other-windows "maximize")
      ("s" ace-swap-window "swap")
      ("a" ace-select-window "select")
      )

   "Resize"
    (
      ("h" move-border-left "←")
      ("j" move-border-down "↓")
      ("k" move-border-up "↑")
      ("l" move-border-right "→")
      ("n" balance-windows "balance")
      ("f" toggle-frame-fullscreen "toggle fullscreen")
      )

   "Split"
    (
      ("b" split-window-right "horizontally")
      ("B" split-window-horizontally-instead "horizontally instead")
      ("v" split-window-below "vertically")
      ("V" split-window-vertically-instead "vertically instead")
      )
    )
  )

(defvar dz-toggles--title (with-faicon "toggle-on" "Toggles" 1 -0.05))

(pretty-hydra-define dz-toggles
  (:color amaranth :quit-key "q" :title dz-toggles--title)
  (
    "Basic"
    (
      ("n" global-display-line-numbers-mode "line number" :toggle t)
      ("w" whitespace-mode "whitespace" :toggle t)
      ("W" whitespace-cleanup-mode "whitespace cleanup" :toggle t)
      ("r" rainbow-mode "rainbow" :toggle t)
      ("d" git-gutter-mode "git gutter" :toggle t)
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
      )

    "All modes"
    (
      ("M" helm-switch-major-mode "major")
      ("m e" helm-enable-minor-mode "enable minor")
      ("m d" helm-disable-minor-mode "disable minor")
      )
    )
  )

(defvar dz-jump-to--title (with-faicon "forward" "Jump to" 1 -0.05))

(pretty-hydra-define dz-jump-to
  (:color amaranth :quit-key "q" :title dz-jump-to--title)
  (
    "Basic"
    (
      ("n" goto-line "line number")
      )

    "avy, ace"
    (
      ("c" avy-goto-char-timer "char")
      ("W" avy-goto-word-1 "word")
      ("l" avy-goto-line "line")
      ("w" ace-window "window")
      )
    )
  )

(defvar dz-dumb-jump-to--title (with-faicon "forward" "Jump to definition" 1 -0.05))

(pretty-hydra-define dz-dumb-jump-to
  (:color amaranth :quit-key "q" :title dz-dumb-jump-to--title)
  (
    "Dumb Jump"
    (
      ("j" dumb-jump-go "Go")
      ("o" dumb-jump-go-other-window "Other window")
      ("e" dumb-jump-go-prefer-external "Go external")
      ("x" dumb-jump-go-prefer-external-other-window "Go external other window")
      ("i" dumb-jump-go-prompt "Prompt")
      ("l" dumb-jump-quick-look "Quick look")
      ("b" dumb-jump-back "Back")
      )
    )
  )

(defvar dz-git-gator--title (with-faicon "git" "Git gator actions" 1 -0.05))

(pretty-hydra-define dz-git-gator
  (:color amaranth :quit-key "q" :title dz-git-gator--title)
  (
    "Jump"
    (
      ("n" git-gutter:next-hunk "next hunk")
      ("p" git-gutter:previous-hunk "prev hunk")
      ("e" git-gutter:end-of-hunk "end of hunk")
      )

    "Actions"
    (
      ("d" git-gutter:popup-hunk "diff")
      ("s" git-gutter:stage-hunk "stage")
      ("r" git-gutter:revert-hunk "revert")
      ("R" git-gutter:update-all-windows "refresh status")
      ("S" git-gutter:set-start-revision "set start revision")
      )
    )
  )

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

(setq major-mode-hydra-invisible-quit-key "q")

(major-mode-hydra-define org-mode
  (:color amaranth)
  ("View"
    (
      ("l" org-toggle-link-display "toggle link view" :toggle t)
      )
    )
  )

(bind-map dz-hydra-map
  :keys ("C-.")
  :bindings (
              "h" 'major-mode-hydra ;; TODO Revisit binding?
              "w" 'dz-window/body
              "t" 'dz-toggles/body
              "j" 'dz-jump-to/body
              "d" 'dz-dumb-jump-to/body ;; TODO Do I really need hydra for that?
              "g" 'dz-git-gator/body
              )
  )

(provide 'dz-config-hydra)
