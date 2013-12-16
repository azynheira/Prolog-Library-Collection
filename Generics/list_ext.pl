:- module(
  list_ext,
  [
    after/3, % ?Element2
             % ?Element1
             % ?List:list
    append_intersperse/3, % +List:list
                          % +Separator
                          % -NewList:list
    before/3, % ?Element1
              % ?Element2
              % ?List:list
    combination/2, % +Lists:list(list)
                   % -Combination:list
    element_cut/4, % +List:list
                   % +Element
                   % -List1:list
                   % -List2:list
    first/2, % +List:list,
             % ?First
    first/3, % +List:list,
             % +N:integer
             % -Firsts:list
    icompare/3, % ?InvertedOrder
                % @Term1
                % @Term2
    length_cut/4, % +L:list
                  % +Cut:integer
                  % -L1:list
                  % -L2:list
    list_replace/3, % +List:list
                    % +Replacements:list(pair)
                    % -NewList:list
    list_separator_concat/3, % +Lists:list(list)
                             % +Separator:list
                             % ?List:list
    list_to_ordered_pairs/2, % +L:list
                             % -Pairs:ordset(ordset)
    member/3, % ?Element1
              % ?Element2
              % ?List:list
    member_default/3, % +Member
                      % +List:list
                      % +Default
    nth_minus_0/3, % +Index:integer
                   % +List:list
                   % -Element:term
    nth_minus_1/3, % +Index:integer
                   % +List:list
                   % -Element:term
    nth0chk/3, % ?Index:integer
               % ?List:List
               % ?Element
    nth1chk/3, % ?Index:integer
               % ?List:List
               % ?Element
    random_member/2, % +List:list
                     % -Member
    random_select/3, % +List:list
                     % -Member
                     % -Rest:list
    random_sublist/3, % +List:list
                      % +LengthOrPercentage:or([nonneg,between(0.0,1.0)])
                      % -Sublist:list
    remove_first/2, % +List:list,
                    % -NewList:list
    remove_firsts/2, % +List:list
                     % -NewList:list
    remove_last/2, % +List:list
                   % -NewList:list
    repeating_list/3, % +Term:term
                      % +Repeats:integer
                      % -List:list(object)
    replace_nth/6, % +StartIndex:index
                   % ?Index:index
                   % +OldList:list
                   % ?OldElement
                   % +NewElement
                   % -NewList:list
    replace_nth0/5, % ?Index:nonneg
                    % +OldList:list
                    % ?OldElement
                    % +NewElement
                    % -NewList:list
    replace_nth1/5, % ?Index:positive_integer
                    % +OldList:list
                    % ?OldElement
                    % +NewElement
                    % -NewList:list
    shorter/3, % +Comparator:pred
               % +List1:list
               % +List2:list
    split_list_by_number_of_sublists/3, % +List:list
                                        % +NumberOfSublists:nonneg
                                        % -Sublists:list(list)
    split_list_by_size/3, % +List:list
                          % +SizeOfSublists:integer
                          % -Sublists:list(list)
    split_list_exclusive/3, % +List:list
                            % +Split:list
                            % -Sublists:list(list)
    strict_sublist/2, % ?SubList:list
                      % +List:list
    sublist/2, % ?SubList:list
               % +List:list

% SORTING
    sort/3 % +Options:list(nvpair)
           % +:List:list
           % -Sorted:list
  ]
).

/** <module> LIST_EXT

Extra list functions for use in SWI-Prolog.

@author Wouter Beek
@version 2011/08-2012/02, 2012/09-2012/10, 2012/12, 2013/03, 2013/05,
         2013/07, 2013/09, 2013/12
*/

:- use_module(generics(meta_ext)).
:- use_module(generics(typecheck)).
:- use_module(library(lists)).
:- use_module(library(option)).
:- use_module(math(random_ext)).



%! after(?X, ?Y, ?List:list) is nondet.
% X appears after Y in the given list.

after(X, Y, List):-
  before(Y, X, List).

%! append_intersperse(+List:list, +Separator, -NewList:list)//
% Returns a list that is based on the given list, but interspersed with
% copies of the separator term.
%
% If the length of the given list is `n`, then the length of the new list
% is `2n - 1` for `n > 0`.

append_intersperse([], _S, []):- !.
append_intersperse([H], _S, [H]):- !.
append_intersperse([H|T1], S, [H,S|T2]):-
  append_intersperse(T1, S, T2).

