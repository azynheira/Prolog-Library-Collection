:- module(
  rdf_store_table,
  [
    rdf_store_table/1, % +Quadruples:ordset(quadruple(or([bnode,iri]),iri,or([bnode,iri,literal]),atom))
    rdf_store_table/4 % ?Subject:or([bnode,iri])
                      % ?Predicate:iri
                      % ?Object:or([bnode,iri,literal])
                      % ?Graph:atom
  ]
).

/** <module> RDF store table

Predicates that allows RDF tables to be asserted
 in the Prolog console and displayed in the Web browser.

@author Wouter Beek
@version 2014/01-2014/03
*/

:- use_module(generics(meta_ext)).
:- use_module(library(http/html_write)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_path)).
:- use_module(library(lists)).
:- use_module(library(semweb/rdf_db)).
:- use_module(library(www_browser)).
:- use_module(rdf_web(rdf_html_table)).

:- rdf_meta(rdf_store_table(t)).
:- rdf_meta(rdf_store_table(r,r,r,+)).

:- http_handler(root(rdf_store_table), rdf_store_table, []).

%! rdf_store_table(
%!   ?Timestamp:positive_integer,
%!   ?Quadruples:list(list)
%! ) is nondet.

:- dynamic(rdf_store_table/2).



%! rdf_store_table(
%!   +Quadruples:ordset(quadruple(or([bnode,iri]),iri,or([bnode,iri,literal]),atom))
%! ) is det.
% Stores the given number of quadrupes into Prolog memory
% in a form that allows easy retrieval for Web table construction.
% Then, opens the default Web browser (if any) to display
% such a table.
%
% A quadruple is a list of
%   1. an RDF subject term,
%   2. an RDF predicate term,
%   3. an RDF object term, and
%   4. an RDF graph name.
%
% The quadruples must all be fully instantiated.
% @see rdf_store_table/4 is a predicate that produces such ground quadruples
%      while allowing itself to be called with uninstantiated arguments.

rdf_store_table(Quadruples):-
  get_time(Time),
  assert(rdf_store_table(Time, Quadruples)),
  http_absolute_uri(root(rdf_store_table), Link),
  www_open_url(Link).


%! rdf_store_table(
%!   ?Subject:or([bnode,iri]),
%!   ?Predicate:iri,
%!   ?Object:or([bnode,iri,literal]),
%!   ?Graph:atom
%! ) is det.
% Stores all quandruples that match the given instantiation pattern.
% Each of the quadruple elements can be left uninstantiated
% -- or partially instantiated in the case of a literal object term --
% in order to match more ground quadruples.

rdf_store_table(S, P, O, G):-
  setoff(
    [S,P,O,G],
    rdf(S, P, O, G),
    Quadruples
  ),
  rdf_store_table(Quadruples).


%! rdf_store_table(+Request:list(nvpair)) is det.
% Generates an HTML page describing the most recently asserted RDF table.
%
% @see rdf_store_table/[1,4] for asserting RDF tables from the Prolog console.

rdf_store_table(_Request):-
  findall(
    Timestamp-Quadruples,
    rdf_store_table(Timestamp, Quadruples),
    Pairs1
  ),
  keysort(Pairs1, Pairs2),
  reverse(Pairs2, [Timestamp-Quadruples|_]),
  format_time(atom(FormattedTime), '%FT%T%:z', Timestamp),
  TitleContent = ['RDF Table at ',FormattedTime],
  reply_html_page(
    app_style,
    title(TitleContent),
    \rdf_html_table([], html(TitleContent), Quadruples)
  ).

