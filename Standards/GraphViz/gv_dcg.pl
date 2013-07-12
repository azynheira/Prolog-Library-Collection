:- module(
  gv_dcg,
  [
    gv_graph//1 % +GraphTerm:compound
  ]
).

/** <module> GV_DCG

DCG rules for GraphViz DOT file generation.

Methods for writing to the GraphViz DOT format.

In GraphViz vertices are called 'nodes'.

@author Wouter Beek
@see http://www.graphviz.org/content/dot-language
@version 2013/07
*/

:- use_module(dcg(dcg_ascii)).
:- use_module(dcg(dcg_cardinal)).
:- use_module(dcg(dcg_content)).
:- use_module(graph_theory(graph_export)).
:- use_module(gv(gv_attrs)).
:- use_module(library(apply)).
:- use_module(library(option)).



%! gv_attribute(+Attribute:nvpair)// is det.
% A single GraphViz attribute.
% We assume that the attribute has already been validated.

gv_attribute(Name=Value) --> !,
  gv_id(Name),
  "=",
  gv_id(Value).
% Support for the non-deprecated representation for name-value pairs.
gv_attribute(Attr) -->
  {Attr =.. [Name,Value]},
  gv_attribute(Name=Value).

% Attributes occur between square brackets.
gv_attribute_list(G_Attrs, Attrs1) -->
  opening_square_bracket,
  {
    % The graph attributes have outer scope.
    merge_options(Attrs1, G_Attrs, AllAttrs),
    include(gv_attribute_value(AllAttrs), Attrs1, Attrs2)
  },
  dcg_multi_list(gv_attribute, comma, Attrs2),
  closing_square_bracket.

gv_compass_pt --> "_".
gv_compass_pt --> "c".
gv_compass_pt --> "e".
gv_compass_pt --> "n".
gv_compass_pt --> "ne".
gv_compass_pt --> "nw".
gv_compass_pt --> "s".
gv_compass_pt --> "se".
gv_compass_pt --> "sw".
gv_compass_pt --> "w".

%! gv_edge_operator(+Directionality:oneof([directed,undirected]))// is det.
% The binary edge operator between two vertices.
% The operator that is used depends on whether the graph is directed or
% undirected.
%
% @arg Directionality Either `directed` (operator `->`) or
%      `undirected` (operator `--`).

gv_edge_operator(directed) --> arrow(2).
gv_edge_operator(undirected) --> "--".

%! gv_edge_rhs(+GraphAttributes:list(nvpair), +ToId:gv_node_id)//
% The right-hand-side of a GraphViz edge representation.
% @tbd Instead of gv_node_id//1 we could have a gv_subgraph//1 here.
% @tbd Add support for multiple, consecutive occurrences of gv_edge_rhs//2.

gv_edge_rhs(G_Attrs, To_Id) -->
  {option(directedness(Dir), G_Attrs, undirected)},
  gv_edge_operator(Dir), space,
  gv_node_id(To_Id).

%! gv_edge_statement(
%!   +Indent:integer,
%!   +GraphAttributes:list(nvpair),
%!   +EdgeTerm:compound
%! )// is det.
% A GraphViz statement describing an edge.
%
% @arg Indent The indentation level at which the edge statement is written.
% @arg GraphAttributes The attributes of the graph. Some of these attributes
%      may be used in the edge statement (e.g., the colorscheme).
% @arg EdgeTerm A compound term in the GIFormat, representing an edge.
%
% @see Module [graph_export.pl] for the GIFormat.
% @tbd Instead of gv_node_id//1 we could have a gv_subgraph//1 here.

gv_edge_statement(I, G_Attrs, edge(From_Id, To_Id, E_Attrs)) -->
  indent(I), gv_node_id(From_Id), space,
  gv_edge_rhs(G_Attrs, To_Id), space,
  % We want `colorscheme/1` from the edges and
  % `directionality/1` from the graph.
  gv_attribute_list(G_Attrs, E_Attrs), newline.

%! gv_generic_attributes_statement(
%!   +Category:oneof([edge,graph,node]),
%!   +Indent:integer,
%!   +GraphAttributes:list(nvpair),
%!   +CategoryAttributes:list(nvpair)
%! )//
% A GraphViz statement describing generic attributes for a category of items.
%
% @arg Category The category of items for to the attributes apply.
%      Possible values: * `edge`, `graph`, `node`.
% @arg Indent An integer.
% @arg GraphAttributes A list of name-value pairs.
% @arg CategoryAttributes A list of name-value pairs.