%! before(?X, ?Y, ?List:list) is nondet.
% X appears before Y in the given list.

before(X, Y, List):-
  nextto(X, Y, List).

%! combination(+Lists:list(list), -Combination:list) is nondet.
% Returns a combination of items from the given lists.
%
% ## Example
%
% ~~~
% ?- combination([[1,2,3],[4,5]], C).
% C = [1, 4] ;
% C = [1, 5] ;
% C = [2, 4] ;
% C = [2, 5] ;
% C = [3, 4] ;
% C = [3, 5].
% ~~~
%
% @param Lists A list of lists of terms.
% @param Combination A list of terms.

combination([], []).
combination([ListH|ListT], [H|T]):-
  member(H, ListH),
  combination(ListT, T).

%! element_cut(+L:list, +Element:atom, -L1:list, -L2:list) is det.
% Cuts the given list at the given element, returning the two cut lists.
% The cut element is itself not part of any of the results.
%
% @param L The list that is to be cut.
% @param Element The element at which the cut is made.
% @param L2 The list of elements that occur before the cut.
% @param L2 The list of elements that occur after the cut.

element_cut([], _Element, [], []):- !.
element_cut([Element | T], Element, [], T):- !.
element_cut([OtherElement | L], Element, [OtherElement | L1], L2):-
  element_cut(L, Element, L1, L2).

%! first(+List:list, ?Element:term) is semidet.
% Succeeds if the given element is the head of the given list.
% Fails if the list has no head.
%
% @param List Any list.
% @param Element The head element of the list, if any.
% @see This is the inverse of the default method last/2.

first([Element | _List], Element).

%! first(+L:list, +N:integer, -First:list) is det.
% Returns the first N element from list L, if these are present.
% This never fails but returns a list of length $0 < l(F) < N$ in case
% $l(L) < N$.
%
% @param L The given list.
% @param N The length of the returned sublist.
% @param First The prepended sublist of =L=.

first(L, N, First):-
  length_cut(L, N, First, _L2).

%! length_cut(+L:list, +Cut:integer, -L1:list, -L2:list) is det.
% Cuts the given list in two sublists, where the former sublist
% has the given length.
%
% @param L The full list.
% @param Cut An integer indicating the length of the former sublist.
% @param L1 The sublist that is the beginning of =L= with length =Cut=.
% @param L2 The sublist that remains after =L1= has been removed from =L=.

length_cut(L, Cut, L, []):-
  length(L, N),
  N < Cut, !.
length_cut(L, Cut, L1, L2):-
  length(L1, Cut),
  append(L1, L2, L).

%! list_replace(
%!   +List:list,
%!   +Replacements:list(term-term),
%!   -NewList:list
%! ) is det.
% Returns the given list in which the given replacements have been made.
%
% @param List The original list.
% @param Replacements A list of replacements of the form =|term-term|=.
% @param NewList The list in which all replacants have been replaced.

% Done!
list_replace([], _Maps, []):- !.
% Match one of the replicants.
list_replace(L1, Maps, L2):-
  member(From-To, Maps),
  append(From, Rest1, L1), !,
  list_replace(Rest1, Maps, Rest2),
  (
    is_list(To)
  ->
    append(To, Rest2, L2)
  ;
    L2 = [To|Rest2]
  ).
% A non-matching element.
list_replace([H|T1], Maps, [H|T2]):-
  list_replace(T1, Maps, T2).

list_separator_concat([], _Separator, []):- !.
list_separator_concat([List], _Separator, [List]):- !.
list_separator_concat([List | Lists], Separator, NewList):-
  append(List, Separator, FirstList),
  list_separator_concat(Lists, Separator, RestLists),
  append(FirstList, RestLists, NewList).

%! list_to_ordered_pairs(+L:list, -Pairs:ordset(ordset)) is det.
% Returns the ordered list of ordered pairs that occur in the given list.
%
% @param L The given list.
% @param Pairs An ordered list of ordered pairs.

list_to_ordered_pairs([], []):- !.
% The pairs need to be internally ordered, but the order in which the
% pairs occur is immaterial.
list_to_ordered_pairs([H|T], S):-
  list_to_orderd_pairs_(H, T, S1),
  list_to_ordered_pairs(T, S2),
  append(S1, S2, S).

