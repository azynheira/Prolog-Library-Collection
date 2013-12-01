:- module(
  option_ext,
  [
    default_option/4, % +OldOptions:list(nvpair)
                      % +Name:atom
                      % +DefaultValue
                      % -NewOptions:list(nvpair)
    default_option/5, % +OldOptions:list(nvpair)
                      % +Name:atom
                      % +DefaultValue
                      % -StoredValue
                      % -NewOptions:list(nvpair)
    option_add/4, % +FromOptions:list(nvpair)
                  % +Name:atom
                  % +Value:atom
                  % +ToOptions:list(nvpair)
    option_ext/3, % ?Option:compound
                  % +Options:list(nvpair)
                  % +Default
    option_format/2, % +OptionAnyFormat:compound
                     % -OptionStandardFormat:compound
    option_format/3, % +OptionAnyFormat:compound
                     % -Name:atom
                     % -Value
    option_member/2, % +Option:compound
                     % +Options:list(compound)
    option_memberchk/2, % +Option:compound
                        % +Options:list(compound)
    replace_option/5, % +OldOptions:list(nvpair)
                      % +Name:atom
                      % +NewValue
                      % -OldValue
                      % -NewOptions:list(nvpair)
    subtract_option/3, % +OldOptions:list(nvpair)
                       % +Delete:list(nvpair)
                       % -NewOptions:list(nvpair)
    update_option/4, % +OldOptions:list(nvpair)
                     % +Name:atom
                     % :Predicate
                     % -NewOptions:list(nvpair)
    update_option/5 % +OldOptions:list(nvpair)
                    % +Name:atom
                    % :Predicate
                    % -OldValue
                    % -NewOptions:list(nvpair)
  ]
).

/** <module> Option list handling extension

Extensions to the swipl buitin handling of option lists.

This module allows the use of default option values in option/3 that have
arbitrary arity. The swipl builtin only handles default values for the
first argument position in the given option term (probably under the
assumption that the option term will always be unary).

@author Wouter Beek
@version 2013/01, 2013/07-2013/08, 2013/11
*/

:- use_module(library(apply)).
:- use_module(library(lists)).
:- use_module(library(option)).

:- meta_predicate(update_option(+,+,2,-)).
:- meta_predicate(update_option(+,+,2,-,-)).



%! default_option(
%!   +OldOptions:list(nvpair),
%!   +Name:atom,
%!   +DefaultValue,
%!   -NewOptions:list(nvpair)
%! ) is det.
% @see default_option/5

default_option(OldOptions, Name, DefaultValue, NewOptions):-
  default_option(OldOptions, Name, DefaultValue, _StoredValue, NewOptions).

%! default_option(
%!   +OldOptions:list(nvpair),
%!   +Name:atom,
%!   +DefaultValue,
%!   -StoredValue,
%!   -NewOptions:list(nvpair)
%! ) is det.
% Gives either the stored value, if it is available,
% or the given default value.

default_option(Options, Name, _DefaultValue, StoredValue, Options):-
  Option =.. [Name,StoredValue],
  option(Option, Options), !.
default_option(OldOptions, Name, DefaultValue, DefaultValue, NewOptions):-
  Option =.. [Name,DefaultValue],
  merge_options([Option], OldOptions, NewOptions).

%! option_add(
%!   +FromOptions:list(nvpair),
%!   +Name:atom,
%!   +Value:atom,
%!   +ToOptions:list(nvpair)
%! ) is det.

option_add(O1, N, V, O2):-
  option_format(N=V, O),
  merge_options([O], O1, O2).

option_ext(Option, Options, Default):-
  functor(Option, Name, Arity),
  functor(MatchOption, Name, Arity),
  (
    % Case 1: The option can be matched in the options list.
    % For this case we use the swipl builtin get_option/3.
    swi_option:get_option(MatchOption, Options)
  ->
    Option = MatchOption
  ;
    % Case 2: The option cannot be matched in the options list,
    % but the default option has the same functor and arity.
    % This is the extension to the swipl builin predicate, allowing
    % the formulation of default values of arbitrary arity.
    functor(Default, Name, Arity)
  ->
    Option = Default
  ;
    % Case 3: The option cannot be matched in the options list and the
    % defualt value is assumed to unify with the first argument position
    % of the given option term.
    arg(1, Option, Default)
  ).

%! option_format(+AnyOption, -NondepOption) is det.
% Ensures that an option uses the non-depracated format:
% ~~~
% Name(Value)
% ~~~
%
% Also allows the deprecated format as input:
% ~~~
% Name=Value
% ~~~

option_format(Name=Value, Name=Value):- !.
option_format(Option, Name=Value):-
  Option =.. [Name,Value].

option_format(Name=Value, Name, Value):- !.
option_format(Option, Name, Value):-
  Option =.. [Name,Value].

option_member(Option1, Options):-
  option_format(Option1, Option2),
  member(Option2, Options).

option_memberchk(Option1, Options):-
  option_format(Option1, Option2),
  memberchk(Option2, Options).

%! replace_option(
%!   +OldOptions:list(nvpair),
%!   +Name:atom,
%!   +NewValue,
%!   -OldValue,
%!   -NewOptions:list(nvpair)
%! ) is det.

replace_option(OldOptions, Name, NewValue, OldValue, NewOptions):-
  OldOption =.. [Name,OldValue],
  select_option(OldOption, OldOptions, TempOptions),
  NewOption =.. [Name,NewValue],
  merge_options([NewOption], TempOptions, NewOptions).

subtract_option(Old1, Del1, New):-
  maplist(option_format, Old1, Old2),
  maplist(option_format, Del1, Del2),
  subtract(Old2, Del2, New).

update_option(OldOptions, Name, Predicate, NewOptions):-
  update_option(OldOptions, Name, Predicate, _OldValue, NewOptions).

update_option(OldOptions, Name, Predicate, OldValue, NewOptions):-
  OldOption =.. [Name,OldValue],
  select_option(OldOption, OldOptions, TempOptions),
  call(Predicate, OldValue, NewValue),
  NewOption =.. [Name,NewValue],
  merge_options([NewOption], TempOptions, NewOptions).

