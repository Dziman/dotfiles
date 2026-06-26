;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Modern completion stack: Vertico + Orderless + Consult + Corfu + Cape
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Minibuffer — Vertico, Orderless, Marginalia
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package vertico
  :init (vertico-mode)
  :custom
  (vertico-cycle t)
  (vertico-resize nil))

(use-package vertico-multiform
  :ensure nil
  :after vertico
  :init (vertico-multiform-mode))

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles basic partial-completion)))))

(use-package marginalia
  :init (marginalia-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Consult — enhanced commands (replaces Helm minibuffer commands)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package consult
  :after projectile
  :bind (("C-x C-r" . consult-recent-file)
         ("C-x r l" . consult-bookmark)
         ("M-y"     . consult-yank-pop)
         ("M-i"     . consult-line)
         ("M-s o"   . consult-line)
         ("M-s r"   . consult-ripgrep)
         ("M-s g"   . consult-git-grep)
         ("M-g i"   . consult-imenu)
         ("M-g o"   . consult-org-heading)
         ("M-g e"   . consult-flycheck))
  :custom
  (consult-project-function #'projectile-project-root))

(use-package consult-projectile
  :after (consult projectile)
  :bind (("C-c p f" . consult-projectile)
         ("C-x C-d" . consult-projectile)))

(use-package consult-flycheck
  :after (consult flycheck))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Embark — context-aware actions (C-. is taken by hydra, use C-;)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package embark
  :bind (("C-;"   . embark-act)
         ("C-M-;" . embark-dwim)
         ("C-h B" . embark-bindings)))

(use-package embark-consult
  :after (embark consult)
  :hook (embark-collect-mode . consult-preview-at-point-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; In-buffer completion — Corfu + Cape
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package corfu
  :init (global-corfu-mode)
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.2)
  (corfu-cycle t)
  (corfu-quit-no-match 'separator))

(use-package corfu-popupinfo
  :ensure nil
  :after corfu
  :hook (corfu-mode . corfu-popupinfo-mode))

(use-package cape
  :init
  (add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-file)
  (add-hook 'python-mode-hook
            (lambda ()
              (add-hook 'completion-at-point-functions
                        (cape-company-to-capf #'company-anaconda) nil t)))
  (add-hook 'terraform-mode-hook
            (lambda ()
              (add-hook 'completion-at-point-functions
                        (cape-company-to-capf #'company-terraform) nil t))))

(provide 'dz-config-vertico)
