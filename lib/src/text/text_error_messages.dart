// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'package:meta/meta.dart';

// import 'package:time_machine/src/time_machine_internal.dart';

@internal
abstract class TextErrorMessages
{
  static const String ambiguousLocalTime = 'The local date/time is ambiguous in the target time zone.';
  static const String calendarAndEra = 'The era specifier cannot be specified in the same pattern as the calendar specifier.';
  static const String dateFieldAndEmbeddedDate = 'Custom date specifiers cannot be specified in the same pattern as an embedded date specifier';
  static const String dateSeparatorMismatch = 'The value string does not match a date separator in the format string.';
  static const String dayOfMonthOutOfRange = 'The day {0} is out of range in month {1} of year {2}.';
  static const String dayOfMonthOutOfRangeNoYear = 'The day {0} is out of range in month {1}.';
  static const String emptyPeriod = 'The specified period was empty.';
  static const String emptyZPrefixedOffsetPattern = 'The Z prefix for an Offset pattern must be followed by a custom pattern.';
  static const String endOfString = 'Input string ended unexpectedly early.';
  static const String eraWithoutYearOfEra = "The era specifier cannot be used without the \"year of era\" specifier.";
  static const String escapeAtEndOfString = "The format string has an escape character (backslash '\') at the end of the string.";
  static const String escapedCharacterMismatch = "The value string does not match an escaped character in the format string: \"{0}\"";
  static const String expectedEndOfString = 'Expected end of input, but more data remains.';
  static const String extraValueCharacters = "The format matches a prefix of the value string but not the entire string. Part not matching: \"{0}\".";
  static const String fieldValueOutOfRange = "The value {0} is out of range for the field '{1}' in the {2} type.";
  static const String formatOnlyPattern = 'This pattern is only capable of formatting, not parsing.';
  static const String formatStringEmpty = 'The format string is empty.';
  static const String hour12PatternNotSupported = "The 'h' pattern flag (12 hour format) is not supported by the {0} type.";
  static const String inconsistentDayOfWeekTextValue = 'The specified day of the week does not matched the computed value.';
  static const String inconsistentMonthTextValue = 'The month values specified as text and numbers are inconsistent.';
  static const String inconsistentValues2 = "The individual values for the fields '{0}' and '{1}' created an inconsistency in the {2} type.";
  static const String invalidEmbeddedPatternType = 'The type of embedded pattern is not supported for this type.';
  static const String invalidHour24 = '24 is only valid as an hour number when the units smaller than hours are all 0.';
  static const String invalidOffset = 'The specified offset is invalid for the given date/time.';
  static const String invalidRepeatCount = "The number of consecutive copies of the pattern character \"{0}\" in the format string ({1}) is invalid.";
  static const String invalidUnitSpecifier = "The period unit specifier '{0}' is invalid.";
  static const String isoMonthOutOfRange = 'The month {0} is out of range in the ISO calendar.';
  static const String mismatchedCharacter = "The value string does not match a simple character in the format string \"{0}\".";
  static const String mismatchedNumber = "The value string does not match the required number from the format string \"{0}\".";
  static const String mismatchedText = "The value string does not match the text-based field '{0}'.";
  static const String misplacedUnitSpecifier = "The period unit specifier '{0}' appears at the wrong place in the input string.";
  static const String missingAmPmDesignator = 'The value string does not match the AM or PM designator for the culture at the required place.';
  static const String missingEmbeddedPatternEnd = "The pattern has an embedded pattern which is missing its closing character ('{0}').";
  static const String missingEmbeddedPatternStart = "The pattern has an embedded pattern which is missing its opening character ('{0}').";
  static const String missingEndQuote = "The format string is missing the end quote character \"{0}\".";
  static const String missingNumber = 'The value string does not include a number in the expected position.';
  static const String missingSign = 'The required value sign is missing.';
  static const String monthOutOfRange = 'The month {0} is out of range in year {1}.';
  static const String multipleCapitalSpanFields = "Only one of \"D\", \"H\", \"M\" or \"S\" can occur in a span format string.";
  static const String noMatchingCalendarSystem = 'The specified calendar id is not recognized.';
  static const String noMatchingFormat = 'None of the specified formats matches the given value string.';
  static const String noMatchingZoneId = 'The specified time zone identifier is not recognized.';
  static const String overallValueOutOfRange = 'Value is out of the legal range for the {0} type.';
  static const String percentAtEndOfString = 'A percent sign (%) appears at the end of the format string.';
  static const String percentDoubled = 'A percent sign (%) is followed by another percent sign in the format string.';
  static const String positiveSignInvalid = 'A positive value sign is not valid at this point.';
  static const String quotedStringMismatch = 'The value string does not match a quoted string in the pattern.';
  static const String repeatCountExceeded = "There were more consecutive copies of the pattern character \"{0}\" than the maximum allowed ({1}) in the format string.";
  static const String repeatedFieldInPattern = "The field \"{0}\" is specified multiple times in the pattern.";
  static const String repeatedUnitSpecifier = "The period unit specifier '{0}' appears multiple times in the input string.";
  static const String skippedLocalTime = 'The local date/time is skipped in the target time zone.';
  static const String timeFieldAndEmbeddedTime = 'Custom time specifiers cannot be specified in the same pattern as an embedded time specifier';
  static const String timeSeparatorMismatch = 'The value string does not match a time separator in the format string.';
  static const String unexpectedNegative = 'The value string includes a negative value where only a non-negative one is allowed.';
  static const String unknownStandardFormat = "The standard format \"{0}\" is not valid for the {1} type. If the pattern was intended to be a custom format, escape it with a percent sign: \"%{0}\".";
  static const String unparsableValue = "{0} Value being parsed: '{1}'. (^ indicates error position.)";
  static const String unparsableValuePostParse = "{0} Value being parsed: '{1}'.";
  static const String unquotedLiteral = 'The character {0} is not a format specifier, and should be quoted to act as a literal.';
  static const String valueOutOfRange = 'The value {0} is out of the legal range for the {1} type.';
  static const String valueStringEmpty = 'The value string is empty.';
  static const String yearOfEraOutOfRange = 'The year {0} is out of range for the {1} era in the {2} calendar.';
  static const String zPrefixNotAtStartOfPattern = 'The Z prefix for an Offset pattern must occur at the beginning of the pattern.';
}
