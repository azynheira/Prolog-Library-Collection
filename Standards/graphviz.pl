:- module(
  graphviz,
  [
% FILE CONVERSION
    convert_graphviz/4, % +FromFile:atom
                        % +Method:onef([dot,sfdp])
                        % +ToFileType:oneof([jpeg,pdf,svg,xdot])
                        % ?ToFile:atom
    graphviz_to_svg/3, % +GraphViz_File:atom
                       % +Method:onef([dot,sfdp])
                       % -SVG:dom

% PARSING
    parse_attributes_graphviz/2, % +Context:oneof([edge,graph,node])
                                 % +Attributes:list(nvpair)

% WRITING
    write_graphviz_to_stream/2 % +Stream:stream
                               % +Graph:element
  ]
).

/** <module> GraphViz

Methods for writing to GraphViz.

In GraphViz vertices are called 'nodes'.

---+ Datatypes

This module uses the following non-standard datatypes.

---++ edge

A compound term of the form

==
edge(FromVertexID, ToVertexID, EdgeAttributes)
==

representing a GraphViz edge.

---+ graph

A compound term of the form

==
graph(Vertices, Edges, GraphAttributes)
==

representing a GraphViz graph.

---++ vertex

A compound term of the form

==
vertex(VertexID, VerticeAttributes)
==

representing a GraphViz vertex.

---+ nvpair

A compound term of the form

==
Name(Value)
==

representing a name-value pair.

@author Wouter Beek
@version 2011-2013/03
*/

:- use_module(generics(exception_handling)).
:- use_module(generics(file_ext)).
:- use_module(generics(os_ext)).
:- use_module(generics(print_ext)).
:- use_module(generics(type_checking), [type_check/2 as type_check_generic]).
:- use_module(library(process)).
:- use_module(standards(brewer)).
:- use_module(standards(c)).
:- use_module(svg(svg)).
:- use_module(standards(x11)).

user:file_search_path(www, project(www)).
user:file_search_path(www_img, www(img)).



% ATTRIBUTES %

arrow_type(box).
arrow_type(crow).
arrow_type(diamond).
arrow_type(dot).
arrow_type(ediamond).
arrow_type(empty).
arrow_type(halfopen).
arrow_type(inv).
arrow_type(invdot).
arrow_type(invempty).
arrow_type(invodot).
arrow_type(none).
arrow_type(normal).
arrow_type(obox).
arrow_type(odiamond).
arrow_type(odot).
arrow_type(open).
arrow_type(tee).
arrow_type(vee).

%% attribute(
%%   ?Name:atom,
%%   ?Type:term,
%%   ?Contexts:list(oneof([edge,graph,node])),
%%   ?Default:term
%% ) is nondet.
% Registered GraphViz attributes.
%
% @param Name The atomic name of a GraphViz attribute.
% @param Type The type of the values for this attribute.
% @param Contexts A list representing the elements for which the attribute can
%        be specified. Any non-empty combination of the following values:
%        1. =edge=, the attribute applies to edges.
%        2. =graph=, the attribute applies to graphs.
%        2. =node=, the attribute applies to vertices.
% @param Default The default value for the attribute.

attribute(arrowhead, oneof(ArrowTypes), [edge], normal):-
  findall(ArrowType, arrow_type(ArrowType), ArrowTypes).

% The character encoding used to interpret text label input.
% Note that iso-8859-1 and Latin1 denote the same character encoding.
attribute(
  charset,
  oneof(['iso-8859-1','Latin1','UTF-8']),
  [graph],
  'UTF-8'
).

% Color schemes from which values of the =color= attribute have to be drawn.
attribute(colorscheme, oneof([svg,x11]), [edge,graph,node], svg).

attribute(dir, oneof([back,both,forward,none]), [edge], forward).

attribute(image, atom, [node], '').

% The font size that is used for text.
attribute(fontsize, double, [graph], 1.0).

attribute(label, lblString, [edge,graph,node], '').

% Whether and how vertices are allowed to overlap.
% Boolean =false= is the same as =voronoi=.
% =scalexy= means that x and y are scaled separately.
attribute(
  overlap,
  or([boolean, oneof([compress,orthoxy,orthoyx,scalexy,voronoi,vpsc])]),
  [graph],
  true
).

attribute(peripheries, integer, [node], 1).

% Polygon-based shapes for GraphViz vertices.
attribute(
  shape,
  or([polygon_based_shape, record_based_shape, user_defined_shape]),
  [node],
  ellipse
).

% Styles for Graphviz edges.
attribute(style, oneof(Styles), [edge], ''):-
  findall(Style, style(edge, Style), Styles).

% Styles for Graphviz vertices.
attribute(style, oneof(Styles), [node], ''):-
  findall(Style, style(node, Style), Styles).

