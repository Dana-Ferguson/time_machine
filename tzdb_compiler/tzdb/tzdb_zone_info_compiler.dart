// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:time_machine/src/time_machine_internal.dart';

import 'file_source.dart';
import 'tzdb_database.dart';
import 'tzdb_zone_info_parser.dart';
import 'tzdb_zone_location_parser.dart';

class TextWriter {
  final void Function(String text) WriteLine;

  TextWriter(this.WriteLine);
}

/// Provides a compiler for Olson (TZDB) zone info files into the internal format used by TimeMachine
/// for its [DateTimeZone] definitions. This reads a set of files and generates a resource file with
/// the compiled contents suitable for reading with [TzdbDateTimeZoneSource] or one of its variants.
class TzdbZoneInfoCompiler {
  static const String _makefile = 'Makefile';
  static const String _zone1970TabFile = 'zone1970.tab';
  static const String _iso3166TabFile = 'iso3166.tab';
  static const String _zoneTabFile = 'zone.tab';

  // todo: readonly collection, get only accessor
  static final List<String> _zoneFiles = [
    'africa', "antarctica", "asia", "australasia", "europe",
    'northamerica', "southamerica", "pacificnew", "etcetera", "backward", "systemv"
  ];

  static final RegExp _versionRegex = RegExp(r"\d{2,4}[a-z]");
  static final RegExp _versionRegex2 = RegExp(r"VERSION=\d{4}.*");

  final TextWriter? _log;

  /// Initializes a new instance of the [TzdbZoneInfoCompiler] class
  /// logging to standard output.
  factory TzdbZoneInfoCompiler() => TzdbZoneInfoCompiler.log(TextWriter((String text) => print(text)));

  /// Initializes a new instance of the [TzdbZoneInfoCompiler] class
  /// logging to the given text writer, which may be null.
  TzdbZoneInfoCompiler.log(this._log);

  /// Tries to compile the contents of a path to a TzdbDatabase. The path can be a directory
  /// name containing the TZDB files, or a local tar.gz file, or a remote tar.gz file.
  /// The version ID is taken from the Makefile, if it exists. Otherwise, an attempt is made to guess
  /// it based on the last element of the path, to match a regex of \d{2,4}[a-z] (anywhere within the element).
  TzdbDatabase compile(String path) {
    var source = _loadSource(path);
    var version = _inferVersion(source);
    var database = TzdbDatabase(version);
    _loadZoneFiles(source, database);
    _loadLocationFiles(source, database);
    return database;
  }

  void _loadZoneFiles(FileSource source, TzdbDatabase database) {
    var tzdbParser = TzdbZoneInfoParser();
    for (var file in _zoneFiles) {
      if (source.contains(file)) {
        _log?.WriteLine('Parsing file $file . . .');
        var bytes = source.open(file);
        tzdbParser.parser(bytes, database);
      }
    }
  }

  void _loadLocationFiles(FileSource source, TzdbDatabase database) {
    if (!source.contains(_iso3166TabFile)) {
      return;
    }
    var iso3166 = source.readLines(_iso3166TabFile)
        .where((line) => line != '' && !line.startsWith("#"))
        .map((line) => line.split('\t'))
        .toList();
    if (source.contains(_zoneTabFile)) {
      var iso3166Dict = { for (var bits in iso3166) bits[0] : bits[1] };
      database.zoneLocations = source.readLines(_zoneTabFile)
          .where((line) => line != '' && !line.startsWith("#"))
          .map((line) => TzdbZoneLocationParser.parseLocation(line, iso3166Dict))
          .toList();
    }
    if (source.contains(_zone1970TabFile)) {
      var iso3166Dict = { for (var bits in iso3166) bits[0] : TzdbZone1970LocationCountry(/*name:*/ bits[1], /*code:*/ bits[0]) };
      database.zone1970Locations = source.readLines(_zone1970TabFile)
          .where((line) => line != '' && !line.startsWith("#"))
          .map((line) => TzdbZoneLocationParser.parseEnhancedLocation(line, iso3166Dict))
          .toList();
    }
  }

  FileSource _loadSource(String path) {
    if (path.startsWith('ftp://') || path.startsWith("http://") || path.startsWith("https://")) {
      _log?.WriteLine('Downloading $path');

      var uri = Uri.parse(path);

      // todo: is there an awaitable method?
      http.get(uri).then((response) {
        var data = response.bodyBytes;

        _log?.WriteLine('Compiling from archive');

        // todo: was uri.AbsolutePath -- which we don't have, but, it gets turned into a filename??? so.. maybe??
        return FileSource.fromArchive(data, uri.pathSegments.last);
      });
    }

    if (Directory(path).existsSync()) {
    // if (FileSystemEntity.typeSync(path) != FileSystemEntityType.notFound) {
      _log?.WriteLine('Compiling from directory $path');
      return FileSource.fromDirectory(path);
    }
    else {
      _log?.WriteLine('Compiling from archive file $path');
      // todo: await
      var file = File(path).readAsBytesSync();
      return FileSource.fromArchive(file, path);
    }
  }

  String _inferVersion(FileSource source) {
    if (source.contains(_makefile)) {
      for (var line in source.readLines(_makefile)) {

        if (_versionRegex2.hasMatch(line)) {
          var version = line.substring(8).trim();
          _log?.WriteLine('Inferred version $version from $_makefile');
          return version;
        }
      }
    }

    var match = _versionRegex.firstMatch(source.origin);
    if (match != null) {
      String version = match.group(0)!;
      _log?.WriteLine('Inferred version $version from file/directory name ${source.origin}');
      return version;
    }
    // todo: InvalidDataException
    throw Exception('Unable to determine TZDB version from source');
  }
}
