:- module(
  ugraph_export,
  [
    export_ugraph/4 % +Options:list(nvpair)
                    % :CoordFunc
                    % +Graph:ugraph
                    % -GraphTerm:compound
  ]
).

/** <module> UGRAPH_EXPORT

Predicates for exporting undirected graphs.

# The intermediate graph format

  graph(Vs, Ranks, Es, G_Attrs)

The following attributes are supported:
  * `label(Name:atom)`

## Ranks format

  rank(RankVertex, ContentVertices)

## Vertex format

  vertex(V_Id, V_Attrs)

The following attributes are supported:
  * `color(Color:atom)`
  * `coord(Coord:coord)`
  * `label(Name:atom)`
  * `radius(Radius:float)`

## Edge format

  edge(FromV/FromV_Id, ToV/ToV_Id, E_Attrs)

The following attributes are supported:
  * `arrow_type(ArrowType:atom)`
  * `color(Color:atom)`
  * `label(Name:atom)`
  * `style(Style:atom)`

@author Wouter Beek
@version 2013/02-2013/03, 2013/07
*/

:- use_module(graph_theory(ugraph_ext)).
:- use_module(library(lists)).

:- meta_predicate(export_ugraph(+,4,+,+)).

:- setting(
  charset,
  oneof(['UTF-8']),
  'UTF-8',
  'The default encoding for undirected graph exports.'
).
:- setting(
  color_scheme,
  oneof([none,svg,x11]),
  svg,
  'The default color_scheme used for exporting undirected graphs.'
).
:- setting(
  font_size,
  float,
  11.0,
  'The default font size for text that occurs in undirected graph exports.'
).
:- setting(
  overlap,
  boolean,
  false,
  'The default for overlap in undirected graph exports.'
).
:- setting(radius, float, 0.1, 'The default radius of vertices.').



% GRAPH %

%! export_ugraph(
%!   +Options:list(nvpair),
%!   :CoordFunc,
%!   +Graph:ugraph,
%!   -GraphTerm:compound
%! ) is det.
% Exports the given unordered graph to the intermediate graph format.
%
% @arg Options Supported values:
%      * `border(+Border:coord)`
%      * `surface(+Surface:coord)`
% @arg CoordFunc A function that maps vertices to coordinates.
% @arg Graph An undirected graph.
% @arg GraphTerm A compound term in the intermediate graph format.

export_ugraph(O, CoordFunc, G, graph(V_Terms, [], E_Terms, G_Attrs)):-
  % Vertices.
  ugraph_vertices(G, Vs),
  findall(
    V_Term,
    (
      member(V, Vs),
      ugraph_vertex(O, V, Vs, V_Term)
    ),
    V_Terms
  ),
  
  % Edges.
  ugraph_edges(G, Es),
  findall(
    E_Term,
    (
      member(E, Es),
      ugraph_edge(E, Vs, E_Term)
    ),
    E_Terms
  ),
  
  % Graph properties.
  ugraph_name(G, G_Name),
  setting(charset, Charset),
  setting(color_scheme, ColorScheme),
  setting(font_size, FontSize),
  setting(overlap, Overlap),
  G_Attrs = [
    charset(Charset),
    color_scheme(ColorScheme),
    font_size(FontSize),
    label(G_Name),
    overlap(Overlap)
  ].



% EDGE %

ugraph_edge(FromV-ToV, Vs, edge(FromV/FromV_Id, ToV/ToV_Id, E_Attrs)):-
  nth0(FromV_Id, Vs, FromV),
  nth0(ToV_Id, Vs, ToV),
  ugraph_edge_arrow_head(FromV-ToV, E_ArrowHead),
  ugraph_edge_color(FromV-ToV, E_Color),
  ugraph_edge_name(FromV-ToV, E_Name),
  ugraph_edge_style(FromV-ToV, E_Style),
  E_Attrs = [
    arrow_type(E_ArrowHead),
    color(E_Color),
    label(E_Name),
    style(E_Style)
  ]