%% attribute(
%%   ?Name:atom,
%%   ?Type:term,
%%   ?Context:list(oneof([edge,graph,node])),
%%   +Attributess:list,
%%   ?Default:term
%% ) is nondet.
% Registered GraphViz attributes.
%
% @param Name The atomic name of a GraphViz attribute.
% @param Type The type of the values for this attribute.
% @param Context A list representing the elements for which the attribute can
%        be specified. Any non-empty combination of the following values:
%        1. =edge=, the attribute applies to edges.
%        2. =graph=, the attribute applies to graphs.
%        2. =node=, the attribute applies to nodes.
% @param Attributess A list of attribute-value pairs. Used for looking up the
%        interactions between multiple attributes.
% @param Default The default value for the attribute.

attribute(color, oneof(Colors), [edge,graph,node], Attributes, black):-
  % The default =colorscheme= is either set by its own argument assertion,
  % or is assumed to be =x11=. We check whether the =colorscheme=
  % setting applies to the current context.
  (
    attribute(colorscheme, _Type, _Context, DefaultColorscheme),
    option(colorscheme(Colorscheme), Attributes, DefaultColorscheme)
  ->
    color_scheme_default_color(Colorscheme, DefaultColor)
  ;
    DefaultColor = black
  ),
  colorscheme_colors(Colorscheme, Colors).

attribute(Name, Type, Context, _Attrs, Default):-
  attribute(Name, Type, Context, Default).

color_scheme_default_color(_, black).



% FILE CONVERSION %

:- assert(user:prolog_file_type(dot,  dot     )).
:- assert(user:prolog_file_type(gv,   graphviz)).
:- assert(user:prolog_file_type(jpeg, jpeg    )).
:- assert(user:prolog_file_type(jpg,  jpeg    )).
:- assert(user:prolog_file_type(pdf,  pdf     )).
:- assert(user:prolog_file_type(svg,  svg     )).
:- assert(user:prolog_file_type(xdot, xdot    )).

%% convert_graphviz(
%%   +FromFile:atom,
%%   +Method:oneof([dot,sfdp]),
%%   +ToFileType:oneof([jpeg,pdf,svg,xdot]),
%%   ?ToFile:atom
%% ) is det.
% Converts a GraphViz DOT file to an image file, using a specific
% visualization method.
%
% @param FromFile
% @param Method
% @param ToFileType
% @param ToFile This is either instantiated to the file location where the
%        output is to be sotre, or this is uninstantiated and then the
%        default location and file naming procedures are used.

convert_graphviz(FromFile, Method, ToFileType, ToFile):-
  type_check(oneof([dot,sfdp]), Method),
  type_check(oneof([jpeg,pdf,svg,xdot]), ToFileType),
  prolog_file_type(ToExtension, ToFileType),

  % The file where the output is put.
  (
    var(ToFile)
  ->
    % No output file location is given, so create one.
    file_name_type(Base0, _FromFileType, FromFile),
    % Add the conversion method to the output file name.
    format(atom(Base), '~w_~w', [Base0, Method]),
    file_name_type(Base, ToFileType, ToFile),
    % We only need one extension name.
    !
  ;
    % An output file location is given, so use it.
    true
  ),
  
  format(atom(OutputType), '-T~w', [ToExtension]),
  process_create(
    path(Method),
    [OutputType, FromFile, '-o', ToFile],
    [process(PID)]
  ),
  process_wait(PID, ShellStatus),
  rethrow(
    shell_status(ShellStatus),
    error(shell_error(FormalMessage), context(_Predicate, ContextMessage)),
    error(
      shell_error(FormalMessage),
      context(graphviz:dot/3, ContextMessage)
    )
  ).

graphviz_to_svg(GraphViz_File, Method, SVG):-
  absolute_file_name(www_img(tmp), SVG_File, [access(write), file_type(svg)]),
  convert_graphviz(GraphViz_File, Method, svg, SVG_File),
  file_to_svg(SVG_File, SVG).



% PARSING %

%% parse_attribute(
%%   +Context:oneof([edge,graph,node]),
%%   +Attributes:list,
%%   +Attribute:nvpair
%% ) is semidet.
% Succeeds if the given attribute term is a valid GraphViz name-value pair.
%
% @param Context The atomic name of the element for which the attribute is
%        set. The same attribute may work differently for different elements.
%        1. =edge=
%        2. =graph=
%        3. =node=
% @param Attributes A list of attribute-value pairs, used for resolving
%        interactions between the given =Attribute= and some other
%        attributes that were specified.
% @param Attribute A name-value pair.