list_to_orderd_pairs_(_H, [], []):- !.
list_to_orderd_pairs_(H, [T|TT], [Pair|S]):-
  list_to_ord_set([H,T], Pair),
  list_to_orderd_pairs_(H, TT, S).

%! member(X, Y, L) is nondet.
% Pairs from a list.
%
% @param X The first argument of the pair.
% @param Y The second argument of the pair.
% @param L The list from which pairs are taken.

member(X, Y, L):-
  member(X, L),
  member(Y, L).

member_default(Member, List, _Default):-
  member(Member, List), !.
member_default(Default, _List, Default).

%! nth_minus_0(+I:integer, +L:list, -Element) is det.
% Succeeds if the given element occurs at =|length(List) - I|= in list =L=.
%
% @param I The index, an integer in =|[0, length(List) - 1]|=.
% @param L Any list.
% @param Element An element occurring in the given list.
% @see The inverse of default method nth0/3.

nth_minus_0(I, L, Element):-
  reverse(L, RevL),
  nth0(I, RevL, Element).

%! nth_minus_1(-I:integer, +L:list, +Element) is semidet.
% Succeeds if the given element occurs at =|length(L) - I|= in list =L=.
%
% @param I The index, an integer in =|[0, length(List)]|=.
% @param L Any list.
% @param Element An element occurring in the given list.
% @see The inverse of default method nth1/3.

nth_minus_1(I, L, Element):-
  reverse(L, RevL),
  nth1(I, RevL, Element).

%! nth0chk(?Index:integer, ?List:list, ?Element) is det.

nth0chk(Index, List, Element):-
  once(nth0(Index, List, Element)).

%! nth1chk(?Index:integer, ?List:list, ?Element) is det.

nth1chk(Index, List, Element):-
  once(nth1(Index, List, Element)).

%! random_member(+List:list, -Member) is det.
% Returns a randomly chosen member from the given list.
%
% @param List
% @param Member

random_member(List, Member):-
  length(List, Length),
  random_betwixt(Length, Random),
  nth0(Random, List, Member).

%! random_select(+List:list, -Member, -List:list) is det.
% Randomly selects a member from the given list,
% returning the remaining list as well.

random_select(L1, X, L2):-
  length(L1, M),
  random_select(L1, M, X, L2).

random_select(L1, M, X, L2):-
  random_betwixt(M, Rnd),
  nth0(Rnd, L1, X, L2).

random_sublist(L1, Percentage, L2):-
  is_between(0.0, 1.0, Percentage), !,
  length(L1, M),
  N is ceil(M * Percentage),
  random_sublist(L1, M, N, L2).
random_sublist(L1, N, L2):-
  nonneg(N), !,
  length(L1, M),
  random_sublist(L1, M, N, L2).

random_sublist(L1, M, N, L2):-
  random_sublist(L1, M, N, [], L2).

random_sublist(_L1, _M, 0, Sol, Sol):- !.
random_sublist(L1, M1, N1, T, Sol):-
  random_select(L1, M1, H, L2),
  N2 is N1 - 1,
  M2 is M1 - 1,
  random_sublist(L2, M2, N2, [H|T], Sol).

%! remove_first(+List, -ListWithoutFirst)
% Returns a list that is like the given list, but without the first element.
% Fails if there is no first element in the given list.
%
% @param List Any nonempty list.
% @param ListWithoutFirst A new list without the first elemnent.
% @see The inverse of remove_last/2.

remove_first([_First | ListWithoutFirst], ListWithoutFirst).

%! remove_firsts(+Lists, -ListsWithoutFirst)
% Returns the given lists without the first elements.
%
% @param Lists Any list of non-empty lists.
% @param ListsWithoutFirst ...
% @see Uses remove_first/2.

remove_firsts([], []).
remove_firsts(
  [List | Lists],
  [ListWithoutFirst | ListsWithoutFirst]
):-
  remove_first(List, ListWithoutFirst),
  remove_firsts(Lists, ListsWithoutFirst).

%! remove_last(+List, -NewList)
% Returns the given list with the last element removed.
%
% @param List The original list.
% @param NewList The original list with the last element remove.
% @see The inverse of remove_first/2.

remove_last([], []).
remove_last([Element], []):-
  atomic(Element).
remove_last([Element | Rest], [Element | NewRest]):-
  remove_last(Rest, NewRest).

%! repeating_list(+Term:term, +Repeats:integer, -List:list(term)) is det.
% Returns the list of the given number of repeats of the given term.
%
% @param Term
% @param Repeats
% @param List

