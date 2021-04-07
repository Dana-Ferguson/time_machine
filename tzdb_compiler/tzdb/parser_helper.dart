import 'package:time_machine/src/time_machine_internal.dart';

/// Contains helper methods for parsing the TZDB files.
// todo: internal static
abstract class ParserHelper {
  static final List<LocalTimePattern> _timePatterns =
  [
    LocalTimePattern.createWithInvariantCulture('H:mm:ss.FFF'),
    LocalTimePattern.createWithInvariantCulture('H:mm'),
    LocalTimePattern.createWithInvariantCulture('%H'),
    // Handle 'somewhat broken' data such as a DAVT rule in Antarctica 2009r, with a date/time of "2009 Oct 18 2:0"
    LocalTimePattern.createWithInvariantCulture('H:m')
  ];

  /// Converts an hour string to its long value.
  ///
  /// <param name='text'>The text to convert.</param>
  /// <returns>The hour in the range [-23, 23].</returns>
  /// <exception cref='FormatException'>If the text is not a valid integer in the range [-23, 23].</exception>
  // todo: was long
  // todo: we don't use ticks anymore
  static int _convertHourToNanoseconds(String text) {
    Preconditions.checkNotNull(text, 'text');
    int value = int.parse(text);
    if (value < -23 || value > 23) {
      throw FormatException('hours out of valid range of [-23, 23]: $value');
    }

    return value * TimeConstants.nanosecondsPerHour;
  }

  /// Converts a minute string to its long value.
  ///
  /// <param name='text'>The text to convert.</param>
  /// <returns>The minute in the range [0, 59].</returns>
  /// <exception cref='FormatException'>If the text is not a valid integer in the range [0, 59].</exception>
  // todo: was long
  static int _convertMinuteToNanoseconds(String text) {
    Preconditions.checkNotNull(text, 'text');
    int value = int.parse(text.trim());
    if (value < 0 || value > 59) {
      throw FormatException('minutes out of valid range of [0, 59]: $value');
    }
    return value * TimeConstants.nanosecondsPerMinute;
  }

  /// Converts a second string to its double value.
  ///
  /// <param name='text'>The text to convert.</param>
  /// <returns>The second in the range [0, 60).</returns>
  /// <exception cref='FormatException'>If the text is not a valid integer in the range [0, 60).</exception>
  // todo: was long
  static int _convertSecondsWithFractionalToNanoseconds(String text) {
    Preconditions.checkNotNull(text, 'text');
    double number = double.parse(text.trim());
    if (number < 0.0 || number >= 60.0) {
      throw FormatException('seconds out of valid range of [0, 60): $number');
    }
    int value = (number * TimeConstants.nanosecondsPerSecond).toInt();
    return value;
  }

  /// Formats the optional.
  ///
  /// <param name='value'>The value.</param>
  static String formatOptional(String? value) => value ?? '-';

  /// Parses the given text for an integer. Leading and trailing white space is ignored.
  ///
  /// <param name='text'>The text to parse.</param>
  /// <param name='defaultValue'>The default value to use if the number cannot be parsed.</param>
  /// <returns>An integer.</returns>
  /// <exception cref='FormatException'>If the text is not a valid integer.</exception>
  static int parseInteger(String? text, int defaultValue) {
    if (text == null) return defaultValue;
    return int.tryParse(text) ?? defaultValue;
  }

  /// Parses a time offset string into an integer number of ticks.
  ///
  /// <param name='text'>The value to parse.</param>
  /// <returns>an integer number of ticks</returns>
  static Offset parseOffset(String text) {
    // Some old files use '-' for 0 in a few places.
    // Example: Tonga, 1999f.
    if (text == '-') {
      return Offset.zero;
    }
    // TODO(2.0): Use normal parsers!
    Preconditions.checkNotNull(text, 'text');
    int sign = 1;
    if (text.startsWith('-')) {
      sign = -1;
      text = text.substring(1);
    }
    var parts = text.split(':');
    if (parts.length > 3) {
      throw FormatException('Offset has too many colon separated parts (max of 3 allowed): ' + text);
    }
    int nanoseconds = _convertHourToNanoseconds(parts[0]);
    if (parts.length > 1) {
      nanoseconds += _convertMinuteToNanoseconds(parts[1]);
      if (parts.length > 2) {
        nanoseconds += _convertSecondsWithFractionalToNanoseconds(parts[2]);
      }
    }
    nanoseconds = nanoseconds * sign;

    return Offset.time(Time(nanoseconds: nanoseconds));
  }

  static LocalTime ParseTime(String text) {
    for (var pattern in _timePatterns) {
      var result = pattern.parse(text);
      if (result.success) {
        return result.value;
      }
    }
    throw FormatException('Invalid time in rules: $text');
  }

  /// Parses an optional value. If the string value is '-' then null is returned otherwise the
  /// input string is returned.
  ///
  /// <param name='text'>The value to parse.</param>
  /// <returns>The input string or null.</returns>
  static String? ParseOptional(String text) {
    Preconditions.checkNotNull(text, 'text');
    return text == '-' ? null : text;
  }

  /// Parses the year.
  ///
  /// <param name='text'>The text to parse.</param>
  /// <param name='defaultValue'>The default value.</param>
  /// <returns>The parsed year.</returns>
  static int ParseYear(String text, int defaultValue) {
    text = text.toLowerCase();
    switch (text) {
      case 'min':
      case 'minimum':
        return Platform.int32MinValue;
      case 'max':
      case 'maximum':
        return Platform.int32MaxValue;
      case 'only':
        return defaultValue;
      default:
        return int.parse(text);
    }
  }
}
