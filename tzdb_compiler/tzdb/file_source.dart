import 'dart:io';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as Path;

/// A random access collection of files.
// todo: internal sealed
class FileSource {
  /// The name of the origin of the files - just the last part,
  /// rather than the whole URL/path.
  final String origin;

  // Could create a ReadOnlyCollection if we ever wanted to make this public
  /// The names of
  final List<String> names;

  final List<int> Function(String) _openFunction;

  FileSource._(this.names, this._openFunction, String fullOrigin) :
        // Path.GetFileName(fullOrigin);
        origin = Path.basename(fullOrigin);

  List<int> open(String name) => _openFunction(name);

  bool contains(String name) => names.contains(name);

  static FileSource fromArchive(List<int> archiveData, String fullOrigin) {
    var entries = <String, List<int>>{}; // new Dictionary<String, byte[]>();
    var data = TarDecoder().decodeBytes(archiveData);

    data.files.forEach((file) {
      entries[file.name] = file.content;
    });

    return new FileSource._(entries.keys.toList(),
            (String file) => entries[file], fullOrigin);
  }

  static FileSource fromDirectory(String path) {
    // .Select(p => Path.GetFileName(p)).ToList()
    var files = Directory(path).listSync().map((f) => Path.basename(f.path)).toList();

    // todo: I don't understand that last argument
    File(path).readAsBytesSync();
    return new FileSource._(files, (file) => File(Path.join(path, file)).readAsBytesSync(), Path.basename(path));
  }

  // todo: I think this works?
  Iterable<String> readLines(String name) {
    var bytes = open(name);
    return LineSplitter.split(utf8.decode(bytes));
  }
}