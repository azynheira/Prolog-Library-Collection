:- module(
  svg_generic,
  [
    svg_head/2, % +Size:size
                % -Head:list
    svg_head/3, % +Width:number
                % +Height:number
                % -Head:list
    svg_namespace//1 % :DCG_Namespace
  ]
).

/** <module> SVG generic

@author Wouter Beek
@version 2012/10, 2013/01-2013/08
*/

:- use_module(dcg(dcg_content)).

:- meta_predicate(svg_namespace(//,?,?)).

% SVG public identifier.
:- dynamic(user:public_identifier/2).
user:public_identifier(svg, 'PUBLIC "-//W3C//DTD SVG 1.1//EN"').

% SVG system identifier.
:- dynamic(user:system_identifier/2).
user:system_identifier(svg,
    'http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd').



%! svg_head(+Size:size, -Head:list) is det.
% Returns the markup for the SVG head for graphics with the given 2D size.
%
% @see Wrapper around svg_head/3.

svg_head(size(2,[Width,Height]), Head):-
  svg_head(Width, Height, Head).

%! svg_head(+Width:integer, +Height:integer, -Head:list) is det.
% Returns the markup for the SVG head for graphics with the given
% height and width.

svg_head(Width, Height, [height=Height_cm, width=Width_cm]):-
  atomic_list_concat([Width,cm], Width_cm),
  atomic_list_concat([Height,cm], Height_cm).

svg_namespace(DCG_Namespace) -->
  {phrase(DCG_Namespace, "svg")},
  void.
svg_namespace(DCG_Namespace) -->
  DCG_Namespace.
