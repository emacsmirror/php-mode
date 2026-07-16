;;; php-keywords.el --- PHP language keyword tables (cc-mode independent)  -*- lexical-binding: t; -*-

;; Copyright (C) 2026  Friends of Emacs-PHP development

;; Author: USAMI Kenta <tadsan@zonu.me>
;; Maintainer: USAMI Kenta <tadsan@zonu.me>
;; URL: https://github.com/emacs-php/php-mode
;; Keywords: languages php
;; License: GPL-3.0-or-later

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This file extracts the PHP vocabulary that used to be scattered across
;; the `c-lang-defconst' forms in lisp/php-cc-mode.el (roughly lines
;; 367-609 as of the `php-cc-mode' freeze) into plain, cc-mode independent
;; `defconst' lists and pre-compiled `regexp-opt' regexps.
;;
;; The purpose is to give the upcoming cc-free `php-mode' font-lock
;; implementation (see lisp/php-mode.el, not yet written) a single source
;; of truth for PHP keywords, without requiring `cc-mode', `cc-langs' or
;; `cc-fonts'.
;;
;; Naming convention: for every category NAME there is
;;   - `php-keywords--NAME'      a list of keyword strings (lower-case)
;;   - `php-keywords--NAME-re'   the same list compiled with
;;                               `regexp-opt' using the 'symbols
;;                               boundary, so it only matches whole
;;                               tokens (e.g. "if" but not "iffy").
;;
;; Case folding: PHP keywords (control structures, declarations,
;; statements, type names, `true'/`false'/`null') are case-insensitive
;; in the PHP language itself (e.g. "IF", "If", "if" are equivalent).
;; The lists below are kept lower-case only; callers that build
;; `font-lock-keywords' entries from the `-re' regexps MUST bind
;; `case-fold-search' to non-nil (or use `font-lock-defaults' with the
;; KEYWORDS-CASE-FOLD slot set to t) while matching against them.
;;
;; Magic constants (`__LINE__' etc.) are the sole exception: by PHP
;; convention they are always written in upper-case, and are therefore
;; stored upper-case and are not meant to be matched case-insensitively.
;; See `php-keywords--constants'.
;;
;; This file intentionally does NOT duplicate lisp/php-defs.el, which
;; holds the (large) table of built-in *function* names.  Predefined
;; runtime constants other than `true'/`false'/`null' and the magic
;; constants (e.g. `PHP_INT_MAX') are likewise out of scope here; only
;; `PHP_EOL' is included below because it was explicitly called out in
;; the implementation blueprint as a commonly fontified constant.

;;; Code:

;; No dependency on `php' or any other package is required: these are
;; plain data tables.  `regexp-opt' is autoloaded from `regexp-opt.el'
;; which is always preloaded in stock Emacs.


;;; 1. Control structures
;;
;; Source: php-cc-mode.el `c-lang-defconst' forms, php-cc branch:
;;   - `c-block-stmt-2-kwds' (catch declare elseif for foreach if switch
;;     while) -- "elseif" "for" "foreach" "if" "switch" "while" taken
;;     from here; "catch" and "declare" are exception-handling /
;;     declaration keywords and are filed under
;;     `php-keywords--statements' / `php-keywords--declarations'
;;     instead.
;;   - `c-simple-stmt-kwds' (break continue die echo exit goto return
;;     throw include include_once print require require_once) --
;;     "break" "continue" "goto" "return" taken from here.
;;   - `c-modifier-kwds' (abstract final static case readonly) -- "case"
;;     is listed there because php-cc-mode.el also uses it for
;;     `enum ... { case Foo; }' declarations, but as a keyword it is
;;     overwhelmingly a `switch' label, so it is filed here.
;;   - `c-other-kwds' -- "default" "endfor" "endforeach" "endif"
;;     "endswitch" "endwhile" taken from here ("enddeclare" is filed
;;     under `php-keywords--declarations' next to "declare").
;;   - `c-inexpr-block-kwds' (match) -- "match" (PHP 8.0) taken from
;;     here.
;;
;; Supplemented (not present as an explicit php-cc `c-lang-defconst'
;; override; inherited by cc-mode from its java-mode/c base language
;; and therefore invisible in the php-cc-specific forms, but required
;; for a self-contained keyword table):
;;   - "else" and "do" -- part of C-like `c-block-stmt-1-kwds' defaults
;;     that php-cc-mode.el never overrides for PHP.
(defconst php-keywords--control-structures
  '("break" "case" "continue" "default" "do" "else" "elseif" "endfor"
    "endforeach" "endif" "endswitch" "endwhile" "for" "foreach" "goto"
    "if" "match" "return" "switch" "while")
  "PHP control-structure keywords (case-insensitive).
See the commentary in php-keywords.el for provenance.")

(defconst php-keywords--control-structures-re
  (regexp-opt php-keywords--control-structures 'symbols)
  "`regexp-opt' of `php-keywords--control-structures', symbol-bounded.
