;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; hydra packages and their configs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package hydra :ensure t)
(use-package major-mode-hydra :ensure t)
(use-package pretty-hydra :ensure t)

(setq major-mode-hydra-invisible-quit-key "q")

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
      )

    "All modes"
    (
      ("M" helm-switch-major-mode "major")
      ("m e" helm-enable-minor-mode "enable minor")
      ("m d" helm-disable-minor-mode "disable minor")
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