gv_generic_attributes_statement(_Cat, _I, _G_Attrs, []) --> [], !.
gv_generic_attributes_statement(Cat, I, G_Attrs, CatAttrs) -->
  indent(I), gv_category(Cat), space,
  gv_attribute_list(G_Attrs, CatAttrs), newline.

gv_category(edge) --> e,d,g,e.
gv_category(graph) --> g,r,a,p,h.
gv_category(node) --> n,o,d,e.

%! gv_graph(+GraphTerm:compound)//
% The follow graph attributes are supported:
%   1. `directonality(+Directionality:oneof([directed,undirected]))`
%      A directed graph uses the keyword `digraph`.
%      An undirected graph uses the keyword `graph`.
%   2. `name(+GraphName:atom)`
%   3. `strict(+StrictGraph:boolean)`
%      This forbids the creation of self-arcs and multi-edges;
%      they are ignored in the input file.
%      Only in combinattion with directionality `directed`.
%
% @tbd Add support for subgraphs in edge statements.
% @tbd Add support for escape strings:
%      http://www.graphviz.org/doc/info/attrs.html#k:escString

gv_graph(graph(V_Terms, E_Terms, G_Attrs1)) -->
  {
    shared_attributes(V_Terms, V_Attrs, NewV_Terms),
    shared_attributes(E_Terms, E_Attrs, NewE_Terms),
    option(strict(Strict), G_Attrs1, false),
    option(directedness(Dir), G_Attrs1, undirected),
    option(name(G_Name), G_Attrs1, noname),
    % Make sure that the default values are part of the graph
    % attributes if they were not originally present.
    merge_options(
      G_Attrs1,
      [directedness(Dir),name(G_Name),strict(Strict)],
      G_Attrs2
    ),
    I = 0
  },

  % The first statement in the GraphViz output.
  % States that this file represents a graph according to the GraphViz format.
  indent(I), gv_strict(Strict),
  gv_graph_type(Dir), space,
  gv_id(G_Name), space,
  opening_curly_bracket, newline,

  % The following lines are indented.
  {NewI is I + 1},
  % Attributes that apply to the graph as a whole.
  gv_generic_attributes_statement(graph, NewI, G_Attrs2, G_Attrs2),
  % Attributes that are the same for all nodes.
  gv_generic_attributes_statement(node, NewI, G_Attrs2, V_Attrs),
  % Attributes that are the same for all edges.
  gv_generic_attributes_statement(edge, NewI, G_Attrs2, E_Attrs),
  % Only add a newline if some content was written in the previous three
  % lines.
  ({(G_Attrs2 == [], V_Attrs == [], E_Attrs == [])} -> "" ; newline),

  % The list of GraphViz nodes.
  dcg_multi_list(gv_node_statement(NewI, G_Attrs2), NewV_Terms),
  newline,

  % The list of GraphViz edges.
  dcg_multi_list(gv_edge_statement(NewI, G_Attrs2), NewE_Terms),
  % Note that we do not include a newline here.

  % The description of the grpah is closed (using the old indent level).
  indent(I), closing_curly_bracket.

%! gv_graph_type(+Directionality:oneof([directed,undirected]))// is det.
% The type of graph that is represented.
%
% @arg Directionality Either `directed` or `undirected`.

gv_graph_type(directed) --> d,i,g,r,a,p,h.
gv_graph_type(undirected) --> g,r,a,p,h.

%! gv_id(-Codes:list(code))// is det.
% Parse a GraphViz identifier.
% There are 4 variants:
%   1. Any string of alphabetic (`[a-zA-Z'200-'377]`) characters,
%      underscores (`_`) or digits (`[0-9]`), not beginning with a digit.
%   2. A numeral `[-]?(.[0-9]+ | [0-9]+(.[0-9]*)? )`.
%   3. Any double-quoted string (`"..."`) possibly containing
%      escaped quotes (`\"`).
%      In quoted strings in DOT, the only escaped character is
%      double-quote (`"`). That is, in quoted strings, the dyad `\"`
%      is converted to `"`. All other characters are left unchanged.
%      In particular, `\\` remains `\\`.
%      Layout engines may apply additional escape sequences.
%   4. An HTML string (`<...>`).
%
% @tbd Add support for HTML-like labels:
%      http://www.graphviz.org/doc/info/shapes.html#html
%      This requires an XML grammar!

