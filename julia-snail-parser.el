;;; julia-snail-parser.el --- Julia Snail Parser -*- lexical-binding: t -*-


(require 'dash)
(require 'parsec)


(defun jsp-whitespace ()
  (parsec-many-as-string
   (parsec-re "[[:space:]\r\n]")))

(defun jsp-identifier ()
  (parsec-and
   (jsp-whitespace)
   (parsec-re "[_[:alnum:]]+")))

(defmacro jsp-keyword (kw)
  `(parsec-re (concatenate 'string ,kw "[^[:alnum:]]")))

(defun jsp-string-tq ()
  (parsec-and
   (jsp-whitespace)
   (parsec-query (parsec-re "\"\"\"\\(\\(?:.\\|\n\\)*?\\)\"\"\"") :group 1)))

(defun jsp-string-dq ()
  (parsec-and
   (jsp-whitespace)
   (parsec-query (parsec-re "\"\\(\\(?:.\\|\n\\)*?\\)\"") :group 1)))

(defun jsp-string ()
  (parsec-and
   (jsp-whitespace)
   (parsec-or (jsp-string-tq)
              (jsp-string-dq))))

(defun jsp-comment ()
  (parsec-and
   (jsp-whitespace)
   (parsec-re "#.*?$")))

(defun jsp-comment-multiline ()
  ;; use this as an example of the parsec-many parsec-try combination
  (parsec-many
   (parsec-try
    (parsec-and
     (jsp-whitespace)
     (parsec-re "#.*?$")))))

(defun jsp-end ()
  (parsec-and
   (jsp-whitespace)
   (jsp-*pq (parsec-re "end") :end)))

(defun jsp-other ()
  (parsec-and
   (jsp-whitespace)
   (parsec-many-till-as-string
    (parsec-or
     (parsec-re "\\[.*?end.*?\\]") ; deal with Julia end syntax in brackets
     (parsec-any-ch))
    (parsec-lookahead
     (parsec-or
      (parsec-try (parsec-eof))
      (parsec-try (jsp-end))
      (parsec-try (jsp-comment))
      (parsec-try (jsp-string))
      (parsec-try (jsp-block)))))))

(defun jsp-expression ()
  (parsec-and
   (jsp-whitespace)
   (parsec-or (jsp-comment)
              (jsp-string)
              (jsp-block)
              (jsp-other))))

(defun jsp-start-module ()
  (-snoc
   (jsp-*pq (parsec-or
             (jsp-keyword "module")
             (jsp-keyword "baremodule"))
            :module)
   (jsp-identifier)))

(defun jsp-start-function ()
  (-snoc
   (jsp-*pq (jsp-keyword "function") :function)
   (jsp-identifier)))

(defun jsp-start-macro ()
  (-snoc
   (jsp-*pq (jsp-keyword "macro") :macro)
   (jsp-identifier)))

(defun jsp-start-type ()
  (-snoc
   (jsp-*pq (parsec-or
             (jsp-keyword "abstract type")
             (jsp-keyword "primitive type"))
            :type)
   (jsp-identifier)))

(defun jsp-start-struct ()
  (-snoc
   (jsp-*pq (parsec-or
             (jsp-keyword "struct")
             (jsp-keyword "mutable struct"))
            :struct)
   (jsp-identifier)))

(defun jsp-start-if ()
  (jsp-*pq (jsp-keyword "if") :if))

(defun jsp-start-while ()
  (-snoc
   (jsp-*pq (jsp-keyword "while") :while)
   ;; FIXME:
   ))

(defun jsp-start-for ()
  (-snoc
   (jsp-*pq (jsp-keyword "for") :for)
   ;; FIXME:
   ))

(defun jsp-start-begin ()
  (-snoc
   (jsp-*pq (jsp-keyword "begin") :begin)
   ;; FIXME:
   ))

(defun jsp-start-quote ()
  (-snoc
   (jsp-*pq (jsp-keyword "quote") :quote)
   ;; FIXME:
   ))

(defun jsp-start-try ()
  (-snoc
   (jsp-*pq (jsp-keyword "try") :try)
   ;; FIXME:
   ))

(defun jsp-start-let ()
  (-snoc
   (jsp-*pq (jsp-keyword "let") :let)
   ;; FIXME:
   ))

(defun jsp-block ()
  (parsec-and
   (jsp-whitespace)
   (parsec-collect*
    (parsec-or (jsp-start-module)
               (jsp-start-function)
               (jsp-start-macro)
               (jsp-start-type)
               (jsp-start-struct)
               (jsp-start-if)
               (jsp-start-while)
               (jsp-start-for)
               (jsp-start-begin)
               (jsp-start-quote)
               (jsp-start-try)
               (jsp-start-let))
    (parsec-many-till
     (jsp-expression)
     (parsec-lookahead
      (parsec-or
       (parsec-eof)
       (parsec-try (jsp-end)))))
    (jsp-end))))

(defun jsp-file ()
  (parsec-many
   (jsp-expression)))


(defmacro jsp-*pq (parser &optional placeholder)
  "Similar to parsec-query, but always returns the point position
at which the parser started matching. If placeholder is given,
replace the result of the parser with it."
  (let ((start (gensym))
        (res (gensym))
        (ph (gensym)))
    `(let ((,start (point))
           (,res ,parser)
           (,ph ,placeholder))
       (list (if ,ph ,ph ,res)
             ,start))))


(provide 'julia-snail-parser)
