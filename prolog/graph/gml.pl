:- module(
  gml,
  [
    gml_edge/3,      % +Out, +FromTerm, +ToTerm
    gml_edge/4,      % +Out, +FromTerm, +ToTerm, +Options
    gml_graph/2,     % +Out, :Goal_1
    gml_graph/3,     % +Out, :Goal_1, +Options
    gml_node/2,      % +Out, +Term
    gml_node/3       % +Out, +Term, +Options
  ]
).

/* <module> GML serialization

```bnf
GML ::= List
List ::= (whitespace * Key whitespace + Value) *
Value ::= Integer | Real | String | [ List ]
Key ::= [ a-z A-Z ] [ a-z A-Z 0-9 ] *
Integer ::= sign digit +
Real ::= sign digit * . digit * mantissa
String ::= " instring "
sign ::= empty | + | -
digit ::= [0-9]
Mantissa ::= empty | E sign digit
instring ::= ASCII - {&,"} | & character + ;
whitespace ::= space | tabulator | newline
```

---

@author Wouter Beek
@version 2018
*/

:- use_module(library(apply)).
:- use_module(library(option)).

:- use_module(library(call_ext)).
:- use_module(library(file_ext)).
:- use_module(library(debug_ext)).
:- use_module(library(graph/dot), []).

:- meta_predicate
    gml_graph(+, 1),
    gml_graph(+, 1, +).





%! gml_attributes(+Options:list(compound), -String:string) is det.

gml_attributes(Options, Str) :-
  maplist(gml_attribute, Options, Strs),
  atomics_to_string(Strs, " ", Str).

gml_attribute(Option, Str) :-
  Option =.. [Key,Value],
  (   number(Value)
  ->  format(string(Str), "~a ~w", [Key,Value])
  ;   format(string(Str), "~a \"~w\"", [Key,Value])
  ).



%! gml_edge(+Out:stream, +FromTerm:term, +ToTerm:term) is det.
%! gml_edge(+Out:stream, +FromTerm:term, +ToTerm:term, +Options:list(compound)) is det.

gml_edge(Out, FromTerm, ToTerm) :-
  gml_edge(Out, FromTerm, ToTerm, []).


gml_edge(Out, FromTerm, ToTerm, Options) :-
  maplist(dot:dot_id, [FromTerm,ToTerm,FromTerm-ToTerm], [FromId,ToId,Id]),
  gml_attributes(Options, Str),
  format_debug(gml, Out, "  edge [ id \"~a\" source \"~a\" target \"~a\" ~s ]", [Id,FromId,ToId,Str]).



%! gml_graph(+Out:stream, :Goal_1) is det.
%! gml_graph(+Out:stream, :Goal_1, +Options:list(compound)) is det.
%
% The following options are supported:
%
%   * directed(+boolean)
%
%     Whether the graph is directed (`true`) or undirected (`false`,
%     default).

gml_graph(Out, Goal_1) :-
  gml_graph(Out, Goal_1, []).


gml_graph(Out, Goal_1, Options) :-
  option(directed(Directed), Options, false),
  must_be(boolean, Directed),
  boolean_value(Directed, DirectedN),
  format_debug(gml, Out, "graph [ directed ~d", [DirectedN]),
  call(Goal_1, Out),
  format_debug(gml, Out, "]").



%! gml_node(+Out:stream, +Term:term) is det.
%! gml_node(+Out:stream, +Term:term, +Options:list(compound)) is det.

gml_node(Out, Term) :-
  gml_node(Out, Term, []).


gml_node(Out, Term, Options) :-
  dot:dot_id(Term, Id),
  gml_attributes(Options, Str),
  format_debug(gml, Out, "  node [ id \"~a\" ~s ]", [Id,Str]).





% HELPERS %

%! boolean_value(+Directed:boolean, +N:between(0,1)) is semidet.
%! boolean_value(+Directed:boolean, -N:between(0,1)) is det.
%! boolean_value(-Directed:boolean, +N:between(0,1)) is det.
%! boolean_value(-Directed:boolean, -N:between(0,1)) is multi.

boolean_value(false, 0).
boolean_value(true, 1).
