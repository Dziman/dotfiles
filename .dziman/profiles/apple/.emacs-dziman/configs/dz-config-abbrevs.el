;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Apple-only abbrevs, merged into the shared tables from abbrevs.def
;;;;;; (`define-abbrev-table' adds to a table that already exists)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; git commit trailers attributing AI-made commits
(define-abbrev-table 'global-abbrev-table
  '(("caclop" "Co-Authored-By: Claude Opus <drusak+claude@apple.com>" nil :system t)
    ("caclso" "Co-Authored-By: Claude Sonnet <drusak+claude@apple.com>" nil :system t)
    ("caclha" "Co-Authored-By: Claude Haiku <drusak+claude@apple.com>" nil :system t)))

;; persons
(define-abbrev-table 'org-mode-abbrev-table
  '(("kpai" "Kiran Pai" nil :system t)
    ("kdarsi" "Kiran Darsi" nil :system t)
    ("manoj" "Manoj Kumar" nil :system t)
    ("phil" "Phil Manuel" nil :system t)))
