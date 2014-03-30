:- module(
  pl_module,
  [
    pl_modules//0
  ]
).

/** <module> Prolog module

Web interface to Prolog modules.

@author Wouter Beek
@version 2014/03
*/

:- use_module(generics(meta_ext)).
:- use_module(generics(uri_query)).
:- use_module(html(html_list)).
:- use_module(html(html_table)).
:- use_module(library(aggregate)).
:- use_module(library(http/html_write)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_path)).
:- use_module(library(lists)).
:- use_module(library(prolog_xref)).
:- use_module(pl_web(pl_predicates)).
:- use_module(pl_web(html_pl_term)).



%! module_to_row(+Module:atom, -Row:list) is det.
% Returns a list of module properties.
%
% The list is ensured to consist of the following members:
%    1. The class to which the module belongs.
%    2. The file from which the module was loaded.
%    3. The list of exported predicates.
%    4. The list of exported operators.

module_to_row(
  Module,
  [class(Class),file(File),predicates(Predicates2),operators(Operators2)]
):-
  module_property(Module, class(Class),
  module_property(Module, file(File)),
  ignore(module_property(Module, exports(Predicates1))),
  default(Predicates1, [], Predicates2),
  ignore(module_property(Module, exported_operators(Operators1))),
  default(Operators1, [], Operators2).


pl_modules -->
  {
    % Set of currently loaded modules.
    aggregate_all(
      set(Module),
      current_module(Module),
      Modules
    ),
    % Properties of modules.
    findall(
      Row,
      (
        member(Module, Modules),
        module_to_row(Module, Row)
      ),
      Rows
    )
  },
  html_table(
    [header_row(true),indexed(true)],
    html('Overview of modules.'),
    html_pl_term,
    [['Module','Class','File','Line count','Exported predicates',
      'Exported operators']|Rows]
  ).


pl_module(Module) -->
  {module_property(Module, exports(Predicates))},
  pl_predicates(Predicates).