Match against buffer text with `case-fold-search' bound to non-nil.")


;;; 2. Declarations and modifiers
;;
;; Source:
;;   - `c-class-decl-kwds' -- "class" "trait" "interface" "enum" (PHP
;;     8.1 backed enums).
;;   - `c-typeless-decl-kwds' -- adds "function" "const" on top of
;;     `c-class-decl-kwds'.
;;   - `c-modifier-kwds' -- "abstract" "final" "static" "readonly" (PHP
;;     8.1 readonly properties); "case" excluded, see above.
;;   - `c-protection-kwds' -- "private" "protected" "public".
;;   - `c-postfix-decl-spec-kwds' -- "implements" "extends".
;;   - `c-type-list-kwds' -- adds "use" "namespace" "insteadof" (the
;;     "@new" and "instanceof" entries in that list are pseudo-tokens /
;;     operators, not declaration keywords, and are excluded; "new" is
;;     filed under `php-keywords--statements').
;;   - `c-other-block-decl-kwds' -- "namespace" (duplicate of above,
;;     kept for provenance).
;;   - `c-other-kwds' -- "global" "var", plus the declare-directive
;;     pseudo-keywords "encoding" "ticks" "strict_types"; "declare"
;;     itself comes from `c-block-stmt-2-kwds' and is filed here
;;     (declarations), together with "enddeclare" which sits next to it
;;     in `c-other-kwds'.
;;
;; Supplemented: none required -- PHP 8.1's "enum"/"readonly" and PHP
;; 8.0's "match" (filed under control-structures) were already present
;; in php-cc-mode.el's tables.
(defconst php-keywords--declarations
  '("abstract" "class" "const" "declare" "enddeclare" "encoding" "enum"
    "extends" "final" "function" "global" "implements" "insteadof"
    "interface" "namespace" "private" "protected" "public" "readonly"
    "static" "strict_types" "ticks" "trait" "use" "var")
  "PHP declaration and modifier keywords (case-insensitive).
See the commentary in php-keywords.el for provenance.")

(defconst php-keywords--declarations-re
  (regexp-opt php-keywords--declarations 'symbols)
  "`regexp-opt' of `php-keywords--declarations', symbol-bounded.
Match against buffer text with `case-fold-search' bound to non-nil.")


;;; 3. Statements and expression-level keywords
;;
;; Source:
;;   - `c-simple-stmt-kwds' -- "die" "echo" "exit" "include"
;;     "include_once" "print" "require" "require_once" "throw" taken
;;     from here ("break" "continue" "goto" "return" filed under
;;     control-structures instead).
;;   - `c-lambda-kwds' -- "function" "use" (already covered by
;;     declarations); nothing new added here.
;;   - `c-operators' `(prefix "new" "clone")' entry -- "new" "clone".
;;   - `c-operators' `(prefix "instanceof")' entry -- "instanceof".
;;   - `c-other-kwds' -- "array" "as" "catch" "empty" "eval" "fn" (PHP
;;     7.4 arrow functions) "isset" "list" "unset" "yield" "yield from"
;;     "and" "or" "xor" taken from here.
;;   - "finally" -- like "else"/"do" above, this is inherited from
;;     cc-mode's java-mode/c base `c-block-stmt-1-kwds' and never
;;     overridden by php-cc-mode.el, so it is supplemented here for
;;     completeness of the try/catch/finally triple.
;;
;; Supplemented: none beyond "finally"; PHP 7.4's "fn" and the
;; "yield from" two-word form were already present in php-cc-mode.el's
;; `c-other-kwds'.
(defconst php-keywords--statements
  '("and" "array" "as" "catch" "clone" "die" "echo" "empty" "eval"
    "exit" "finally" "fn" "include" "include_once" "instanceof" "isset"
    "list" "new" "or" "print" "require" "require_once" "throw" "try"
    "unset" "xor" "yield")
  "PHP statement and expression keywords (case-insensitive).
See the commentary in php-keywords.el for provenance.
Note: the two-word form \"yield from\" is not representable as a single
`regexp-opt' symbol entry; match it separately as
\"\\\\_<yield\\\\_>\\\\s-+\\\\_<from\\\\_>\" if needed, or rely on
\"yield\" alone matching the common one-word case.")

