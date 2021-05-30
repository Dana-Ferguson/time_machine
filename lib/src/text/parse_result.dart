// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/utility/time_machine_utilities.dart';
import 'package:time_machine/src/calendars/time_machine_calendars.dart';
import 'package:time_machine/src/text/time_machine_text.dart';

// todo: we have some weird type interactions, with seemingly little benefit from having this be type <T> ... reconsider this?

/// The result of a parse operation.
///
/// [T]: The type which was parsed, such as a [LocalDateTime].
@immutable
class ParseResult<T> {
  late final T _value;
  final Error Function()? _errorProvider;
  final bool _continueAfterErrorWithMultipleFormats;

  // ignore: prefer_const_constructors_in_immutables
  ParseResult._error(this._errorProvider, this._continueAfterErrorWithMultipleFormats);

  // ignore: prefer_const_constructors_in_immutables
  ParseResult._(this._value)
      : _errorProvider = null,
        _continueAfterErrorWithMultipleFormats = false;

  /// Gets the value from the parse operation if it was successful, or throws an exception indicating the parse failure
  /// otherwise.
  ///
  /// This method is exactly equivalent to calling the [getValueOrThrow] method, but is terser if the code is
  /// already clear that it will throw if the parse failed.
  T get value => getValueOrThrow();

  /// Gets an exception indicating the cause of the parse failure.
  ///
  /// This property is typically used to wrap parse failures in higher level exceptions.
  ///
  /// * [StateError]: The parse operation succeeded.
  Error get error {
    if (_errorProvider == null) {
      // InvalidOperationException
      throw StateError('Parse operation succeeded, so no exception is available');
    }
    return _errorProvider!();
  }

  /// Gets the value from the parse operation if it was successful, or throws an exception indicating the parse failure
  /// otherwise.
  ///
  /// This method is exactly equivalent to fetching the [value] property, but more explicit in terms of throwing
  /// an exception on failure.
  ///
  /// Returns: The result of the parsing operation if it was successful.
  T getValueOrThrow() {
    if (_errorProvider == null) {
      return _value;
    }
    throw _errorProvider!();
  }

  /// Returns the success value, and sets the out parameter to either
  /// the specified failure value of T or the successful parse result value.
  ///
  /// * [failureValue]: The 'default' value to set in [result] if parsing failed.
  /// * [result]: The parameter to store the parsed value in on success.
  ///
  /// Returns: True if this parse result was successful, or false otherwise.
  T TryGetValue(T failureValue) {
    // todo: This did the true/false return _value ... this might alter how it's used (no longer doing that)
    return success ? _value : failureValue;
  }

  /// Indicates whether the parse operation was successful.
  ///
  /// This returns `true` if and only if fetching the value with the [value] property will return with no exception.
  bool get success => _errorProvider == null;

  /// Converts this result to a new target type, either by executing the given projection
  /// for a success result, or propagating the exception provider for failure.
  ///
  /// * [projection]: The projection to apply for the value of this result,
  /// if it's a success result.
  ///
  /// Returns: A ParseResult for the target type, either with a value obtained by applying the specified
  /// projection to the value in this result, or with the same error as this result.
  ParseResult<TTarget> convert<TTarget>(TTarget Function(T) projection) {
    Preconditions.checkNotNull(projection, 'projection');
    return success
        ? ParseResult.forValue<TTarget>(projection(value))
        : ParseResult<TTarget>._error(_errorProvider, _continueAfterErrorWithMultipleFormats);
  }

  /// Converts this result to a new target type by propagating the exception provider.
  /// This parse result must already be an error result.
  ///
  /// Returns: A ParseResult for the target type, with the same error as this result.
  ParseResult<TTarget> convertError<TTarget>() {
    if (success) {
      // InvalidOperationException
      throw StateError('ConvertError should not be called on a successful parse result');
    }
    return ParseResult<TTarget>._error(_errorProvider, _continueAfterErrorWithMultipleFormats);
  }

  // todo: convert to factories.. also, why are these public?

  /// Produces a ParseResult which represents a successful parse operation.
  ///
  /// When [T] is a reference type, [value] should not be null,
  /// but this isn't currently checked.
  ///
  /// * [value]: The successfully parsed value.
  ///
  /// Returns: A ParseResult representing a successful parsing operation.
  static ParseResult<T> forValue<T>(T value) => ParseResult<T>._(value);

