:- module(
  ap_rdf_serial,
  [
    ap_rdf_convert_directory/4, % +FromDirectory:atom
                                % +ToDirectory:atom
                                % -AP_Status:compound
                                % ?MIME:atom
    ap_rdf_merge_directory/4 % +FromDirectory:atom
                             % +ToFile:atom
                             % -AP_Status:compound
                             % ?MIME:atom
  ]
).

/** <module> AP RDF serial

@author Wouter Beek
@version 2014/02-2014/03, 2014/05
*/

:- use_module(library(apply)).
:- use_module(library(error)).

:- use_module(ap(ap_db)).
:- use_module(generics(error_ext)).
:- use_module(generics(meta_ext)).
:- use_module(generics(uri_ext)).

:- use_module(plRdf_ser(rdf_convert)).
:- use_module(plRdf_ser(rdf_file)).
:- use_module(plRdf_ser(rdf_file_db)).
:- use_module(plRdf_ser(rdf_serial)).
:- use_module(plRdf_term(rdf_datatype)).



ap_rdf_convert_directory(FromDir, ToDir, ApStage, Mime):-
  default('application/x-turtle', Mime),
  rdf_convert_directory(FromDir, ToDir, Mime, ToFiles),
  (
    ToFiles == []
  ->
    existence_error('RDF file', 'No RDF files')
  ;
    maplist(ap_rdf_directory_assertion(ApStage), ToFiles)
  ).


ap_rdf_merge_directory(FromDir, ToDir, ApStage, Mime):-
  default('application/x-turtle', Mime),
  rdf_mime_format(Mime, Format),
  absolute_file_name(
    input,
    ToFile,
    [access(write),file_type(Format),relative_to(ToDir)]
  ),
  (
    rdf_merge_directory(FromDir, ToFile, [void(true)], [mime(Mime)])
  ->
    rdf_directory_files(FromDir, ToFiles),
    maplist(ap_rdf_directory_assertion(ApStage), ToFiles)
  ;
    existence_error('RDF file', 'No RDF files')
  ).


ap_rdf_directory_assertion(ApStage, File):-
  add_operation_on_file(ApStage, File, 'RDF conversion', []).

