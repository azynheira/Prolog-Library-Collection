:- module(
  archive_gnu,
  [
    create_archive/2, % +Files:list(atom)
                      % +Archive:atom
    create_tarball/2, % +Files:list(atom)
                      % +Tarball:atom
    extract_archive/1, % +FromFile:atom
    extract_archive/2, % +FromFile:atom
                       % -Conversions:list(oneof([gunzipped,untarred,unzipped]))
    is_archive_file/1 % +File:atom
  ]
).

/** <module> Archive extensions

Extensions to the support for archived files.

These predicates call GNU tools:
  - create_archive/2
  - create_tarball/2
  - extract_archive/[1,2]
  - is_archive/1

@author Wouter Beek
@version 2013/12-2014/05
*/

:- use_module(library(apply)).
:- use_module(library(filesex)).
:- use_module(library(process)).

:- use_module(generics(db_ext)).
:- use_module(os(dir_ext)).
:- use_module(os(file_ext)).

% application/x-bzip2
% .bz,.bz2,.tbz,.tbz2
%:- iana_register_mime(application, 'x-bzip2', bz2).
user:prolog_file_type(bz, archive).
user:prolog_file_type(bz, bunzip2).
user:prolog_file_type(bz2, archive).
user:prolog_file_type(bz2, bunzip2).
user:prolog_file_type(tbz, archive).
user:prolog_file_type(tbz, bunzip2).
user:prolog_file_type(tbz2, archive).
user:prolog_file_type(tbz2, bunzip2).
% application/x-gzip
% .gz
%:- iana_register_mime(application, 'x-gzip', gz).
user:prolog_file_type(gz, archive).
user:prolog_file_type(gz, gunzip).
% application/x-rar-compressed
% .rar
%:- iana_register_mime(application, 'x-rar-compressed', rar).
user:prolog_file_type(rar, archive).
user:prolog_file_type(rar, rar).
% application/x-tar
% .tar
% .tgz
%:- iana_register_mime(application, 'x-tar', tar).
user:prolog_file_type(tar, archive).
user:prolog_file_type(tar, tar).
% application/zip
% .zip
%:- iana_register_mime(application, 'zip', zip).
user:prolog_file_type(zip, archive).
user:prolog_file_type(zip, zip).



create_archive(Files, Archive):-
  findall(file(File), member(File, Files), O1),
  process_create(path(tar), ['-cjf',file(Archive)|O1], []).


create_tarball(Files, Archive):-
  findall(file(File), member(File, Files), O1),
  process_create(path(tar), ['-cf',file(Archive)|O1], []).


%! extract_archive(+FromFile:atom) is det.
% @see Wrapper around extract_archive/2.

extract_archive(File):-
  extract_archive(File, _).


%! extract_archive(
%!   +FromFile:atom,
%!   -Conversions:list(oneof([gunzipped,untarred,unzipped]))
%! ) is det.

extract_archive(FromFile1, Conversions):-
  file_name_extension(_, tgz, FromFile1), !,
  file_alternative(FromFile1, _, _, '.tar.gz', FromFile2),
  rename_file(FromFile1, FromFile2),
  extract_archive(FromFile2, Conversions).
user:prolog_file_type(tgz, archive).
extract_archive(FromFile, L):-
  file_name_extension(Base, Ext, FromFile),
  prolog_file_type(Ext, archive), !,
  extract_archive(Ext, FromFile, H),
  extract_archive(Base, T),
  L = [H|T].
extract_archive(_, []).


%! extract_archive(
%!   +Extension:oneof([bz2,gz,tgz,zip]),
%!   +FromFile:atom,
%!   -Conversion:oneof([gunzipped,untarred,unzipped])
%! ) is semidet.

extract_archive(Extension, File, gunzipped):-
  prolog_file_type(Extension, bunzip2), !,
  process_create(path(bunzip2), ['-f',file(File)], []).
extract_archive(Extension, File, gunzipped):-
  prolog_file_type(Extension, gunzip), !,
  process_create(path(gunzip), ['-f',file(File)], []).
extract_archive(Extension, File, untarred):-
  prolog_file_type(Extension, tar), !,
  directory_file_path(Directory, _, File),
  atomic_list_concat(['--directory',Directory], '=', C),
  process_create(path(tar), [xvf,file(File),C], []),
  delete_file(File).
extract_archive(Extension, File, unzipped):-
  prolog_file_type(Extension, zip), !,
  directory_file_path(Directory, _, File),
  process_create(path(unzip), [file(File),'-fo','-d',file(Directory)], []),
  delete_file(File).


%! is_archive_file(+File:atom) is semidet.

is_archive_file(File):-
  file_name_extension(_, Ext, File),
  prolog_file_type(Ext, archive), !.

