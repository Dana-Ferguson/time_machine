// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/Text/TextErrorMessages.cs
// c77bb7b May 8th 2018

import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_timezones.dart';
import 'package:time_machine/time_machine_text.dart';

@internal abstract class TextErrorMessages
{
  @internal static const String AmbiguousLocalTime = "The local date/time is ambiguous in the target time zone.";
  @internal static const String CalendarAndEra = "The era specifier cannot be specified in the same pattern as the calendar specifier.";
  @internal static const String DateFieldAndEmbeddedDate = "Custom date specifiers cannot be specified in the same pattern as an embedded date specifier";
  @internal static const String DateSeparatorMismatch = "The value string does not match a date separator in the format string.";
  @internal static const String DayOfMonthOutOfRange = "The day {0} is out of range in month {1} of year {2}.";
  @internal static const String DayOfMonthOutOfRangeNoYear = "The day {0} is out of range in month {1}.";
  @internal static const String EmptyPeriod = "The specified period was empty.";
  @internal static const String EmptyZPrefixedOffsetPattern = "The Z prefix for an Offset pattern must be followed by a custom pattern.";
  @internal static const String EndOfString = "Input string ended unexpectedly early.";
  @internal static const String EraWithoutYearOfEra = "The era specifier cannot be used without the \"year of era\" specifier.";
  @internal static const String EscapeAtEndOfString = "The format string has an escape character (backslash '\') at the end of the string.";
  @internal static const String EscapedCharacterMismatch = "The value string does not match an escaped character in the format string: \"{0}\"";
  @internal static const String ExpectedEndOfString = "Expected end of input, but more data remains.";
  @internal static const String ExtraValueCharacters = "The format matches a prefix of the value string but not the entire string. Part not matching: \"{0}\".";
  @internal static const String FieldValueOutOfRange = "The value {0} is out of range for the field '{1}' in the {2} type.";
  @internal static const String FormatOnlyPattern = "This pattern is only capable of formatting, not parsing.";
  @internal static const String FormatStringEmpty = "The format string is empty.";
  @internal static const String Hour12PatternNotSupported = "The 'h' pattern flag (12 hour format) is not supported by the {0} type.";
  @internal static const String InconsistentDayOfWeekTextValue = "The specified day of the week does not matched the computed value.";
  @internal static const String InconsistentMonthTextValue = "The month values specified as text and numbers are inconsistent.";
  @internal static const String InconsistentValues2 = "The individual values for the fields '{0}' and '{1}' created an inconsistency in the {2} type.";
  @internal static const String InvalidEmbeddedPatternType = "The type of embedded pattern is not supported for this type.";
  @internal static const String InvalidHour24 = "24 is only valid as an hour number when the units smaller than hours are all 0.";
  @internal static const String InvalidOffset = "The specified offset is invalid for the given date/time.";
  @internal static const String InvalidRepeatCount = "The number of consecutive copies of the pattern character \"{0}\" in the format string ({1}) is invalid.";
  @internal static const String InvalidUnitSpecifier = "The period unit specifier '{0}' is invalid.";
  @internal static const String IsoMonthOutOfRange = "The month {0} is out of range in the ISO calendar.";
  @internal static const String MismatchedCharacter = "The value string does not match a simple character in the format string \"{0}\".";
  @internal static const String MismatchedNumber = "The value string does not match the required number from the format string \"{0}\".";
  @internal static const String MismatchedText = "The value string does not match the text-based field '{0}'.";
  @internal static const String MisplacedUnitSpecifier = "The period unit specifier '{0}' appears at the wrong place in the input string.";
  @internal static const String MissingAmPmDesignator = "The value string does not match the AM or PM designator for the culture at the required place.";
  @internal static const String MissingEmbeddedPatternEnd = "The pattern has an embedded pattern which is missing its closing character ('{0}').";
  @internal static const String MissingEmbeddedPatternStart = "The pattern has an embedded pattern which is missing its opening character ('{0}').";
  @internal static const String MissingEndQuote = "The format string is missing the end quote character \"{0}\".";
  @internal static const String MissingNumber = "The value string does not include a number in the expected position.";
  @internal static const String MissingSign = "The required value sign is missing.";
  @internal static const String MonthOutOfRange = "The month {0} is out of range in year {1}.";
  @internal static const String MultipleCapitalDurationFields = "Only one of \"D\", \"H\", \"M\" or \"S\" can occur in a duration format string.";
  @internal static const String NoMatchingCalendarSystem = "The specified calendar id is not recognized.";
  @internal static const String NoMatchingFormat = "None of the specified formats matches the given value string.";
  @internal static const String NoMatchingZoneId = "The specified time zone identifier is not recognized.";
  @internal static const String OverallValueOutOfRange = "Value is out of the legal range for the {0} type.";
  @internal static const String PercentAtEndOfString = "A percent sign (%) appears at the end of the format string.";
  @internal static const String PercentDoubled = "A percent sign (%) is followed by another percent sign in the format string.";
  @internal static const String PositiveSignInvalid = "A positive value sign is not valid at this point.";
  @internal static const String QuotedStringMismatch = "The value string does not match a quoted string in the pattern.";
  @internal static const String RepeatCountExceeded = "There were more consecutive copies of the pattern character \"{0}\" than the maximum allowed ({1}) in the format string.";
  @internal static const String RepeatedFieldInPattern = "The field \"{0}\" is specified multiple times in the pattern.";
  @internal static const String RepeatedUnitSpecifier = "The period unit specifier '{0}' appears multiple times in the input string.";
  @internal static const String SkippedLocalTime = "The local date/time is skipped in the target time zone.";
  @internal static const String TimeFieldAndEmbeddedTime = "Custom time specifiers cannot be specified in the same pattern as an embedded time specifier";
  @internal static const String TimeSeparatorMismatch = "The value string does not match a time separator in the format string.";
  @internal static const String UnexpectedNegative = "The value string includes a negative value where only a non-negative one is allowed.";
  @internal static const String UnknownStandardFormat = "The standard format \"{0}\" is not valid for the {1} type. If the pattern was intended to be a custom format, escape it with a percent sign: \"%{0}\".";
  @internal static const String UnparsableValue = "{0} Value being parsed: '{1}'. (^ indicates error position.)";
  @internal static const String UnparsableValuePostParse = "{0} Value being parsed: '{1}'.";
  @internal static const String UnquotedLiteral = "The character {0} is not a format specifier, and should be quoted to act as a literal.";
  @internal static const String ValueOutOfRange = "The value {0} is out of the legal range for the {1} type.";
  @internal static const String ValueStringEmpty = "The value string is empty.";
  @internal static const String YearOfEraOutOfRange = "The year {0} is out of range for the {1} era in the {2} calendar.";
  @internal static const String ZPrefixNotAtStartOfPattern = "The Z prefix for an Offset pattern must occur at the beginning of the pattern.";
}