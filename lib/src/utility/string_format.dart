// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
// todo: these should really be contained in a class

// https://regexr.com/
// Capturing Group 1: Arg Index
// Capturing Group 3: Special Format
const String _basicArgPattern = r"\{(\d+)(:([A-Za-z0-9]*))?\}";
final _pattern = RegExp(_basicArgPattern);

/// Simulates basic dotnet BCL string.Format functionality to ease porting. Invariant Culture only.
String stringFormat(String text, [List<dynamic> args = const []]) {
  if (args.isEmpty) return text;
  return text.replaceAllMapped(_pattern, (match) => _replacer(match, args));
}

// todo: should probably throw some errors or something?
String _replacer(Match match, List<dynamic> args) {
  var indexToken = match[1];
  if (indexToken == null) return '';
  var index = int.parse(indexToken);

  var formatToken = match[3];
  // Just ignoring them for now?
  if (formatToken != null) print('Found a formatToken: $formatToken');

  if (args.length <= index) return '';
  return args[index]!.toString();
}

String stringInsert(String text, int index, String value) {
  if (index <= 0) return value + text;
  if (index >= text.length) return text + value;
  return '${text.substring(0, index)}$value${text.substring(index)}';
}

String stringFilled(String text, int count) {
  StringBuffer sb = StringBuffer();
  for(int i = 0; i < count; i++) {
    sb.write(text);
  }
  return sb.toString();
}

abstract class StringFormatUtilities {
  static String zeroPadNumber(int n, int width) {
    if (n >= 0)
      return n.toString().padLeft(width, '0');
    else
      return '-' + n.abs().toString().padLeft(width, '0');
  }
}