parse_attribute(Context, Attributes, Attribute):-
  Attribute =.. [Name, Value],
  attribute(Name, Type, Contexts, Attributes, _Default),
  % The same attribute may be defined for multiple elements. The meaning of
  % the attribute may be different for different elements.
  memberchk(Context, Contexts),
  !,
  type_check(Type, Value).

%% parse_attributes_graphviz(
%%   +Context:oneof([edge,graph,node]),
%%   +Attributes:list(nvpair)
%% ) is det.
% Parses a list of attributes.
%
% @param Context The atomic name of the element to which the attributes apply.
% @param Attributes A list of name-value pairs.

parse_attributes_graphviz(Context, Attributes):-
  maplist(parse_attribute(Context, Attributes), Attributes).



% TYPE CHECKING %

/* TODO
% html_label//0
% DCG for GraphViz HTML labels.

cell --> ['<td>'], label, ['</td>'].
cell --> ['<td>', '<img/>', '</td>'].

cells --> cell.
cells --> cells, cell.
cells --> cells, ['<vr/>'], cell.

html_label --> table.
html_label --> text.

label --> [Label], {atomic(Label)}.

row --> ['<tr>'], cells, ['</tr>'].

rows --> row.
rows --> rows, row.
rows --> rows, ['<hr/>'], row.

string --> [String], {atomic(String)}.

table --> table0.
table --> ['<font>'], table0, ['</font>'].

table0 --> ['<table>'], rows, ['</table>'].

text --> text_item.
text --> text, text_item.

text_item --> string.
text_item --> ['<br/>'].
text_item --> ['<font>'], text, ['</font>'].
text_item --> ['<i>'], text, ['</i>'].
text_item --> ['<b>'], text, ['</b>'].
text_item --> ['<u>'], text, ['</u>'].
text_item --> ['<sub>'], text, ['</sub>'].
text_item --> ['<sup>'], text, ['</sup>'].
*/

%% colorscheme_colors(?ColorScheme:atom, ?Colors:list(atom)) is det.
% The color names for each of the supported color schemes.
%
% @param ColorScheme The atomic name of a GraphViz supported color scheme.
% @param Colors A list of atomic names of colors in a specific color scheme.

colorscheme_colors(svg, Colors):-
  svg_colors(Colors),
  !.
colorscheme_colors(x11, Colors):-
  x11_colors(Colors),
  !.
colorscheme_colors(ColorScheme, Colors):-
  brewer_colors(ColorScheme, Colors).

%% shape(?Category:oneof([polygon]), ?Name:atom) is nondet.

shape(polygon, assembly).
shape(polygon, box).
shape(polygon, box3d).
shape(polygon, cds).
shape(polygon, circle).
shape(polygon, component).
shape(polygon, diamond).
shape(polygon, doublecircle).
shape(polygon, doubleoctagon).
shape(polygon, egg).
shape(polygon, ellipse).
shape(polygon, fivepoverhang).
shape(polygon, folder).
shape(polygon, hexagon).
shape(polygon, house).
shape(polygon, insulator).
shape(polygon, invhouse).
shape(polygon, invtrapezium).
shape(polygon, invtriangle).
shape(polygon, larrow).
shape(polygon, lpromoter).
shape(polygon, 'Mcircle').
shape(polygon, 'Mdiamond').
shape(polygon, 'Msquare').
shape(polygon, none).
shape(polygon, note).
shape(polygon, noverhang).
shape(polygon, octagon).
shape(polygon, oval).
shape(polygon, parallelogram).
shape(polygon, pentagon).
shape(polygon, plaintext).
shape(polygon, point).
shape(polygon, polygon).
shape(polygon, primersite).
shape(polygon, promoter).
shape(polygon, proteasesite).
shape(polygon, proteinstab).
shape(polygon, rarrow).
shape(polygon, rect).
shape(polygon, rectangle).
shape(polygon, restrictionsite).
shape(polygon, ribosite).
shape(polygon, rnastab).
shape(polygon, rpromoter).
shape(polygon, septagon).
shape(polygon, signature).
shape(polygon, square).
shape(polygon, tab).
shape(polygon, terminator).
shape(polygon, threepoverhang).
shape(polygon, trapezium).
shape(polygon, triangle).
shape(polygon, tripleoctagon).
shape(polygon, utr).

%% style(?Class:oneof([edge,node]), ?Name:atom) is nondet.

style(edge, bold).
style(edge, dashed).
style(edge, dotted).
style(edge, solid).

style(node, bold).
style(node, dashed).
style(node, diagonals).
style(node, dotted).
style(node, filled).
style(node, rounded).
style(node, solid).
style(node, striped).
style(node, wedged).

%% type_check(+Type:compound, +Value:term) is semidet.
% Succeeds of the given value is of the given GraphViz type.
%
% @param Type A compound term representing a GraphViz type.
% @param Value The atomic name of a value.
%
% @tbd Test the DCG for HTML labels.
% @tbd Add the escape sequences for the =escString= datatype.

