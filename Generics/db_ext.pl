:- module(
  db_ext,
  [
    assert_novel/1 % +Term
  ]
).

/** <module> DB_EXT

Database extensions.

@author Wouter Beek
@version 2013/04
*/



assert_novel(Term):-
  call(Term),
  !.
assert_novel(Term):-
  assertz(Term).

