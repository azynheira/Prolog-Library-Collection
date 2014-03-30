:- module(
  html_pl_generic,
  [
    html_file//1, % +File:atom
    html_files//1, % +Files:list(atom)
    html_program//1, % +Program:atom
    html_operator//1, % +Operator:compound
    html_predicate//1, % +Predicate
    html_predicate//2, % +Functor:atom
                       % +Arity:nonneg
    html_predicate//3 % +Module:atom
                      % +Functor:atom
                      % +Arity:nonneg
  ]
).

/** <module> HTML Prolog generics

Generic DCGs for generating parts of HTML descriptions of Prolog terms.

@author Wouter Beek
@version 2014/01-2014/03
*/

:- use_module(generics(uri_query)).
:- use_module(library(http/html_write)).
:- use_module(library(http/http_path)).
:- use_module(pl_web(html_pl_term)).



%! html_arity(+Arity:nonneg)// is det.
% Generates an HTML desciption of the artity of a predicate.

html_arity(Arity) -->
  html(span(class=arity, Arity)).


%! html_file(+File:atom)// is det.
% Generates an HTML description of the given file name.

html_file(File) -->
  html(span(class=file, File)).


%! html_files(+Files:list(atom))// is det.
% Generates an HTML description of the given file names.
%
% @tbd Find common prefixes and shorten the output accordingly,

html_files([]) --> [].
html_files([H|T]) -->
  html([
    \html_file(H),
    br([]),
    \html_files(T)
  ]).


html_functor(Functor) -->
  html(span(class=functor, Functor)).


html_functor_and_arity(Functor, Arity) -->
  html([
    \html_functor(Functor),
    '/',
    \html_arity(Arity)
  ]).


html_module(Module) -->
  html(span(class=module, Module)).


html_operator(op(Precedence,Type,Name)) -->
  {
    http_absolute_location(pl(operator), Location1, []),
    uri_query_add(Location1, operator, op(Precedence,Type,Name), Location2)
  },
  html(
    span(class=operator,
      a(href=Location2, [
        'op(',
        span(class=operator_precedence, \html_pl_term(Precedence)),
        ',',
        span(class=operator_type, \html_pl_term(Type)),
        ',',
        span(class=operator_name, \html_pl_term(Name)),
        ')'
      ])
    )
  ).


html_predicate(Module:Functor/Arity) --> !,
  html_predicate(Module, Functor, Arity).
html_predicate(Functor/Arity) -->
  html_predicate(Functor, Arity).


html_predicate(Functor, Arity) -->
  {
    http_absolute_location(pl(predicate), Location1, []),
    uri_query_add(Location1, predicate, Functor/Arity, Location2)
  },
  html(
    span(class=predicate,
      a(href=Location2,
        \html_functor_and_arity(Functor, Arity))
    )
  ).

html_predicate(Module, Functor, Arity) -->
  {
    http_absolute_location(pl(predicate), Location1, []),
    uri_query_add(Location1, predicate, Module:Functor/Arity, Location2)
  },
  html(
    span(class=predicate,
      a(href=Location2, [
        \html_module(Module),
        ':',
        \html_functor_and_arity(Functor, Arity)
      ])
    )
  ).


html_program(Program) -->
  html(
    span([], [
      'Program: ',
      span(class=program, Program)
    ])
  ).
