:- module(
  http_download_ext,
  [
    download_and_extract/3 % +Options:list(nvpair)
                           % +Url:url
                           % -Files:ordset(atom)
  ]
).

/** <module> HTTP download extensions

Advanced predicates for downloading over HTTP(S),
e.g. automatically extracting the downloaded files if they are archives.

@author Wouter Beek
@version 2013/05, 2013/09, 2013/11-2014/04
*/

:- use_module(library(option)).

:- use_module(http(http_download)).
:- use_module(os(archive_ext)).
:- use_module(os(dir_ext)).



%! download_and_extract(
%!   +Options:list(nvpair),
%!   +Url:url,
%!   -Files:list(atom)
%! ) is det.
% The following options are supported:
%   * =|file(+File:atom)|=
%     The file to which the contents at URL are located.
%   * The other options are passed to download_to_file/3.

download_and_extract(Options, Url, Files):-
  option(file(File), Options, _),
  setup_call_cleanup(
    download_to_file(Url, File, Options),
    extract_file(File),
    delete_file(File)
  ),
  
  % Gather all files.
  file_directory_name(File, Dir),
  directory_files(
    [
      include_directories(true),
      include_self(false),
      order(lexicographic),
      recursive(true)
    ],
    Dir,
    Files
  ).

