import 'dart:convert';

import 'package:time_machine/src/time_machine_internal.dart';

import 'tokens.dart';
import 'parser_helper.dart';
import 'tzdb_database.dart';
import 'rule_line.dart';
import 'zone_line.dart';

/// Provides a parser for TZDB time zone description files.
// todo: internal
class TzdbZoneInfoParser {
  /// The keyword that specifies the line defines an alias link.
  static const String _keywordLink = 'Link';

  /// The keyword that specifies the line defines a daylight savings rule.
  static const String _keywordRule = 'Rule';

  /// The keyword that specifies the line defines a time zone.
  static const String _keywordZone = 'Zone';

  /// <summary>
  /// The days of the week names as they appear in the TZDB zone files. They are
  /// always the short name in US English.
  /// </summary>
  static final List<String> _daysOfWeek = [ '', "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

  /// The months of the year names as they appear in the TZDB zone files. They are
  /// always the short name in US English.
  static final List<String> _shortMonths = [ '', "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

  /// ... except when they're actually the long month name, e.g. in Greece in 96d.
  /// (This is basically only for old files.)
  static final List<String> _longMonths =
  [ '', "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];

  /// Parses the next token as a month number (1-12).
  ///
  /// <param name='tokens'>The tokens.</param>
  /// <param name='name'>The name of the expected value, for use in the exception if no value is available.</param>
  int _nextMonth(Tokens tokens, String name) {
    var value = _nextString(tokens, name);
    return parseMonth(value);
  }

  /// Parses the next token as an offset.
  ///
  /// <param name='tokens'>The tokens.</param>
  /// <param name='name'>The name of the expected value, for use in the exception if no value is available.</param>
  Offset _nextOffset(Tokens tokens, String name) => ParserHelper.parseOffset(_nextString(tokens, name));

  /// Returns the next token, which is optional, converting '-' to null.
  ///
  /// <param name='tokens'>The tokens.</param>
  /// <param name='name'>The name of the expected value, for use in the exception if no value is available.</param>
  String? _nextOptional(Tokens tokens, String name) => ParserHelper.ParseOptional(_nextString(tokens, name));

  /// Returns the next string from the token stream.
  ///
  /// <param name='tokens'>The tokens to parse from.</param>
  /// <param name='name'>The name of the expected value, for use in the exception if no value is available.</param>
  String _nextString(Tokens tokens, String name) {
    if (!tokens.hasNextToken) {
      // InvalidDataException
      throw Exception('Missing zone info token: $name');
    }
    return tokens.nextToken(name)!;
  }

  /// Parses the next string from the token stream as a year.
  ///
  /// <param name='tokens'>The tokens.</param>
  /// <param name='defaultValue'>The default value to return if the year isn't specified.</param>
  static int _nextYear(Tokens tokens, int defaultValue) {
    int result = defaultValue;
    if (tokens.tryNextToken()) {
      result = ParserHelper.ParseYear(tokens.tryNextTokenResult!, defaultValue);
    }
    return result;
  }

  /// Parses the TZDB time zone info file from the given stream and merges its information
  /// with the given database. The stream is not closed or disposed.
  ///
  /// <param name='input'>The stream input to parse.</param>
  /// <param name='database'>The database to fill.</param>
  void parser(List<int> inputBytes, TzdbDatabase database) {
    var text = utf8.decode(inputBytes);

    String? currentZone;
    for (var line in LineSplitter.split(text)) {
      currentZone = _parseLine(line, currentZone, database);
    }
  }

  final _isLetter = RegExp('[a-zA-Z]');

  /// Parses the ZoneYearOffset for a rule or zone. This is something like '3rd Sunday of October at 2am'.
  ///
  /// <remarks>
  /// IN ON AT
  /// </remarks>
  /// <param name='tokens'>The tokens to parse.</param>
  /// <param name='forRule'>True if this is for a Rule line, in which case ON/AT are mandatory;
  /// false for a Zone line, in which case it's part of "until" and they're optional</param>
  /// <returns>The ZoneYearOffset object.</returns>
  ZoneYearOffset parseDateTimeOfYear(Tokens tokens, bool forRule) {
    var mode = ZoneYearOffset.StartOfYear.mode;
    var timeOfDay = ZoneYearOffset.StartOfYear.timeOfDay;

    int monthOfYear = _nextMonth(tokens, 'MonthOfYear');

    int dayOfMonth = 1;
    int dayOfWeek = 0;
    bool advanceDayOfWeek = false;
    bool addDay = false;

    if (tokens.hasNextToken || forRule) {
      var on = _nextString(tokens, 'On');
      if (on.startsWith('last')) {
        dayOfMonth = -1;
        dayOfWeek = _parseDayOfWeek(on.substring(4));
      }
      else {
        int index = on.indexOf('>=');
        if (index > 0) {
          dayOfMonth = int.parse(on.substring(index + 2));
          dayOfWeek = _parseDayOfWeek(on.substring(0, index));
          advanceDayOfWeek = true;
        }
        else {
          index = on.indexOf('<=');
          if (index > 0) {
            dayOfMonth = int.parse(on.substring(index + 2));
            dayOfWeek = _parseDayOfWeek(on.substring(0, index));
          }
          else {
            try {
              dayOfMonth = int.parse(on);
              dayOfWeek = 0;
            }
            // todo: does this mean the same things in Dart as it does in .NET?
            on FormatException catch (e) {
              throw ArgumentError('Unparsable ON token: $on, $e');
            }
          }
        }
      }

      if (tokens.hasNextToken || forRule) {
        var atTime = _nextString(tokens, 'AT');
        // if (!(atTime == null || atTime.isEmpty)) {
        if (atTime.isNotEmpty) {
          if (_isLetter.hasMatch(atTime[atTime.length - 1])) {
            String zoneCharacter = atTime[atTime.length - 1];
            mode = _convertModeCharacter(zoneCharacter);
            atTime = atTime.substring(0, atTime.length - 1);
          }
          if (atTime == '24:00') {
            timeOfDay = LocalTime.midnight;
            addDay = true;
          }
          // As of TZDB 2018f, Japan's fallback transitions occur at 25:00. We can't
          // represent this entirely accurately, but this is as close as we can approximate it.
          else if (atTime == '25:00') {
            timeOfDay = LocalTime(1, 0, 0);
            addDay = true;
          }
          else {
            timeOfDay = ParserHelper.ParseTime(atTime);
          }
        }
      }
    }
    return ZoneYearOffset(
        mode,
        monthOfYear,
        dayOfMonth,
        dayOfWeek,
        advanceDayOfWeek,
        timeOfDay,
        addDay);
  }

  /// <summary>
  /// Parses the day of week.
  /// </summary>
  /// <param name='text'>The text.</param>
  static int _parseDayOfWeek(String text) {
    Preconditions.checkArgument(text.isNotEmpty, 'text', "Value must not be empty or null");
    int index = _daysOfWeek.indexOf(text, 1);
    if (index == -1) {
      // InvalidDataException
      throw Exception('Invalid day of week: $text');
    }
    return index;
  }

  /// <summary>
  /// Parses a single line of an TZDB zone info file.
  /// </summary>
  /// <remarks>
  /// <para>
  /// TZDB files have a simple line based structure. Each line defines one item. Comments
  /// start with a hash or pound sign (#) and continue to the end of the line. Blank lines are
  /// ignored. Of the remaining there are four line types which are determined by the first
  /// keyword on the line.
  /// </para>
  /// <para>
  /// A line beginning with the keyword <c>Link</c> defines an alias between one time zone and
  /// another. Both time zones use the same definition but have different names.
  /// </para>
  /// <para>
  /// A line beginning with the keyword <c>Rule</c> defines a daylight savings time
  /// calculation rule.
  /// </para>
  /// <para>
  /// A line beginning with the keyword <c>Zone</c> defines a time zone.
  /// </para>
  /// <para>
  /// A line beginning with leading whitespace (an empty keyword) defines another part of the
  /// preceeding time zone. As many lines as necessary to define the time zone can be listed,
  /// but they must all be together and only the first line can have a name.
  /// </para>
  /// </remarks>
  /// <param name='line'>The line to parse.</param>
  /// <param name='database'>The database to fill.</param>
  /// <return>The zone name just parsed, if any - so that it can be passed into the next call.</return>
  String? _parseLine(String line, String? previousZone, TzdbDatabase database) {
    // Trim end-of-line comments
    int index = line.indexOf('#');
    if (index >= 0) {
      line = line.substring(0, index);
    }
    line = line.trimRight();
    if (line.isEmpty) {
      // We can still continue with the previous zone
      return previousZone;
    }

    // Okay, everything left in the line should be 'real' now.
    var tokens = Tokens.tokenize(line);
    var keyword = _nextString(tokens, 'Keyword');
    switch (keyword) {
      case _keywordRule:
        database.addRule(parseRule(tokens));
        return null;
      case _keywordLink:
        var alias = parseLink(tokens);
        database.addAlias(alias[0], alias[1]);
        return null;
      case _keywordZone:
        var name = _nextString(tokens, 'GetName');
        database.addZone(parseZone(name, tokens));
        return name;
      default:
        if (keyword.isEmpty) {
          if (previousZone == null) {
            // InvalidDataException
            throw Exception('Zone continuation provided with no previous zone line');
          }
          database.addZone(parseZone(previousZone, tokens));
          return previousZone;
        }
        else {
          // InvalidDataException
          throw Exception('Unexpected zone database keyword: $keyword');
        }
    }
  }

  /// <summary>
  /// Parses an alias link and returns the ZoneAlias object.
  /// </summary>
  /// <param name='tokens'>The tokens to parse.</param>
  /// <returns>The ZoneAlias object.</returns>
  List<String> parseLink(Tokens tokens) {
    var existing = _nextString(tokens, 'Existing');
    var alias = _nextString(tokens, 'Alias');
    return [existing, alias];
  }

  /// <summary>
  /// Parses the month.
  /// </summary>
  /// <param name='text'>The text.</param>
  /// <returns>The month number in the range 1 to 12.</returns>
  /// <exception cref='InvalidDataException'>The month name can't be parsed</exception>
  static int parseMonth(String text) {
    // Preconditions.checkArgument(!(text == null || text.isEmpty), 'text', "Value must not be empty or null");
    Preconditions.checkArgument(text.isNotEmpty, 'text', "Value must not be empty");
    int index = _shortMonths.indexOf(text, 1);
    if (index == -1) {
      index = _longMonths.indexOf(text, 1);
      if (index == -1) {
        // InvalidDataException
        throw Exception('Invalid month: $text');
      }
    }
    return index;
  }

  /// <summary>
  /// Parses a daylight savings rule and returns the Rule object.
  /// </summary>
  /// <remarks>
  /// # Rule    NAME    FROM    TO    TYPE    IN    ON    AT    SAVE    LETTER/S
  /// </remarks>
  /// <param name='tokens'>The tokens to parse.</param>
  /// <returns>The Rule object.</returns>
  RuleLine parseRule(Tokens tokens) {
    var name = _nextString(tokens, 'GetName');
    int fromYear = _nextYear(tokens, 0);

    // This basically doesn't happen these days, but if we have any recurrent rules
    // which start at the dawn of time, make them effective from 1900. This matches
    // zic behaviour in the only cases of this that we've seen, e.g. the systemv rules
    // prior to 2001a.
    if (fromYear == Platform.int32MinValue) {
      fromYear = 1900;
    }

    int toYear = _nextYear(tokens, fromYear);
    if (toYear < fromYear) {
      throw ArgumentError('To year cannot be before the from year in a Rule: $toYear < $fromYear');
    }
    var type = _nextOptional(tokens, 'Type');
    var yearOffset = parseDateTimeOfYear(tokens, true);
    var savings = _nextOffset(tokens, 'SaveMillis');
    var daylightSavingsIndicator = _nextOptional(tokens, 'LetterS')!;
    // The name of the zone recurrence is currently the name of the rule. Later (in ZoneRule.GetRecurrences)
    // it will be replaced with the formatted name. It's not ideal, but it avoids a lot of duplication.
    var recurrence = ZoneRecurrence(name, savings, yearOffset, fromYear, toYear);
    return RuleLine(recurrence, daylightSavingsIndicator, type);
  }

  /// <summary>
  ///   Parses a time zone definition and returns the Zone object.
  /// </summary>
  /// <remarks>
  ///   # GMTOFF RULES FORMAT [ UntilYear [ UntilMonth [ UntilDay [ UntilTime [ ZoneCharacter ] ] ] ] ]
  /// </remarks>
  /// <param name='name'>The name of the zone being parsed.</param>
  /// <param name='tokens'>The tokens to parse.</param>
  /// <returns>The Zone object.</returns>
  ZoneLine parseZone(String name, Tokens tokens) {
    var offset = _nextOffset(tokens, 'Gmt Offset');
    var rules = _nextOptional(tokens, 'Rules');
    var format = _nextString(tokens, 'Format');
    int year = _nextYear(tokens, Platform.int32MaxValue);

    if (tokens.hasNextToken) {
      var until = parseDateTimeOfYear(tokens, false);
      return ZoneLine(name, offset, rules, format, year, until);
    }

    return ZoneLine(name, offset, rules, format, year, ZoneYearOffset.StartOfYear);
  }

  /// Normalizes the transition mode characater.
  ///
  /// <param name='modeCharacter'>The character to normalize.</param>
  /// <returns>The <see cref='TransitionMode'/>.</returns>
  static TransitionMode _convertModeCharacter(String modeCharacter) {
    switch (modeCharacter) {
      case 's':
      case 'S':
        return TransitionMode.standard;
      case 'u':
      case 'U':
      case 'g':
      case 'G':
      case 'z':
      case 'Z':
        return TransitionMode.utc;
      default:
        return TransitionMode.wall;
    }
  }
}
