;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Rust development
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; ============================================================================
;; Prerequisites (install once on a fresh machine)
;; ============================================================================
;;
;; All shell commands assume macOS + Homebrew. Verify each tool with
;; `command -v <tool>` after installing.
;;
;; 1. `rustup` (toolchain manager). Preferred:
;;       brew install rustup-init && rustup-init -y
;;    Alternative (single-binary cask):
;;       brew install rustup
;;    Verify:  command -v rustup
;;
;; 2. Stable toolchain (gives you `cargo` and `rustc`):
;;       rustup default stable
;;    Verify:  command -v cargo && command -v rustc
;;
;; 3. `rust-analyzer` (LSP server). Preferred via rustup so it tracks the
;;    active toolchain:
;;       rustup component add rust-analyzer
;;    Alternative (Homebrew, if rustup component is unavailable):
;;       brew install rust-analyzer
;;    Verify:  command -v rust-analyzer
;;
;; 4. `rustfmt` (used by `rustic-format-on-save`):
;;       rustup component add rustfmt
;;    Verify:  command -v rustfmt
;;
;; 5. `clippy` (used as the `cargo watch` checker for on-the-fly lints):
;;       rustup component add clippy
;;    Verify:  cargo clippy --version
;;
;; 6. `lldb-dap` (debugger adapter for `dap-mode`). Already pinned in
;;    `dz-config-swift.el` to /opt/homebrew/opt/llvm/bin/lldb-dap, so:
;;       brew install llvm
;;    Verify:  command -v /opt/homebrew/opt/llvm/bin/lldb-dap
;;
;; Optional, nice-to-haves (only needed if you use the matching hydra entries):
;;       cargo install cargo-edit cargo-watch cargo-expand cargo-outdated
;; ============================================================================

(use-package rustic
  :mode ("\\.rs\\'" . rustic-mode)
  :custom
  (rustic-lsp-client 'lsp-mode)
  (rustic-format-on-save t)
  (rustic-format-trigger 'on-save)
  (rustic-cargo-use-last-stored-arguments t)
  :hook (rustic-mode . dziman/rust-mode-setup)
  :bind
  (:map rustic-mode-map
    ("M-r" . #'rustic-cargo-run)
    ("C-c C-c" . #'rustic-cargo-build)
    ("C-c C-t" . #'rustic-cargo-test)
    ("C-c C-k" . #'rustic-cargo-check)
    ("C-c C-l" . #'rustic-cargo-clippy)
    ("C-c C-x" . #'rustic-cargo-clean)
    )
  :config
  (add-to-list 'auto-mode-alist '("\\.rs\\'" . rustic-mode))
  )

(defun dziman/rust-mode-setup ()
  "Per-buffer setup for Rust files: LSP + on-the-fly checks + eldoc."
  ;; `clippy` instead of plain `check` so flycheck surfaces clippy lints too.
  (setq-local lsp-rust-analyzer-cargo-watch-command "clippy")
  (lsp-deferred)
  (flycheck-mode 1)
  (eldoc-mode 1)
  )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; rust-analyzer tuning
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(with-eval-after-load 'lsp-mode
  ;; Inlay hints: types, parameter names, chained calls, closure return types
  (setq lsp-inlay-hint-enable t)
  (setq lsp-rust-analyzer-server-display-inlay-hints t)
  (setq lsp-rust-analyzer-display-chaining-hints t)
  (setq lsp-rust-analyzer-display-parameter-hints t)
  (setq lsp-rust-analyzer-display-closure-return-type-hints t)
  ;; Background check loop -> on-the-fly diagnostics
  (setq lsp-rust-analyzer-cargo-watch-enable t)
  (setq lsp-rust-analyzer-cargo-watch-command "clippy")
  ;; Macro support
  (setq lsp-rust-analyzer-proc-macro-enable t)
  (setq lsp-rust-analyzer-experimental-proc-attr-macros t)
  ;; Imports: `use foo::bar` style, prefer `self::` over `crate::`
  (setq lsp-rust-analyzer-import-granularity "module")
  (setq lsp-rust-analyzer-import-prefix "self")
  )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Debugging. `dap-cpptools` registers the built-in Rust templates
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'dap-cpptools)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Major-mode hydra (open with `C-. h` thanks to `major-mode-hydra`)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defvar dziman/hydra/rust--title (dziman/with-faicon "cogs" "Rust" 1 -0.05))

(major-mode-hydra-define rustic-mode
  (:color teal :quit-key "q" :title dziman/hydra/rust--title)
  (
    "Cargo"
    (
      ("b" rustic-cargo-build "build")
      ("r" rustic-cargo-run "run")
      ("t" rustic-cargo-test "test")
      ("T" rustic-cargo-current-test "test at point")
      ("k" rustic-cargo-check "check")
      ("K" rustic-cargo-clippy "clippy")
      ("d" rustic-cargo-doc "doc")
      ("c" rustic-cargo-clean "clean")
      ("u" rustic-cargo-update "update")
      ("n" rustic-cargo-new "new project")
      ("o" rustic-cargo-outdated "outdated")
      )

    "Format"
    (
      ("f" rustic-format-buffer "buffer (rustfmt)")
      ("F" rustic-format-file "file (rustfmt)")
      ("p" lsp-format-buffer "buffer (lsp)")
      )

    "LSP"
    (
      ("R" lsp-rename "rename")
      ("a" lsp-execute-code-action "code actions")
      ("i" lsp-find-implementation "implementation")
      ("D" lsp-find-type-definition "type def")
      ("j" lsp-find-declaration "declaration")
      ("m" helm-lsp-workspace-symbol "workspace symbol")
      )

    "Macro / Expand"
    (
      ("M" rustic-cargo-expand "cargo expand")
      ("P" lsp-rust-analyzer-expand-macro "expand macro")
      )

    "Debug"
    (
      ("g" dziman/hydra/debug/body "open debug hydra")
      )
    )
  )

(provide 'dz-config-rust)
