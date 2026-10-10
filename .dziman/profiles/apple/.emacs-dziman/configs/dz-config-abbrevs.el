;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Apple-only abbrevs, merged into the shared tables from abbrevs.def
;;;;;; (`define-abbrev-table' adds to a table that already exists)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; git commit trailers attributing AI-made commits
(define-abbrev-table 'global-abbrev-table
  '(("caclop" "Co-Authored-By: Claude Opus <drusak+claude@apple.com>" nil 0)
    ("caclso" "Co-Authored-By: Claude Sonnet <drusak+claude@apple.com>" nil 0)
    ("caclha" "Co-Authored-By: Claude Haiku <drusak+claude@apple.com>" nil 0)))

;; persons
(define-abbrev-table 'org-mode-abbrev-table
  '(("kpai" "Kiran Pai" nil 0)
    ("kdarsi" "Kiran Darsi" nil 0)
    ("manoj" "Manoj Kumar" nil 0)
    ("phil" "Phil Manuel" nil 0)))