  /// Produces a ParseResult which represents a failed parsing operation.
  ///
  /// This method accepts a delegate rather than the exception itself, as creating an
  /// exception can be relatively slow: if the client doesn't need the actual exception, just the information
  /// that the parse failed, there's no point in creating the exception.
  ///
  /// * [errorProvider]: A delegate that produces the exception representing the error that
  /// caused the parse to fail.
  ///
  /// Returns: A ParseResult representing a failed parsing operation.
  static ParseResult<T> forError<T>(Error Function() errorProvider) =>
      ParseResult<T>._error(Preconditions.checkNotNull(errorProvider, 'errorProvider'), false);
}

@internal
abstract class IParseResult {
  static bool continueAfterErrorWithMultipleFormats(ParseResult result) => result._continueAfterErrorWithMultipleFormats;

  static ParseResult<T> forInvalidValue<T>(ValueCursor cursor, String formatString, [List<dynamic> parameters = const []]) =>
      _forInvalidValueError(() {
        // Format the message which is specific to the kind of parse error.
        String detailMessage = stringFormat(formatString, parameters);
        // Format the overall message, containing the parse error and the value itself.
        String overallMessage = stringFormat(TextErrorMessages.unparsableValue, [detailMessage, cursor]);
        return UnparsableValueError(overallMessage);
      });

  static ParseResult<T> forInvalidValuePostParse<T>(String text, String formatString, [List<dynamic> parameters = const[]]) =>
      _forInvalidValueError(() {
        // Format the message which is specific to the kind of parse error.
        String detailMessage = stringFormat(formatString, parameters);
        // Format the overall message, containing the parse error and the value itself.
        String overallMessage = stringFormat(TextErrorMessages.unparsableValuePostParse, [detailMessage, text]);
        return UnparsableValueError(overallMessage);
      });

  // note: was ForInvalidValue
  static ParseResult<T> _forInvalidValueError<T>(Error Function() errorProvider) => ParseResult<T>._error(errorProvider, true);

  static ParseResult<T> argumentNull<T>(String parameter) => ParseResult<T>._error(() => ArgumentError.notNull(parameter), false);

  static ParseResult<T> positiveSignInvalid<T>(ValueCursor cursor) => forInvalidValue<T>(cursor, TextErrorMessages.positiveSignInvalid);

  // Special case: it's a fault with the value, but we still don't want to continue with multiple patterns.
  // Also, there's no point in including the text.
  static final ParseResult valueStringEmpty =
  ParseResult._error(() => UnparsableValueError(TextErrorMessages.valueStringEmpty), false);

  static ParseResult<T> extraValueCharacters<T>(ValueCursor cursor, String remainder) =>
      IParseResult.forInvalidValue<T>(cursor, TextErrorMessages.extraValueCharacters, [remainder]);

  static ParseResult<T> quotedStringMismatch<T>(ValueCursor cursor) => IParseResult.forInvalidValue<T>(cursor, TextErrorMessages.quotedStringMismatch);

  static ParseResult<T> escapedCharacterMismatch<T>(ValueCursor cursor, String patternCharacter) =>
      IParseResult.forInvalidValue<T>(cursor, TextErrorMessages.escapedCharacterMismatch, [patternCharacter]);

  static ParseResult<T> endOfString<T>(ValueCursor cursor) => IParseResult.forInvalidValue<T>(cursor, TextErrorMessages.endOfString);

  static ParseResult<T> timeSeparatorMismatch<T>(ValueCursor cursor) =>
      IParseResult.forInvalidValue<T>(cursor, TextErrorMessages.timeSeparatorMismatch);

  static ParseResult<T> dateSeparatorMismatch<T>(ValueCursor cursor) =>
      IParseResult.forInvalidValue<T>(cursor, TextErrorMessages.dateSeparatorMismatch);

  static ParseResult<T> missingNumber<T>(ValueCursor cursor) => IParseResult.forInvalidValue<T>(cursor, TextErrorMessages.missingNumber);

  static ParseResult<T> unexpectedNegative<T>(ValueCursor cursor) => IParseResult.forInvalidValue<T>(cursor, TextErrorMessages.unexpectedNegative);

  /// This isn't really an issue with the value so much as the pattern... but the result is the same.
  static final ParseResult formatOnlyPattern =
  ParseResult._error(() => UnparsableValueError(TextErrorMessages.formatOnlyPattern), true);

  static ParseResult<T> mismatchedNumber<T>(ValueCursor cursor, String pattern) =>
      forInvalidValue(cursor, TextErrorMessages.mismatchedNumber, [pattern]);

  static ParseResult<T> mismatchedCharacter<T>(ValueCursor cursor, String patternCharacter) =>
      forInvalidValue(cursor, TextErrorMessages.mismatchedCharacter, [patternCharacter]);

