#lang info

(define collection "extensible-functions")
(define version "0.0.1")
(define deps '("base" "rackunit-lib" "typed-racket-lib" "typed-racket-more"))
(define build-deps '("scribble-lib" "racket-doc" "typed-racket-doc"))
(define scribblings '(("documentation/extensible-functions.scrbl" ())))
(define compile-omit-paths '("tests"))
(define pkg-desc "A solution to the expression problem in Typed Racket.")
(define pkg-authors '(leafac))