repeating_list(Object, Repeats, List):-
  nonvar(List), !,
  repeating_list1(Object, Repeats, List).
repeating_list(Object, Repeats, List):-
  nonvar(Repeats), !,
  repeating_list2(Object, Repeats, List).

%! repeating_list1(-Object, -Repeats:integer, +List:list) is nondet.
% Returns the object and how often it occurs in the repeating list.

repeating_list1(_Object, 0, []).
repeating_list1(Object, Repeats, [Object|T]):-
  forall(
    member(X, T),
    X = Object
  ),
  length([Object | T], Repeats).

%! repeating_list2(+Object, +Repeats:integer, -List:list) is det.

repeating_list2(_Object, 0, []):- !.
repeating_list2(Object, Repeats, [Object|List]):-
  succ(NewRepeats, Repeats),
  repeating_list2(Object, NewRepeats, List).

%! replace_nth(
%!   +StartIndex:integer,
%!   ?Index:integer,
%!   +OldList:list,
%!   ?OldElement,
%!   +NewElement,
%!   -NewList:list
%! ) is det.
% Performs rather advanced in-list replacements.
%
% ## Examples
%
% Consecutive applications:
% ~~~
% ?- L1 = [[1,2,3],[4,5,6],[7,8,9]], replace_nth0(1, L1, E1, E2, L2), replace_nth0(2, E1, 6, a, E2).
% L1 = [[1, 2, 3], [4, 5, 6], [7, 8, 9]],
% E1 = [4, 5, 6],
% E2 = [4, 5, a],
% L2 = [[1, 2, 3], [4, 5, a], [7, 8, 9]].
% ~~~
%
% Alternative indexes:
% ~~~
% ?- list_ext:replace_nth1(I, [a,b,a], a, x, L2).
% I = 1,
% L2 = [x, b, a] ;
% I = 3,
% L2 = [a, b, x] ;
% false.
% ~~~
%
% @author Jan Wielemaker
% @author Richard O'Keefe
% @author Stefan Ljungstrand
% @author Wouter Beek
% @see The original implementation by Jan and Richard
%      used to start at index 1:
%      http://www.swi-prolog.org/pldoc/doc/home/vnc/prolog/lib/swipl/library/record.pl?show=src
% @see Stefan added the new and old element arguments on 2013/11/02
%      when we were discussing this on the ##prolog channel.

% If the index is given, then the predicate is (semi-)deterministic.
replace_nth(I1, I, L1, E1, E2, L2):-
  nonvar(I), !,
  I >= I1,
  replace_nth_(I1, I, L1, E1, E2, L2), !.
% If the index is not given, then there may be multiple answers.
replace_nth(I1, I, L1, E1, E2, L2):-
  replace_nth_(I1, I, L1, E1, E2, L2).

replace_nth_(I, I, [E1|T], E1, E2, [E2|T]).
replace_nth_(I1, I, [H|T1], E1, E2, [H|T2]):-
  I2 is I1 + 1,
  replace_nth_(I2, I, T1, E1, E2, T2).

%! replace_nth0(
%!   +Index:integer,
%!   +OldList:list,
%!   +OldElement,
%!   +NewElement,
%!   -NewList:list
%! ) is det.
% Performs rather advanced in-list replacements, counting from index 0.
%
% @see Wrapper around replace_nth/6.

replace_nth0(I, L1, E1, E2, L2):-
  replace_nth(0, I, L1, E1, E2, L2).

%! replace_nth1(
%!   +Index:integer,
%!   +OldList:list,
%!   +OldElement,
%!   +NewElement,
%!   -NewList:list
%! ) is det.
% Performs rather advanced in-list replacements, counting from index 1.
%
% @see Wrapper around replace_nth/6.

replace_nth1(I, L1, E1, E2, L2):-
  replace_nth(1, I, L1, E1, E2, L2).

%! shorter(+Order:pred/2, +List:list(term), +List2:list(term)) is semidet.
% Succeeds if =List1= has relation =Order= to =List2=.
%
% @param Order A binary predicate. Either <, =, or >.
% @param List1 A list of objects.
% @param List2 A list of objects.

shorter(Order, List1, List2):-
  length(List1, Length1),
  length(List2, Length2),
  compare(Order, Length2, Length1).