  static ParseResult<T> mismatchedText<T>(ValueCursor cursor, String field) => forInvalidValue(cursor, TextErrorMessages.mismatchedText, [field]);

  static ParseResult<T> noMatchingFormat<T>(ValueCursor cursor) => forInvalidValue(cursor, TextErrorMessages.noMatchingFormat);

  // todo: this will not work in JSDart
  static ParseResult<T> valueOutOfRange<T>(ValueCursor cursor, dynamic value, String tType) =>
      forInvalidValue(cursor, TextErrorMessages.valueOutOfRange, [value, tType]);

  static ParseResult<T> missingSign<T>(ValueCursor cursor) => forInvalidValue(cursor, TextErrorMessages.missingSign);

  static ParseResult<T> missingAmPmDesignator<T>(ValueCursor cursor) => forInvalidValue(cursor, TextErrorMessages.missingAmPmDesignator);

  static ParseResult<T> noMatchingCalendarSystem<T>(ValueCursor cursor) => forInvalidValue(cursor, TextErrorMessages.noMatchingCalendarSystem);

  static ParseResult<T> noMatchingZoneId<T>(ValueCursor cursor) => forInvalidValue(cursor, TextErrorMessages.noMatchingZoneId);

  static ParseResult<T> invalidHour24<T>(String text) => forInvalidValuePostParse(text, TextErrorMessages.invalidHour24);

  static ParseResult<T> fieldValueOutOfRange<T>(ValueCursor cursor, int value, String field, String tType) =>
      forInvalidValue(cursor, TextErrorMessages.fieldValueOutOfRange, [value, field, tType]);

  static ParseResult<T> fieldValueOutOfRangePostParse<T>(String text, int value, String field, String tType) =>
      forInvalidValuePostParse(text, TextErrorMessages.fieldValueOutOfRange, [value, field, tType]);

  /// Two fields (e.g. 'hour of day' and "hour of half day") were mutually inconsistent.
  static ParseResult<T> inconsistentValues<T>(String text, String field1, String field2, String tType) =>
      forInvalidValuePostParse(text, TextErrorMessages.inconsistentValues2, [field1, field2, tType]);

  /// The month of year is inconsistent between the text and numeric specifications.
  /// We can't use InconsistentValues for this as the pattern character is the same in both cases.
  static ParseResult<T> inconsistentMonthValues<T>(String text) => forInvalidValuePostParse(text, TextErrorMessages.inconsistentMonthTextValue);

  /// The day of month is inconsistent with the day of week value.
  /// We can't use InconsistentValues for this as the pattern character is the same in both cases.
  static ParseResult<T> inconsistentDayOfWeekTextValue<T>(String text) =>
      forInvalidValuePostParse(text, TextErrorMessages.inconsistentDayOfWeekTextValue);

  /// We'd expected to get to the end of the string now, but we haven't.
  static ParseResult<T> expectedEndOfString<T>(ValueCursor cursor) => forInvalidValue(cursor, TextErrorMessages.expectedEndOfString);

  static ParseResult<T> yearOfEraOutOfRange<T>(String text, int value, Era era, CalendarSystem calendar) =>
      forInvalidValuePostParse(text, TextErrorMessages.yearOfEraOutOfRange, [value, era.name, calendar.name]);

  static ParseResult<T> monthOutOfRange<T>(String text, int month, int year) =>
      forInvalidValuePostParse(text, TextErrorMessages.monthOutOfRange, [month, year]);

  static ParseResult<T> isoMonthOutOfRange<T>(String text, int month) =>
      forInvalidValuePostParse(text, TextErrorMessages.isoMonthOutOfRange, [month]);

  static ParseResult<T> dayOfMonthOutOfRange<T>(String text, int day, int month, int year) =>
      forInvalidValuePostParse(text, TextErrorMessages.dayOfMonthOutOfRange, [day, month, year]);

  static ParseResult<T> dayOfMonthOutOfRangeNoYear<T>(String text, int day, int month) =>
      forInvalidValuePostParse(text, TextErrorMessages.dayOfMonthOutOfRangeNoYear, [day, month]);

  static ParseResult<T> invalidOffset<T>(String text) => forInvalidValuePostParse(text, TextErrorMessages.invalidOffset);

  static ParseResult<T> skippedLocalTime<T>(String text) => forInvalidValuePostParse(text, TextErrorMessages.skippedLocalTime);

  static ParseResult<T> ambiguousLocalTime<T>(String text) => forInvalidValuePostParse(text, TextErrorMessages.ambiguousLocalTime);
}
