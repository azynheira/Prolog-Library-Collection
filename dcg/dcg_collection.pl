:- module(
  dcg_collection,
  [
    collection//6, % :Begin
                   % :End
                   % :Ordering
                   % :Separator
                   % :ElementWriter
                   % +Elements:list
    list//2, % :ElementWriter
             % +Elements:list
    nvpair//3, % :ElementWriter
               % +Name
               % +Value
    pair//3, % +Mode:oneof([ascii,html])
             % :ElementWriter
             % +Pair:pair
    pair//4, % +Mode:oneof([ascii,html])
             % :ElementWriter
             % +Element1
             % +Element2
    set//2, % :ElementWriter
            % +Elements:list
    tuple//3 % +Mode:oneof([ascii,html])
             % :ElementWriter
             % +Elements:list
  ]
).

/** <module> DCG collection

DCG rules for generating collections.
This module supports the following collection properties:
  - Collections may contain other collections as their elements.
  - Arbitrary DCGs generate the `Begin` and `End` of the collection.
  - An arbitrary DCG separates elements in the collection, i.e. `Separator`.
  - Each element is written with the same DCG rule `ElementWriter`.

For convenience's sake, the following collection instances are supported:
  - List
  - Name-value pair
  - Pair
  - Set
  - Tuple

@author Wouter Beek
@version 2013/07-2013/09, 2013/11-2014/01 2014/03, 2014/05
*/

:- use_module(library(option)).

:- use_module(dcg(dcg_ascii)).
:- use_module(dcg(dcg_content)).
:- use_module(dcg(dcg_error)).
:- use_module(dcg(dcg_generic)).
:- use_module(dcg(dcg_meta)).
:- use_module(generics(meta_ext)).
:- use_module(generics(option_ext)).

:- meta_predicate(collection(//,//,2,//,3,+,?,?)).
:- meta_predicate(collection_inner(//,//,2,//,3,+,?,?)).
:- meta_predicate(list(3,+,?,?)).
:- meta_predicate(nvpair(3,+,+,?,?)).
:- meta_predicate(pair(+,3,+,?,?)).
:- meta_predicate(pair(+,3,+,+,?,?)).
:- meta_predicate(set(3,+,?,?)).
:- meta_predicate(tuple(+,3,+,?,?)).



%! collection(
%!   :Begin,
%!   :End,
%!   :Ordering,
%!   :Separator,
%!   :ElementWriter,
%!   +Elements:list
%! )// is det.
% Generates a represention of the collection of given elements.
%
% @arg Begin DCG rule that is called before the first element.
% @arg End DCG rule that is called after the last element.
% @arg Ordering Binary predicate that orders the given elements.
% @arg Separator DCG rules that is called in between each two elements.
% @arg ElementWriter Unary DCG rule that writes a single element.
% @arg Elements A list of ground terms that denote
%      the members of the collection.

collection(Begin, End, Ordering, Separator, ElementWriter, Elements1) -->
  % Allow an arbitrary ordering to be enforced, e.g. list_to_set/2.
  {
    default(=, Ordering),
    once(call(Ordering, Elements1, Elements2))
  },
  Begin,
  collection_inner(Begin, End, Ordering, Separator, ElementWriter, Elements2),
  End.

% Done!
collection_inner(_, _, _, _, _, []) --> [].
% Nested collection.
collection_inner(Begin, End, Ordering, Separator, ElementWriter, [H|T]) -->
  {is_list(H)}, !,
  collection(Begin, End, Ordering, Separator, ElementWriter, H),
  collection_inner(Begin, End, Ordering, Separator, ElementWriter, T).
% Non-collection element in collection.
collection_inner(Begin, End, Ordering, Separator, ElementWriter, [H|T]) -->
  dcg_call(ElementWriter, H),
  dcg_yn_separator(T, Separator),
  collection_inner(Begin, End, Ordering, Separator, ElementWriter, T).


%! list(:ElementWriter, +Elements:list)// is det.
% Lists are printed recursively, using indentation relative to the given
% indentation level.

list(ElementWriter, Elements) -->
  collection(`[`, `]`, =, `,`, ElementWriter, Elements).


%! nvpair(:ElementWriter, +Name, +Value)// is det.

nvpair(ElementWriter, Name, Value) -->
  collection(``, `;`, =, `: `, ElementWriter, [Name,Value]).


%! pair(+Mode:oneof([ascii,html]), :ElementWriter, +Pairs:pair)// is det.

pair(Mode, ElementWriter, E1-E2) -->
  pair(Mode, ElementWriter, E1, E2).


%! pair(
%!   +Mode:oneof([ascii,html]),
%!   :ElementWriter,
%!   +Element1,
%!   +Element2
%! )// is det.
% Prints the given pair.
%
% @arg Mode The kind of brackets that are printed for this pair.
%      Either `ascii` for using the ASCII characters `<` and `>` (default)
%      or `html` for using the HTML escape sequences `&lang;` and `&rang;`.
% @arg ElementWriter
% @arg Element1
% @arg Element2

pair(Mode, ElementWriter, E1, E2) -->
  {default(ascii, Mode)},
  collection(langle(Mode), rangle(Mode), =, `,`, ElementWriter, [E1,E2]).


%! set(:ElementWriter, +Elements:list)// is det.

set(ElementWriter, L) -->
  collection(`{`, `}`, list_to_ord_set, `,`, ElementWriter, L).


%! tuple(+Mode:oneof([ascii,html]), :ElementWriter, +Elements:list)// is det.
% Prints a tuple.
%
% @arg Mode The kind of brackets that are printed for this pair.
%      Either `ascii` for using the ASCII characters `<` and `>` (default)
%      or `html` for using the HTML escape sequences `&lang;` and `&rang;`.
% @arg ElementWriter
% @arg Elements

tuple(Mode, ElementWriter, L) -->
  {default(ascii, Mode)},
  collection(langle(Mode), rangle(Mode), =, `,`, ElementWriter, L).



% HELPERS %

langle(ascii) --> `<`.
langle(html) --> `&lang;`.

rangle(ascii) --> `>`.
rangle(html) --> `&rang;`.

