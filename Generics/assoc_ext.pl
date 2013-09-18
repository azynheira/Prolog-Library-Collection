:- module(
  assoc_ext,
  [
    get_assoc_ord_member/3, % +Key
                            % +Assoc:assoc
                            % ?Value
    put_assoc_ord_member/4, % +Key
                            % +OldAssoc:assoc
                            % +Value
                            % -NewAssoc:assoc
% DEBUG
    print_assoc/1, % +Assoc:assoc
    print_assoc/3 % +Indent:nonneg
                  % :KeyTransform
                  % +Assoc:assoc
  ]
).

/** <module> Association list extension

An association list with multiple values per key, using ordered sets.

@author Wouter Beek
@version 2013/04-2013/05, 2013/07-2013/09
*/

:- use_module(generics(print_ext)).
:- use_module(library(assoc)).
:- use_module(library(debug)).
:- use_module(library(lists)).
:- use_module(library(ordsets)).

:- meta_predicate(print_assoc(+,2,+)).

:- nodebug(assoc_ext).



%! get_assoc_ord_member(+Key, +Assoc:assoc, ?Value) is nondet.

get_assoc_ord_member(Key, Assoc, Value):-
  get_assoc(Key, Assoc, Set),
  ord_member(Value, Set).

%! ord_member(+Member, +Set:ordset) is semidet.
%! ord_member(-Member, +Set:ordset) is nondet.
% @see Wrapper around ord_memberchk/2 (when instantiation is =|(+,+)|=)
%      and member/2 (when instantiation is =|(-,+)|=).

ord_member(Value, Ordset):-
  nonvar(Value), !,
  ord_memberchk(Value, Ordset).
ord_member(Value, Ordset):-
  member(Value, Ordset).

%! put_assoc_ord_member(
%!   +Key,
%!   +OldAssoc:assoc,
%!   +Value,
%!   -NewAssoc:assoc
%! ) is det.

% An ordered set already exists as the value of the given key.
put_assoc_ord_member(Key, Assoc1, Value, Assoc2):-
  get_assoc(Key, Assoc1, Set1), !,
  ord_add_element(Set1, Value, Set2),
  put_assoc(Key, Assoc1, Set2, Assoc2),
  
  % DEB
  length(Set2, NewSetLength),
  debug(
    assoc_ext,
    'Added <~w,~w> to existing assoc, whose value set is now of length ~w.',
    [Key,Value,NewSetLength]
  ).
% The given key has no value, so a new ordered set is created.
put_assoc_ord_member(Key, Assoc1, Value, Assoc2):-
  list_to_ord_set([Value], Set),
  put_assoc(Key, Assoc1, Set, Assoc2),
  debug(assoc_ext, 'Added <~w,~w> to NEW assoc.', [Key,Value]).

print_assoc(Assoc):-
  print_assoc(0, term_to_atom, Assoc).

print_assoc(KeyIndent, KeyTransform, Assoc):-
  is_assoc(Assoc),
  assoc_to_keys(Assoc, Keys),
  ValueIndent is KeyIndent + 1,
  forall(
    member(Key, Keys),
    (
      indent(KeyIndent),
      call(KeyTransform, Key, KeyName),
      format('~w:\n', [KeyName]),
      forall(
        get_assoc(Key, Assoc, Value),
        (
          indent(ValueIndent),
          call(KeyTransform, Value, ValueName),
          format('~w\n', [ValueName])
        )
      )
    )
  ).