type_check(or(AlternativeTypes), Value):-
  member(Type, AlternativeTypes),
  type_check(Type, Value),
  !.
type_check(escString, Value):-
  type_check_generic(atom, Value),
  !.
type_check(lblString, Value):-
  type_check(escString, Value),
  !.
type_check(lblString, Value):-
  type_check(htmlLabel, Value),
  !.
type_check(polygon_based_shape, Value):-
  findall(
    Shape,
    shape(polygon, Shape),
    Shapes
  ),
  type_check_generic(oneof(Shapes), Value).
type_check(Type, Value):-
  type_check_generic(Type, Value).



% WRITING %

%% write_attribute(+Stream:stream, +Attribute:nvpair, +Separator:atom) is det.
% Writes an attribute, together with a separator.
%
% @param Stream An output stream.
% @param Attribute A name-value pair.
% @param Separator An atomic separator.

write_attribute(Stream, Separator, Attribute):-
  Attribute =.. [Name, Value],
  (
    attribute(Name, _Type, _Context, _Attributes, _Default)
  ->
    c_convert(Value, C_Value),
    format(Stream, '~w="~w"~w', [Name, C_Value, Separator])
  ;
    true
  ).

%% write_attributes(
%%   +Stream:stream,
%%   +Attributes:list(nvpair),
%%   +Separator:atom
%% ) is det.
% Writes the given list of attributes to an atom.
%
% @param Stream An output stream.
% @param Attributes A list of name-value pairs.
% @param Separator An atomic separator that is written between the attributes.

% Empty attribute list.
write_attributes(_Stream, [], _Separator):-
  !.
% Non-empty attribute list.
% Write the open and colsing signs of the attribute list.
write_attributes(Stream, Attributes, Separator):-
  format(Stream, '[', []),
  write_attributes0(Stream, Attributes, Separator),
  format(Stream, ']', []).

% We know that the list in not empty.
% For the last attribute in the list we use the empty separator.
write_attributes0(Stream, [Attribute], _Separator):-
  !,
  write_attribute(Stream, '', Attribute).
write_attributes0(Stream, [Attribute | Attributes], Separator):-
  write_attribute(Stream, Separator, Attribute),
  write_attributes0(Stream, Attributes, Separator).

%% write_edge(+Stream:stream, +Edge:edge) is det.
% Writes an edge term.
%
% @param Stream An output stream.
% @param Edge A GraphViz edge compound term.

write_edge(Stream, edge(FromVertexID, ToVertexID, EdgeAttributes)):-
  print_indent(Stream, 1),
  format(Stream, 'node_~w -> node_~w ', [FromVertexID, ToVertexID]),
  write_attributes(Stream, EdgeAttributes, ', '),
  format(Stream, ';', []),
  nl(Stream).

%% write_graphviz_to_stream(+Stream:stream, +Graph:graph) is det.
% Writes a GraphViz structure to an output stream.
%
% @param Stream An output stream.
% @param Graph A GraphViz graph compound term.

write_graphviz_to_stream(Stream, graph(Vertices, Edges, GraphAttributes)):-
  option(label(GraphName), GraphAttributes, noname),
  format(Stream, 'digraph ~w {', [GraphName]),
  nl(Stream),
  maplist(write_vertex(Stream), Vertices),
  nl(Stream),
  maplist(write_edge(Stream), Edges),
  nl(Stream),
  write_graph_attributes(Stream, GraphAttributes),
  format(Stream, '}', []),
  nl(Stream).

%% write_graph_attributes(
%%   +Stream:stream,
%%   +GraphAttributes:list(nvpair)
%% ) is det.
% Writes the given GraphViz graph attributes.
%
% The writing of graph attributes deviates a little bit from the writing of
% edge and node attributes, because the written attributes are not enclosed in
% square brackets and they are written on separate lines (and not as
% comma-separated lists).
%
% @param Stream An output stream.
% @param GraphAttributes A list of name-value pairs.

write_graph_attributes(Stream, GraphAttributes):-
  print_indent(Stream, 1),
  write_attributes0(Stream, GraphAttributes, '\n  '),
  nl(Stream).

%% write_vertex(+Stream:stream, +Vertex:vertex) is det.
% Writes a vertex term.
%
% @param Stream An output stream.
% @param Vertex A GraphViz vertex compound term.

write_vertex(Stream, node(VertexID, VerticeAttributes)):-
  print_indent(Stream, 1),
  format(Stream, 'node_~w ', [VertexID]),
  write_attributes(Stream, VerticeAttributes, ', '),
  format(Stream, ';', []),
  nl(Stream).

