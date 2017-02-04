#lang typed/racket/base
(require (for-syntax typed/racket/base racket/list racket/syntax)
         racket/match syntax/parse/define racket/format)

(provide define/match/extensible)

(define-syntax-parser define/match/extensible
  [(_ (~and form (function:identifier argument:identifier ...)) (~datum :) type:expr
      clause/original:expr ...)
   (with-syntax ([define/match/extension/function
                   (format-id #'function "define/match/extension/~a" #'function)])
     #`(begin
         (: function type)
         (define form
           ((current-function) argument ...))

         (define-simple-macro (define/match/extension/function clause:expr (... ...+))
           (current-function
            (let ([rest-function (current-function)])
              (: function type)
              (define/match form
                clause (... ...)
                [(argument ...) (rest-function argument ...)])
              function)))

         (: current-function (Parameterof type))
         (define current-function
           (make-parameter
            (let ()
              (: function type)
              (define form
                (apply raise-arguments-error 'function
                       "match/extensible function not defined for arguments"
                       (append `(,(~a 'argument) ,argument) ...)))
              function)))

         #,@(if (empty? (syntax->list #'(clause/original ...)))
                #'()
                #'((define/match/extension/function clause/original ...)))))])

(module+ test
  (require typed/rackunit racket/match racket/format)

  (struct Expression () #:transparent)

  (struct Expression-Integer Expression
    ([integer : Integer])
    #:transparent)

  (struct Addition Expression
    ([operand/left : Expression]
     [operand/right : Expression])
    #:transparent)

  ;; -----------------------------------------------------------

  (: pretty-print/non-extensible (-> Expression String))
  (define/match (pretty-print/non-extensible expression)
    [((Expression-Integer integer)) (~a integer)]
    [((Addition operand/left operand/right))
     (~a "(" (pretty-print/non-extensible operand/left) "+"
         (pretty-print/non-extensible operand/right) ")")])

  ;; -----------------------------------------------------------

  (struct Subtraction Expression
    ([operand/left : Expression]
     [operand/right : Expression])
    #:transparent)

  #;
  (define (pretty-print/non-extensible expression)
    "Cannot extend “pretty-print/non-extensible” to work on “Subtraction”")

  ;; -----------------------------------------------------------

  (define/match/extensible (pretty-print expression)
    : (-> Expression String)
    [((Expression-Integer integer)) (~a integer)]
    [((Addition operand/left operand/right))
     (~a "(" (pretty-print operand/left) "+"
         (pretty-print operand/right) ")")])
  
  ;; -----------------------------------------------------------

  (define/match/extension/pretty-print
    [((Subtraction operand/left operand/right))
     (~a "(" (pretty-print operand/left) "-"
         (pretty-print operand/right) ")")])
  
  ;; -----------------------------------------------------------

  (check-equal?
   (pretty-print (Subtraction (Addition (Expression-Integer 2) (Expression-Integer 4))
                              (Expression-Integer 1)))
   "((2+4)-1)")
  (check-exn exn:fail:contract? (λ () (pretty-print (Expression)))))