(defconst php-keywords--statements-re
  (regexp-opt php-keywords--statements 'symbols)
  "`regexp-opt' of `php-keywords--statements', symbol-bounded.
Match against buffer text with `case-fold-search' bound to non-nil.")


;;; 4. Type names
;;
;; Source: `c-primitive-type-kwds' -- "int" "integer" "bool" "boolean"
;; "float" "double" "real" "string" "object" "void" "mixed" "never"
;; (PHP 8.1 "never" return type).
;;
;; Supplemented (PHP union/pseudo types that are commonly fontified as
;; types but were not present in php-cc-mode.el's `c-primitive-type-kwds'):
;;   - "array" "callable" "iterable" -- long-standing PHP pseudo-types
;;     usable in type declarations, missing from the cc table (that
;;     table only covered scalar/primitive-ish names; "array" itself
;;     was instead reachable in php-cc-mode.el only indirectly via
;;     `c-other-kwds').
;;   - "false" "null" "true" -- PHP 8.0 allows "false"/"null" as
;;     standalone return/param types and PHP 8.2 allows "true"; also
;;     present in `c-constant-kwds' (see `php-keywords--constants').
;;   - "self" "parent" "static" -- class-relative pseudo-types, valid in
;;     return-type position since PHP 7.4/8.0; "self" and "static" were
;;     present in php-cc-mode.el's `c-other-kwds', "parent" likewise.
(defconst php-keywords--types
  '("array" "bool" "boolean" "callable" "double" "false" "float" "int"
    "integer" "iterable" "mixed" "never" "null" "object" "parent"
    "real" "self" "static" "string" "true" "void")
  "PHP type-hint / pseudo-type keywords (case-insensitive).
See the commentary in php-keywords.el for provenance.")

(defconst php-keywords--types-re
  (regexp-opt php-keywords--types 'symbols)
  "`regexp-opt' of `php-keywords--types', symbol-bounded.
Match against buffer text with `case-fold-search' bound to non-nil.")


;;; 5. Language constants and magic constants
;;
;; Source:
;;   - `c-constant-kwds' -- "true" "false" "null" (case-insensitive
;;     PHP language constants; stored lower-case here, same convention
;;     as every other list in this file).
;;   - php.el's existing `php-magical-constants' -- "__CLASS__"
;;     "__DIR__" "__FILE__" "__FUNCTION__" "__LINE__" "__METHOD__"
;;     "__NAMESPACE__" "__TRAIT__".  These are NOT re-derived from
;;     php-cc-mode.el (they are not part of the 367-609 c-lang-defconst
;;     block; php-cc-mode.el fontifies them by referring directly to
;;     `php-magical-constants' from php.el, see the
;;     `php-magical-constant' font-lock rule).  They are duplicated
;;     into this file's `php-keywords--constants' so this module is
;;     self-contained and does not need to `require' php.el; keep the
;;     two lists in sync if `php-magical-constants' ever changes.
;;
;; Unlike every other category in this file, magic constants are
;; conventionally written in upper-case only and are matched
;; case-sensitively (that is how php-cc-mode.el's existing font-lock
;; rule for `php-magical-constants' behaves).  "true"/"false"/"null"
;; remain lower-case/case-insensitive like the rest of the file.
;;
;; Supplemented: "PHP_EOL", a predefined runtime constant (not a
;; syntactic keyword) called out explicitly in the implementation
;; blueprint (§6) as worth fontifying alongside the magic constants.
;; It is the only predefined library constant included here -- the
;; rest of PHP's predefined constants (PHP_INT_MAX, PHP_VERSION, ...)
;; belong with built-in symbol tables such as lisp/php-defs.el, not in
;; this "language keyword" module.
(defconst php-keywords--constants
  '("true" "false" "null")
  "PHP literal keywords `true', `false' and `null' (case-insensitive).
See `php-keywords--magic-constants' for the separate, case-sensitive
upper-case magic constants (`__LINE__' and friends) and `PHP_EOL'.")

(defconst php-keywords--constants-re
  (regexp-opt php-keywords--constants 'symbols)
  "`regexp-opt' of `php-keywords--constants', symbol-bounded.
Match against buffer text with `case-fold-search' bound to non-nil.")

(defconst php-keywords--magic-constants
  '("__CLASS__" "__DIR__" "__FILE__" "__FUNCTION__" "__LINE__"
    "__METHOD__" "__NAMESPACE__" "__TRAIT__" "PHP_EOL")
  "PHP magic constants and `PHP_EOL', kept upper-case and matched
case-sensitively (do NOT bind `case-fold-search' to non-nil when using
`php-keywords--magic-constants-re').  Mirrors php.el's
`php-magical-constants' plus \"PHP_EOL\"; see the commentary above.")

(defconst php-keywords--magic-constants-re
  (regexp-opt php-keywords--magic-constants 'symbols)
  "`regexp-opt' of `php-keywords--magic-constants', symbol-bounded.
Match case-sensitively (do not fold case).")


;;; 6. Magic methods
;;
;; Source: none -- php-cc-mode.el's 367-609 `c-lang-defconst' block
;; does not enumerate magic method names anywhere (grepped for
;; "__construct", "__call", "__get", "__set", "magic" etc.: no hits).
;; This whole category is supplemented from the PHP manual's list of
;; magic methods (https://www.php.net/manual/language.oop5.magic.php),
;; current through PHP 8.4.
(defconst php-keywords--magic-methods
  '("__call" "__callstatic" "__clone" "__construct" "__debuginfo"
    "__destruct" "__get" "__invoke" "__isset" "__serialize" "__set"
    "__set_state" "__sleep" "__tostring" "__unserialize" "__unset"
    "__wakeup")
  "PHP magic method names, stored lower-case (case-insensitive, like
ordinary PHP identifiers). Supplemented in full; not derived from
php-cc-mode.el, see the commentary above.")

(defconst php-keywords--magic-methods-re
  (regexp-opt php-keywords--magic-methods 'symbols)
  "`regexp-opt' of `php-keywords--magic-methods', symbol-bounded.
Match against buffer text with `case-fold-search' bound to non-nil.")

(provide 'php-keywords)
;;; php-keywords.el ends here
