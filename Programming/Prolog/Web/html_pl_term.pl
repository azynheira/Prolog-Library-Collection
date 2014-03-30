:- module(
  html_pl_term,
  [
    html_pl_term//1 % +PlTerm
  ]
).

/** <module> HTML Prolog term

@author Wouter Beek
@version 2014/01-2014/03
*/

:- use_module(generics(uri_query)).
:- use_module(html(html)).
:- use_module(html(html_list)).
:- use_module(library(http/html_write)).
:- use_module(library(http/http_path)).
:- use_module(pl_web(html_pl_error)).
:- use_module(pl_web(html_pl_generic)).



%! html_pl_term(@PlTerm)// is det.
% @tbd What about blobs?

% Error term.
html_pl_term(error(Formal,Context)) --> !,
  {Formal =.. [ErrorKind|_]},
  html(
    div(class=error, [
      div(class=error_kind,
        ErrorKind
      ),
      div(class=error_formal,
        \html_error_formal(Formal)
      ),
      \html_error_context(Context)
    ])
  ).
% Prolog module.
html_pl_term(Module) -->
  {
    current_module(Module), !,
    http_absolute_location(pl(modules), Location1, []),
    uri_query_add(Location1, module, Module, Location2)
  },
  html(span(class=module, a(href=Location2, Module))).
% Class compound term.
html_pl_term(class(Class)) --> !,
  html(span(class=class, Class)).
% File compound term.
html_pl_term(file(File)) --> !,
  html_file(File).
% Prolog predicate terms.
html_pl_term(predicates(Predicates)) --> !,
  html_list([ordered(true)], html_predicate, Predicates).
% Prolog operators.
html_pl_term(operators(Operators)) --> !,
  html_list([ordered(true)], html_operator, Operators).
% Integer.
html_pl_term(Integer) -->
  {integer(Integer)}, !,
  {format(atom(FormattedInteger), '~:d', [Integer])},
  html(span(class=integer, FormattedInteger)).
% Floating point value.
html_pl_term(Float) -->
  {float(Float)}, !,
  {format(atom(FormattedFloat), '~G', [Float])},
  html(span(class=float, FormattedFloat)).
% String.
html_pl_term(String) -->
  {string(String)}, !,
  html(span(cass=string, String)).
% Atom.
html_pl_term(Atom) -->
  {atom(Atom)}, !,
  html(span(class=atom, Atom)).
% HTML link.
html_pl_term(URL-Label) --> !,
  html_link(URL-Label).
% Compound terms are converted to an atom first.
html_pl_term(PlTerm) -->
  {with_output_to(atom(Atom), write_canonical(PlTerm))},
  html(span(class=compound, Atom)).