%! ugraph_edge_arrow_head(+E:edge, -ArrowType:atom) is det.
% @arg ArrowType One of the following values:
%      * `box`
%      * `crow`
%      * `diamond`
%      * `dot`
%      * `ediamond`
%      * `empty`
%      * `halfopen`
%      * `inv`
%      * `invodot`
%      * `normal`
%      * `invdot`
%      * `invempty`
%      * `none`
%      * `odiamond`
%      * `obox`
%      * `odot`
%      * `open`
%      * `tee`
%      * `vee`

ugraph_edge_arrow_head(_FromV-_ToV, normal).

ugraph_edge_color(_FromV-_ToV, black).

%! ugraph_edge_name(+Edge:edge, -EdgeName:atom) is det.
% Returns a name for the given edge.

ugraph_edge_name(FromV-ToV, EdgeName):-
  maplist(ugraph_vertex_name, [FromV, ToV], [FromV_Name, ToV_Name]),
  phrase(ugraph_edge_name(FromV_Name, ToV_Name), Codes),
  atom_codes(EdgeName, Codes).

ugraph_edge_name(FromV_Name, ToV_Name) -->
  {atom_codes(FromV_Name, FromV_NameCodes)},
  FromV_NameCodes,
  space,
  dcg_arrow([head(both)], 1),
  space,
  {atom_codes(ToV_Name, ToV_NameCodes)},
  ToV_NameCodes.

%! ugraph_edge_style(+E:edge, -Style:atom) is det.
% @arg Style One of the following values:
%      * `bold`
%      * `dashed`
%      * `dotted`
%      * `invis`
%      * `solid`
%      * `tapered`

ugraph_edge_style(_FromV-_ToV, solid).

ugraph_name(UG, Name):-
  term_to_atom(UG, Name).



% VERTEX %

%! ugraph_vertex(
%!   +Options:list(nvpair),
%!   +Vertex:vertex,
%!   +Vertices:ordset(vertex),
%!   -V_Term:compound
%! ) is det.
% @tbd Add support for the vertex/1 property on vertex terms.

ugraph_vertex(O, V, Vs, vertex(V_Id, V_Attrs)):-
  nth0(V_Id, Vs, V),
  ugraph_vertex_color(V, V_Color),
  call(CoordFunc, O, Vs, V, V_Coord),
  %ugraph_vertex_image(V, V_Image),
  ugraph_vertex_name(V, V_Name),
  setting(radius, V_R),
  ugraph_vertex_shape(V, V_Shape),
  V_Attrs = [
    color(V_Color),
    coord(V_Coord),
    label(V_Name),
    radius(V_R),
    shape(V_Shape)
  ].

ugraph_vertex_color(_V, black).

%ugraph_vertex_image(V, V_Image):-

ugraph_vertex_name(V, V_Name):-
  term_to_atom(V, V_Name).

%! ugraph_vertex_shape(+Vertex:vertex, -Shape:atom) is det.
% @arg Vertex
% @arg Shape The following values are supported:
%      `box`
%      `polygon`
%      `ellipse`
%      `oval`
%      `circle`
%      `point`
%      `egg`
%      `triangle`
%      `plaintext`
%      `diamond`
%      `trapezium`
%      `parallelogram`
%      `house`
%      `pentagon`
%      `hexagon`
%      `septagon`
%      `octagon`
%      `doublecircle`
%      `doubleoctagon`
%      `tripleoctagon`
%      `invtriangle`
%      `invtrapezium`
%      `invhouse`
%      `Mdiamond`
%      `Msquare`
%      `Mcircle`
%      `rect`
%      `rectangle`
%      `square`
%      `star`
%      `none`
%      `note`
%      `tab`
%      `folder`
%      `box3d`
%      `component`
%      `promoter`
%      `cds`
%      `terminator`
%      `utr`
%      `primersite`
%      `restrictionsite`
%      `fivepoverhang`
%      `threepoverhang`
%      `noverhang`
%      `assembly`
%      `signature`
%      `insulator`
%      `ribosite`
%      `rnastab`
%      `proteasesite`
%      `proteinstab`
%      `rpromoter`
%      `rarrow`
%      `larrow`
%      `lpromoter`

ugraph_vertex_shape(_V, ellipse).

