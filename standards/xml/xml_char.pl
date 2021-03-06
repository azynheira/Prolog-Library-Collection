:- module(
  xml_char,
  [
    'Char'//1, % ?Code:code
    'Char11'//1, % ?Code:code
    'NameChar'//1, % ?Code:code
    'NameStartChar'//1, % ?Code:code
    'RestrictedChar'//1, % ?Code:code
    'S'//0
  ]
).

/** <module> XML character

DCGs for character definitions in XML recommendations.

@author Wouter Beek
@version 2014/05
*/

:- use_module(dcg(dcg_ascii)).
:- use_module(dcg(dcg_content)).
:- use_module(dcg(dcg_unicode)).
:- use_module(sparql(sparql_char)).



%! 'Char'(?Code:code)// .
% An **XML Character** is an atomic unit of text specified by ISO/IEC 10646.
%
% ~~~{.ebnf}
% Char ::= #x9 |              // Horizontal tab
%          #xA |              // Line feed
%          #xD |              // Carriage return
%          [#x20-#xD7FF] |    // Space, punctuation, numbers, letters
%          [#xE000-#xFFFD] |
%          [#x10000-#x10FFFF]
% ~~~
%
% Avoid comapatibility characters [Unicode, section 2.3].
% Avoid the following characters (control characters,
% permanently undefined Unicode characters):
%
% ~~~{.txt}
% [#x7F-#x84] // Delete, ...
% [#x86-#x9F]
% [#xFDD0-#xFDEF],
% [#x1FFFE-#x1FFFF]
% [#x2FFFE-#x2FFFF]
% [#x3FFFE-#x3FFFF]
% [#x4FFFE-#x4FFFF]
% [#x5FFFE-#x5FFFF]
% [#x6FFFE-#x6FFFF]
% [#x7FFFE-#x7FFFF]
% [#x8FFFE-#x8FFFF]
% [#x9FFFE-#x9FFFF]
% [#xAFFFE-#xAFFFF]
% [#xBFFFE-#xBFFFF]
% [#xCFFFE-#xCFFFF]
% [#xDFFFE-#xDFFFF]
% [#xEFFFE-#xEFFFF]
% [#xFFFFE-#xFFFFF]
% [#x10FFFE-#x10FFFF]
% ~~~
%
% @compat XML 1.0.5 [2].

% Horizontal tab =|#x9|=
'Char'(C) --> horizontal_tab(C).
% Line feed =|#xA|=
'Char'(C) --> line_feed(C).
% Carriage return =|#xD|=
'Char'(C) --> carriage_return(C).
% Space, punctuation, numbers, letters
% =|#x20-#xD7FF|=
'Char'(C) --> between_hex('20', 'D7FF', C).
% =|#xE000-#xFFFD|=
'Char'(C) --> between_hex('E000', 'FFFD', C).
% =|#x10000-#x10FFFF|=
'Char'(C) --> between_hex('10000', '10FFFF', C).


%! 'Char11'(?Code:code)// .
% ~~~{.ebnf}
% Char ::= [#x1-#xD7FF] |
%          [#xE000-#xFFFD] |
%          [#x10000-#x10FFFF]
%          /* any Unicode character, excluding the surrogate blocks,
%             FFFE, and FFFF. */
% ~~~
%
% @compat XML 1.1.2 [2].

% #x1-#xD7FF
'Char11'(C) --> between_hex('1', 'D7FF', C).
% #xE000-#xFFFD
'Char11'(C) --> between_hex('E000', 'FFFD', C).
% #x10000-#x10FFFF
'Char11'(C) --> between_hex('10000', '10FFFF', C).


%! 'NameChar'(?Code:code)//
% ~~~{.ebnf}
% NameChar ::= NameStartChar |
%              "-" |
%              "." |
%              [0-9] |
%              #xB7 |
%              [#x0300-#x036F] |
%              [#x203F-#x2040]
% ~~~
%
% @compat XML 1.0.5 [4a].
% @compat XML 1.1.2 [4a].

'NameChar'(C) --> 'NameStartChar'(C).
'NameChar'(C) --> hyphen_minus(C).
'NameChar'(C) --> dot(C).
'NameChar'(C) --> decimal_digit(C).
% #x00B7
'NameChar'(C) --> middle_dot(C).
% #x0300-#x036F
'NameChar'(C) --> between_hex('0300', '036F', C).
% #x203F
'NameChar'(C) --> undertie(C).
% #x2040
'NameChar'(C) --> character_tie(C).


%! 'NameStartChar'(?Code:code)//
% ~~~{.ebnf}
% NameStartChar ::= ":" |
%                   [A-Z] |
%                   "_" |
%                   [a-z] |
%                   [#xC0-#xD6] |
%                   [#xD8-#xF6] |
%                   [#xF8-#x2FF] |
%                   [#x370-#x37D] |
%                   [#x37F-#x1FFF] |
%                   [#x200C-#x200D] |
%                   [#x2070-#x218F] |
%                   [#x2C00-#x2FEF] |
%                   [#x3001-#xD7FF] |
%                   [#xF900-#xFDCF] |
%                   [#xFDF0-#xFFFD] |
%                   [#x10000-#xEFFFF]
% ~~~
%
% @compat XML 1.0.5 [4].
% @compat XML 1.1.2 [4].
% @compat Reuses SPARQL 1.1 Query [164].

'NameStartChar'(C) --> colon(C).
'NameStartChar'(C) --> underscore(C).
'NameStartChar'(C) --> 'PN_CHARS_BASE'(C).


%! 'RestrictedChar'(?Code:code)//
% ~~~{.ebnf}
% RestrictedChar ::=
%     \\ Start of heading, start of text, end of text, end of transmission,
%     \\ enquiry, positive acknowledgement, bell, backspace.
%     [#x1-#x8] |
%
%     \\ Vertical tab, form feed.
%     [#xB-#xC] |
%
%     \\ Shift out, shift in, data link escape, device control (1, 2, 3, 4),
%     \\ negative acknowledgement, synchronous idle,
%     \\ end of transmission block, cancel, end of medium, substitute,
%     \\ escape, file separator, group separator, record separator,
%     \\ unit separator.
%     [#xE-#x1F] |
%
%     [#x7F-#x84] |
%     [#x86-#x9F]
% ~~~
%
% @compat XML 1.1.2 [2a].

'RestrictedChar'(C) --> between_hex('1', '8', C).
'RestrictedChar'(C) --> between_hex('B', 'C', C).
'RestrictedChar'(C) --> between_hex('E', '1F', C).
'RestrictedChar'(C) --> between_hex('7F', '84', C).
'RestrictedChar'(C) --> between_hex('86', '9F', C).


%! 'S'// .
% White space.
%
% ~~~{.ebnf}
% S ::= ( #x20 | #x9 | #xD | #xA )+   // Any consecutive number of spaces,
%                                     // carriage returns, line feeds, and
%                                     // horizontal tabs.
% ~~~
%
% The presence of carriage_return// in the above production is maintained
% purely for backward compatibility with the First Edition.
% All `#xD` characters literally present in an XML document are either removed
% or replaced by line_feed// (i.e., `#xA`) characters before any other
% processing is done.
%
% @compat XML 1.0.5 [3].
% @compat XML 1.1.2 [3].

'S' --> 'S_char', 'S*'.

'S*' --> [].
'S*' --> 'S_char', 'S*'.

'S_char' --> carriage_return.
'S_char' --> horizontal_tab.
'S_char' --> line_feed.
'S_char' --> space.

