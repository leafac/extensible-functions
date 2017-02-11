#lang scribble/manual

@(require (for-label racket extensible-functions))

@title{Extensible Functions}
@author{@author+email["Leandro Facchinetti" "me@leafac.com"]}

@defmodule[extensible-functions]

@emph{A solution to the expression problem in Typed Racket.}

@tabular[#:style 'boxed
         #:sep @hspace[1]
         #:row-properties '(bottom-border)
         `((, @bold{Version} , @seclink["changelog/0.0.1"]{0.0.1})
           (, @bold{Documentation} , @hyperlink["https://docs.racket-lang.org/extensible-functions"]{https://docs.racket-lang.org/extensible-functions})
           (, @bold{License} , @hyperlink["https://gnu.org/licenses/gpl-3.0.txt"]{GNU General Public License Version 3})
           (, @bold{Code of Conduct} , @hyperlink["http://contributor-covenant.org/version/1/4/"]{Contributor Covenant v1.4.0})
           (, @bold{Distribution} , @hyperlink["https://pkgd.racket-lang.org/pkgn/package/extensible-functions"]{Racket package})
           (, @bold{Source} , @hyperlink["https://git.leafac.com/extensible-functions"]{https://git.leafac.com/extensible-functions})
           (, @bold{Bug Reports} , @para{Write emails to @hyperlink["mailto:extensible-functions@leafac.com"]|{extensible-functions@leafac.com}|.})
           (, @bold{Contributions} , @para{Send @hyperlink["https://git-scm.com/docs/git-format-patch"]{patches} and @hyperlink["https://git-scm.com/docs/git-request-pull"]{pull requests} via email to @hyperlink["mailto:extensible-functions@leafac.com"]|{extensible-functions@leafac.com}|.}))]

@section[#:tag "overview"]{Overview}

@margin-note{It is surprising how little people talk about the expression problem, given how frequently it manifests in everyday programming.}

The @hyperlink["http://eli.thegreenplace.net/2016/the-expression-problem-and-its-solutions/"]{expression problem} is a fundamental issue in programming. It is related to the tension between abstracting over data types and abstracting over functions. Most Racket programs follow the functional-programming paradigm—though Racket has support for object-oriented programming, generally only GUI-related code takes advantage of it. So, in most Racket programs the main form of abstraction is the function. However, when working with extensible data types, functions are limited. Consider the following example:

@racketblock[
 (struct Expression () #:transparent)

 (struct Expression-Integer Expression
   ([integer : Integer])
   #:transparent)

 (struct Addition Expression
   ([operand/left : Expression]
    [operand/right : Expression])
   #:transparent)

 @code:comment{-----------------------------------------------------------}

 (: pretty-print/non-extensible (-> Expression String))
 (define/match (pretty-print/non-extensible expression)
   [((Expression-Integer integer)) (~a integer)]
   [((Addition operand/left operand/right))
    (~a "(" (pretty-print/non-extensible operand/left) "+"
        (pretty-print/non-extensible operand/right) ")")])

 @code:comment{-----------------------------------------------------------}

 (struct Subtraction Expression
   ([operand/left : Expression]
    [operand/right : Expression])
   #:transparent)

 (define (pretty-print/non-extensible expression)
   "Cannot extend “pretty-print/non-extensible” to work on “Subtraction”")]

The code above starts by defining structures for arithmetic expressions. Next, it defines a @emph{pretty printer}. Then, the existing data types are extended with a new type of expression, subtraction. At this point, there is no natural way to extend the pretty printer to work over subtractions.

Let us explore two non-solutions. The first is to define a new function:

@racketblock[
 (: pretty-print/extended (-> Expression String))
 (define/match (pretty-print/extended expression)
   [((Subtraction operand/left operand/right))
    (~a "(" (pretty-print/extended operand/left) "-"
        (pretty-print/extended operand/right) ")")]
   [_ (pretty-print/non-extensible expression)])]

The new function @racket[pretty-printer/extended] handles the case of the data type extension (subtraction) and delegates to the original @racket[pretty-print/non-extensible] for the other cases. This does not work: note that the pretty printer for addition recursively calls itself, but it always calls @racket[pretty-printer/non-extensible] and not @racket[pretty-printer/extended]. So the pretty printer would fail for an expression in which subtraction occurs in one operand of addition—for example, @racket[(Addition (Subtraction (Expression-Value 2) (Expression-Value 3)) (Expression-Value 4))].

The second non-solution is to copy and paste the body of @racket[pretty-print/non-extensible] into @racket[pretty-print/extended], replacing all recursive calls accordingly. There are many problems with this approach. The most outstanding is the repeated code and the burden to maintain it. Also, this non-solution would require changing all call-sites of the original function to the newly extended version. Finally, the extensions are not composable. For example, one module extending expressions with multiplication would need to be aware of extensions already in place (subtraction). This is not manageable if extension writers are different people, working on different modules in different packages.

We introduce a solution to the expression problem: extensible functions. With extensible functions, the pretty printer is a function open for extensions. Consider the following rewrite:

@margin-note{Note the importance of @seclink["occurrence-typing" #:doc '(lib "typed-racket/scribblings/ts-guide.scrbl")]{occurrence typing} for extensible functions to work in the type system.}

@racketblock[
 (struct Expression () #:transparent)

 (struct Expression-Integer Expression
   ([integer : Integer])
   #:transparent)

 (struct Addition Expression
   ([operand/left : Expression]
    [operand/right : Expression])
   #:transparent)
  
 @code:comment{-----------------------------------------------------------}

 (define/match/extensible (pretty-print expression)
   : (-> Expression String)
   [((Expression-Integer integer)) (~a integer)]
   [((Addition operand/left operand/right))
    (~a "(" (pretty-print operand/left) "+"
        (pretty-print operand/right) ")")])

 @code:comment{-----------------------------------------------------------}

 (struct Subtraction Expression
   ([operand/left : Expression]
    [operand/right : Expression])
   #:transparent)
  
 @code:comment{-----------------------------------------------------------}

 (define/match/extension/pretty-print
   [((Subtraction operand/left operand/right))
    (~a "(" (pretty-print operand/left) "-"
        (pretty-print operand/right) ")")])]

In the code above, @racket[define/match/extensible] defines @racket[pretty-print] for the existing expressions, but leaves the function open for extension. Later, when subtraction is defined, the pretty printer is extended with @racket[define/match/extension/pretty-print]. At this point, @racket[pretty-print] supports subtraction, even if occurs inside an addition.

@margin-note{Shadowing existing functions with an extension that matches the same data type—or a supertype thereof—is considered bad form as it obscures the meaning of the program.}

@emph{Caveat}: extensible functions work by mutating the original function—in other words, extending a function is a stateful operation. This means the order of @racket[require]s becomes meaningful to the program. Also, if two extensions match the same data type—or a supertype thereof—the second definition shadows the first.

@section[#:tag "installation"]{Installation}

Extensible Functions are a @hyperlink["https://pkgd.racket-lang.org/pkgn/package/extensible-functions"]{Racket package}. Install it in DrRacket or with the following command line:

@nested[#:style 'code-inset
        @verbatim|{
$ raco pkg install extensible-functions
         }|]

@section[#:tag "usage"]{Usage}

@defform[#:literals (:) (define/match/extensible (function argument ...) : type
                          match*-clause
                          ...)]{
 Similar to @racket[define/match], except that the generated function is @emph{extensible}. Besides the @racket[function], @racket[define/match/extensible] also introduces @racket[define/match/extension/<function>], which is a form that receives further @racket[match*-clause]s and extends the original function. If the generated function is called with an argument it does not recognize, then it raises an @racket[exn:fail:contract].
}

@section[#:tag "changelog"]{Changelog}

This section documents all notable changes to Extensible Functions. It follows recommendations from @hyperlink["http://keepachangelog.com/"]{Keep a CHANGELOG} and uses @hyperlink["http://semver.org/"]{Semantic Versioning}. Each released version is a Git tag.

@;{
 @subsection[#:tag "changelog/unreleased"]{Unreleased} @; 0.0.1 · 2016-02-23

 @subsubsection[#:tag "changelog/unreleased/added"]{Added}

 @subsubsection[#:tag "changelog/unreleased/changed"]{Changed}

 @subsubsection[#:tag "changelog/unreleased/deprecated"]{Deprecated}

 @subsubsection[#:tag "changelog/unreleased/removed"]{Removed}

 @subsubsection[#:tag "changelog/unreleased/fixed"]{Fixed}

 @subsubsection[#:tag "changelog/unreleased/security"]{Security}
}

@subsection[#:tag "changelog/0.0.1"]{0.0.1 · 2017-02-07}

@subsubsection[#:tag "changelog/0.0.1/added"]{Added}

@itemlist[
 @item{Basic functionality.}]