%! split_list_by_number_of_sublists(
%!   +List:list,
%!   +NumberOfSublists:nonneg,
%!   -Sublists:list(list)
%! ) is det.

split_list_by_number_of_sublists(List, NumberOfSublists, Sublists):-
  length(List, Length),
  Length > NumberOfSublists, !,
  succ(ReducedNumberOfSublists, NumberOfSublists),
  SizeOfSublists is Length div ReducedNumberOfSublists,
  split_list_by_size(List, SizeOfSublists, Sublists).
split_list_by_number_of_sublists(List, _NumberOfSublists, List).

%! split_list_by_size(
%!   +List:list,
%!   +MaxmimumLength:integer,
%!   -SubLists:list(list)
%! ) is det.
% Splits the given list into lists of maximally the given length.

% The last sublists is exactly of the requested size.
% The empty list indicates this.
split_list_by_size([], _SizeOfSublists, []):- !.
% The main case: use length/2 and append/3 to extract the list
% prefix that is one of the sublist results.
split_list_by_size(List, SizeOfSublists, [Sublist | Sublists]):-
  length(Sublist, SizeOfSublists),
  append(Sublist, NewList, List), !,
  split_list_by_size(NewList, SizeOfSublists, Sublists).
% The last sublist is not exactly of the requested size. Give back
% what remains.
split_list_by_size(LastSublist, _SizeOfSublists, [LastSublist]).

%! split_list_exclusive(+List:list, +Split:list, -Chunks:list(list)) is det.

split_list_exclusive(List, Split, Chunks):-
  split_list_exclusive(List, Split, [], Chunks).

% The final chunk.
split_list_exclusive([], _Split, Chunk, [Chunk]):- !.
% Process a split.
split_list_exclusive(
  [Match | List1],
  [Match | Split],
  Chunk,
  [Chunk | Chunks]
):-
  append(Split, List2, List1), !,
  split_list_exclusive(List2, [Match | Split], [], Chunks).
% Process a chunk.
split_list_exclusive([Part | List], Split, Chunk, Chunks):-
  split_list_exclusive(List, Split, [Part | Chunk], Chunks).

%! sublist(?SubList:list, +List:list) is nondet.
% Returns sublists of the given list.

sublist([], []).
sublist([H | SubT], [H | T]):-
  sublist(SubT, T).
sublist(SubT, [_H | T]):-
  sublist(SubT, T).



% SORTING %

%! i(?Order1, ?Order2) is nondet.
% Inverter of order relations.
% This is used for sorting with the =inverted= option set to =true=.
%
% @param Order1 An order relation, i.e. <, > or =.
% @param Order1 An order relation, i.e. <, > or =.

i(<, >).
i(>, <).
i(=, =).

%! icompare(?InvertedOrder, @Term1, @Term2) is det.
% Determine or test the order between two terms in the inversion of the
% standard order of terms.
% This allows inverted sorting, useful for some algorithms that can
% operate (more) quickly on inversely sorted operations, without the
% cost of reverse/2.
% This is used for sorting with the =inverted= option set to =true=.
%
% @param InvertedOrder One of <, > or =.
% @param Term1
% @param Term2
% @see compare/3 using uninverted order predicates.

icompare(InvertedOrder, Term1, Term2):-
  compare(Order, Term1, Term2),
  i(Order, InvertedOrder).

%! sort(+Options:list(nvpair), +List:list, -Sorted:list) is det.
% @param Options A list of name-value pairs. The following options are
%        supported:
%        1. =|duplicates(boolean)|= Whether duplicate elements are retained
%           in the sorted list.
%        2. =|inverted(boolean)|= Whether the sorted list goes from lowest to
%           highest (standard) or from highest to lowest.

% The combination of _inverted_ and _|no duplicates|_ uses a dedicated
% comparator. This is cheaper that first sorting and then reversing the
% results.
sort(Options, List, Sorted):-
  option(inverted(true), Options, false),
  option(duplicates(false), Options, false), !,
  predsort(icompare, List, Sorted).
sort(Options, List, Sorted):-
  (
    option(duplicates(true), Options, false)
  ->
    msort(List, Sorted0)
  ;
    sort(List, Sorted0)
  ),
  (
    option(inverted(true), Options, false)
  ->
    reverse(Sorted0, Sorted)
  ;
    Sorted = Sorted0
  ).

strict_sublist(SubList, List):-
  sublist(SubList, List),
  SubList \== List.