% Alpha-numeric strings (variant 1) and numerals (variant 2).
gv_id(Atom) -->
  {atom_codes(Atom, Codes)},
  gv_id_(Codes),
  % Variant 1 identifiers should not be (case-variants of) a
  % GraphViz keyword.
  {\+ gv_keyword(Codes)}.
% Double-quoted strings (variant 3).
% The quotes are already part of the given atom.
gv_id(Atom) -->
  {
    atom_codes(Atom, [H|T]),
    append(S, [H], T)
  },
  double_quote(H),
  gv_quoted_string(S),
  double_quote(H).
% Double-quoted strings (variant 3).
% The quotes are not in the given atom. They are written anyway.
gv_id(Atom) -->
  {atom_codes(Atom, S)},
  double_quote,
  gv_quoted_string(S),
  double_quote.

gv_id_([H|T]) -->
  gv_id_first(H),
  gv_id_rest(T).
gv_id_(Cs) -->
  signed_number(_N, Cs).
% HTML strings (variant 4).
%gv_id_ -->
%  "<",
%  gv_html_string,
%  ">".

gv_id_first(X) --> letter(X).
gv_id_first(X) --> underscore(X).

gv_id_rest([]) --> [].
gv_id_rest([H|T]) -->
  (alpha_numeric(H) ; underscore(H)),
  gv_id_rest(T).

gv_keyword(Codes):-
  % Obviously, the keywords do not occur on the difference list input.
  % So we must use phrase/[2,3].
  phrase(gv_keyword, Codes).

%! gv_keyword//
% GraphViz has reserved keywords that cannot be used as identifiers.
% GraphViz keywords are case-insensitive.

gv_keyword --> d,i,g,r,a,p,h.
gv_keyword --> e,d,g,e.
gv_keyword --> g,r,a,p,h.
gv_keyword --> n,o,d,e.
gv_keyword --> s,t,r,i,c,t.
gv_keyword --> s,u,b,g,r,a,p,h.

%! gv_node_id(+NodeId:atom)//
% GraphViz node identifiers can be of the following two types:
%   1. A GraphViz identifier, see gv_id//1.
%   2. A GraphViz identifier plus a GraphViz port indicator, see gv_port//0.
%
% @tbd Add support for GraphViz port indicators
%      inside GraphViz node identifiers.

gv_node_id(V_Id) -->
  gv_id(V_Id).
%gv_node_id(_) -->
%  gv_id(_),
%  gv_port.

%! gv_node_statement(
%!   +Indent:integer,
%!   +GraphAttributes,
%!   +VertexTerm:compound
%! )// is det.
% A GraphViz statement describing a vertex (GraphViz calls vertices 'nodes').

gv_node_statement(I, G_Attrs, vertex(V_Id, _V, V_Attrs)) -->
  indent(I), gv_node_id(V_Id), space,
  gv_attribute_list(G_Attrs, V_Attrs), newline.

gv_port -->
  gv_port_location,
  (gv_port_angle ; "").
gv_port -->
  gv_port_angle,
  (gv_port_location ; "").
gv_port -->
  ":",
  gv_compass_pt.

gv_port_angle -->
  "@",
  gv_id(_).

gv_port_location -->
  ":",
  gv_id(_).
gv_port_location -->
  ":(",
  gv_id(_),
  ",",
  gv_id(_),
  ")".

gv_quoted_string([]) --> [].
% Just to be sure, we do not allow the double quote
% that closes the string to be escaped.
gv_quoted_string([X]) -->
  {X \== 92}, !,
  [X].
% A double quote is only allowed if it is escaped by a backslash.
gv_quoted_string([92,34|T]) --> !,
  gv_quoted_string(T).
% Add the backslash escape character.
gv_quoted_string([34|T]) --> !,
  backslash,
  double_quote,
  gv_quoted_string(T).
% All other characters are allowed without escaping.
gv_quoted_string([H|T]) -->
  [H],
  gv_quoted_string(T).

%! gv_strict(+Strict:boolean)// is det.
% The keyword denoting that the graph is strict, i.e., has no self-arcs and
% no multi-edges.
% This only applies to directed graphs.

gv_strict(false) --> [].
gv_strict(true) -->
  s,t,r,i,c,t, space.