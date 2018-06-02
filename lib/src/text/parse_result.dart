// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/Text/ParseResult.cs
// c77bb7b May 8th, 2018
import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_timezones.dart';
import 'package:time_machine/time_machine_text.dart';

/// <summary>
/// The result of a parse operation.
/// </summary>
/// <typeparam name="T">The type which was parsed, such as a <see cref="LocalDateTime"/>.</typeparam>
/// <threadsafety>This type is immutable reference type. See the thread safety section of the user guide for more information.</threadsafety>
@immutable
/*sealed*/ class ParseResult<T> {
  @private final T _value;
  @private final Error Function() errorProvider;
  @internal final bool ContinueAfterErrorWithMultipleFormats;

  @private ParseResult.error(this.errorProvider, this.ContinueAfterErrorWithMultipleFormats) : _value = null;

  @private ParseResult(this._value)
      : errorProvider = null,
        ContinueAfterErrorWithMultipleFormats = false;

  /// <summary>
  /// Gets the value from the parse operation if it was successful, or throws an exception indicating the parse failure
  /// otherwise.
  /// </summary>
  /// <remarks>
  /// This method is exactly equivalent to calling the <see cref="GetValueOrThrow"/> method, but is terser if the code is
  /// already clear that it will throw if the parse failed.
  /// </remarks>
  /// <value>The result of the parsing operation if it was successful.</value>
  T get Value => GetValueOrThrow();

  /// <summary>
  /// Gets an exception indicating the cause of the parse failure.
  /// </summary>
  /// <remarks>This property is typically used to wrap parse failures in higher level exceptions.</remarks>
  /// <value>The exception indicating the cause of the parse failure.</value>
  /// <exception cref="InvalidOperationException">The parse operation succeeded.</exception>
  Error get Exception {
    if (errorProvider == null) {
      // InvalidOperationException
      throw new StateError("Parse operation succeeded, so no exception is available");
    }
    return errorProvider();
  }

  /// <summary>
  /// Gets the value from the parse operation if it was successful, or throws an exception indicating the parse failure
  /// otherwise.
  /// </summary>
  /// <remarks>
  /// This method is exactly equivalent to fetching the <see cref="Value"/> property, but more explicit in terms of throwing
  /// an exception on failure.
  /// </remarks>
  /// <returns>The result of the parsing operation if it was successful.</returns>
  T GetValueOrThrow() {
    if (errorProvider == null) {
      return _value;
    }
    throw errorProvider();
  }

  /// <summary>
  /// Returns the success value, and sets the out parameter to either
  /// the specified failure value of T or the successful parse result value.
  /// </summary>
  /// <param name="failureValue">The "default" value to set in <paramref name="result"/> if parsing failed.</param>
  /// <param name="result">The parameter to store the parsed value in on success.</param>
  /// <returns>True if this parse result was successful, or false otherwise.</returns>
  T TryGetValue(T failureValue) {
    // todo: This did the true/false return _value ... this might alter how it's used (no longer doing that)
    return Success ? _value : failureValue;
  }

  /// <summary>
  /// Indicates whether the parse operation was successful.
  /// </summary>
  /// <remarks>
  /// This returns True if and only if fetching the value with the <see cref="Value"/> property will return with no exception.
  /// </remarks>
  /// <value>true if the parse operation was successful; otherwise false.</value>
  bool get Success => errorProvider == null;

  /// <summary>
  /// Converts this result to a new target type, either by executing the given projection
  /// for a success result, or propagating the exception provider for failure.
  /// </summary>
  /// <param name="projection">The projection to apply for the value of this result,
  /// if it's a success result.</param>
  /// <returns>A ParseResult for the target type, either with a value obtained by applying the specified
  /// projection to the value in this result, or with the same error as this result.</returns>

  ParseResult<TTarget> Convert<TTarget>(TTarget Function(T) projection) {
    Preconditions.checkNotNull(projection, 'projection');
    return Success
        ? ParseResult.ForValue<TTarget>(projection(Value))
        : new ParseResult<TTarget>.error(errorProvider, ContinueAfterErrorWithMultipleFormats);
  }

  /// <summary>
  /// Converts this result to a new target type by propagating the exception provider.
  /// This parse result must already be an error result.
  /// </summary>
  /// <returns>A ParseResult for the target type, with the same error as this result.</returns>
  ParseResult<TTarget> ConvertError<TTarget>() {
    if (Success) {
      // InvalidOperationException
      throw new StateError("ConvertError should not be called on a successful parse result");
    }
    return new ParseResult<TTarget>.error(errorProvider, ContinueAfterErrorWithMultipleFormats);
  }

  // #region Factory methods and readonly static fields

  /// <summary>
  /// Produces a ParseResult which represents a successful parse operation.
  /// </summary>
  /// <remarks>When T is a reference type, <paramref name="value"/> should not be null,
  /// but this isn't currently checked.</remarks>
  /// <param name="value">The successfully parsed value.</param>
  /// <returns>A ParseResult representing a successful parsing operation.</returns>
  static ParseResult<T> ForValue<T>(T value) => new ParseResult<T>(value);

  /// <summary>
  /// Produces a ParseResult which represents a failed parsing operation.
  /// </summary>
  /// <remarks>This method accepts a delegate rather than the exception itself, as creating an
  /// exception can be relatively slow: if the client doesn't need the actual exception, just the information
  /// that the parse failed, there's no point in creating the exception.</remarks>
  /// <param name="exceptionProvider">A delegate that produces the exception representing the error that
  /// caused the parse to fail.</param>
  /// <returns>A ParseResult representing a failed parsing operation.</returns>
  static ParseResult<T> ForException<T>(Error Function() exceptionProvider) =>
      new ParseResult<T>.error(Preconditions.checkNotNull(exceptionProvider, 'exceptionProvider'), false);

  @internal static ParseResult<T> ForInvalidValue<T>(ValueCursor cursor, String formatString, [List<dynamic> parameters = const []]) =>
      ForInvalidValueError(() => _forInvalidValueExceptionProvider(cursor, formatString, parameters));

  static Error _forInvalidValueExceptionProvider(ValueCursor cursor, String formatString, List<dynamic> parameters) {
    // Format the message which is specific to the kind of parse error.
    String detailMessage = stringFormat(formatString, parameters);
    // Format the overall message, containing the parse error and the value itself.
    String overallMessage = stringFormat(TextErrorMessages.UnparsableValue, [detailMessage, cursor]);
    return new UnparsableValueError(overallMessage);
  }

  @internal static ParseResult<T> ForInvalidValuePostParse<T>(String text, String formatString, [List<dynamic> parameters = const[]]) =>
      ForInvalidValueError(() => _forInvalidValuePostParseExceptionProvider(text, formatString, parameters));

  static Error _forInvalidValuePostParseExceptionProvider(String text, String formatString, List<dynamic> parameters) {
    // Format the message which is specific to the kind of parse error.
    String detailMessage = stringFormat(formatString, parameters);
    // Format the overall message, containing the parse error and the value itself.
    String overallMessage = stringFormat(TextErrorMessages.UnparsableValuePostParse, [detailMessage, text]);
    return new UnparsableValueError(overallMessage);
  }

  // note: was ForInvalidValue
  @private static ParseResult<T> ForInvalidValueError<T>(Error Function() exceptionProvider) => new ParseResult<T>.error(exceptionProvider, true);

  @internal static ParseResult<T> ArgumentNull<T>(String parameter) => new ParseResult<T>.error(() => new ArgumentError.notNull(parameter), false);

  @internal static ParseResult<T> PositiveSignInvalid<T>(ValueCursor cursor) => ForInvalidValue<T>(cursor, TextErrorMessages.PositiveSignInvalid);

  // Special case: it's a fault with the value, but we still don't want to continue with multiple patterns.
  // Also, there's no point in including the text.
  @internal static final ParseResult ValueStringEmpty =
  new ParseResult.error(() => new UnparsableValueError(TextErrorMessages.ValueStringEmpty), false);

  @internal static ParseResult<T> ExtraValueCharacters<T>(ValueCursor cursor, String remainder) =>
      ParseResult.ForInvalidValue<T>(cursor, TextErrorMessages.ExtraValueCharacters, [remainder]);

  @internal static ParseResult<T> QuotedStringMismatch<T>(ValueCursor cursor) => ParseResult.ForInvalidValue<T>(cursor, TextErrorMessages.QuotedStringMismatch);

  @internal static ParseResult<T> EscapedCharacterMismatch<T>(ValueCursor cursor, String patternCharacter) =>
      ParseResult.ForInvalidValue<T>(cursor, TextErrorMessages.EscapedCharacterMismatch, [patternCharacter]);

  @internal static ParseResult<T> EndOfString<T>(ValueCursor cursor) => ParseResult.ForInvalidValue<T>(cursor, TextErrorMessages.EndOfString);

  @internal static ParseResult<T> TimeSeparatorMismatch<T>(ValueCursor cursor) =>
      ParseResult.ForInvalidValue<T>(cursor, TextErrorMessages.TimeSeparatorMismatch);

  @internal static ParseResult<T> DateSeparatorMismatch<T>(ValueCursor cursor) =>
      ParseResult.ForInvalidValue<T>(cursor, TextErrorMessages.DateSeparatorMismatch);

  @internal static ParseResult<T> MissingNumber<T>(ValueCursor cursor) => ParseResult.ForInvalidValue<T>(cursor, TextErrorMessages.MissingNumber);

  @internal static ParseResult<T> UnexpectedNegative<T>(ValueCursor cursor) => ParseResult.ForInvalidValue<T>(cursor, TextErrorMessages.UnexpectedNegative);

  /// <summary>
  /// This isn't really an issue with the value so much as the pattern... but the result is the same.
  /// </summary>
  @internal static final ParseResult FormatOnlyPattern =
  new ParseResult.error(() => new UnparsableValueError(TextErrorMessages.FormatOnlyPattern), true);

  @internal static ParseResult<T> MismatchedNumber<T>(ValueCursor cursor, String pattern) =>
      ForInvalidValue(cursor, TextErrorMessages.MismatchedNumber, [pattern]);

  @internal static ParseResult<T> MismatchedCharacter<T>(ValueCursor cursor, String patternCharacter) =>
      ForInvalidValue(cursor, TextErrorMessages.MismatchedCharacter, [patternCharacter]);

  @internal static ParseResult<T> MismatchedText<T>(ValueCursor cursor, String field) => ForInvalidValue(cursor, TextErrorMessages.MismatchedText, [field]);

  @internal static ParseResult<T> NoMatchingFormat<T>(ValueCursor cursor) => ForInvalidValue(cursor, TextErrorMessages.NoMatchingFormat);

  // todo: this will not work in JSDart
  @internal static ParseResult<T> ValueOutOfRange<T>(ValueCursor cursor, dynamic value) =>
      ForInvalidValue(cursor, TextErrorMessages.ValueOutOfRange, [value, value.runtimeType]);

  @internal static ParseResult<T> MissingSign<T>(ValueCursor cursor) => ForInvalidValue(cursor, TextErrorMessages.MissingSign);

  @internal static ParseResult<T> MissingAmPmDesignator<T>(ValueCursor cursor) => ForInvalidValue(cursor, TextErrorMessages.MissingAmPmDesignator);

  @internal static ParseResult<T> NoMatchingCalendarSystem<T>(ValueCursor cursor) => ForInvalidValue(cursor, TextErrorMessages.NoMatchingCalendarSystem);

  @internal static ParseResult<T> NoMatchingZoneId<T>(ValueCursor cursor) => ForInvalidValue(cursor, TextErrorMessages.NoMatchingZoneId);

  @internal static ParseResult<T> InvalidHour24<T>(String text) => ForInvalidValuePostParse(text, TextErrorMessages.InvalidHour24);

  @internal static ParseResult<T> FieldValueOutOfRange<T>(ValueCursor cursor, int value, String field, String tType) =>
      ForInvalidValue(cursor, TextErrorMessages.FieldValueOutOfRange, [value, field, tType]);

  @internal static ParseResult<T> FieldValueOutOfRangePostParse<T>(String text, int value, String field, String tType) =>
      ForInvalidValuePostParse(text, TextErrorMessages.FieldValueOutOfRange, [value, field, tType]);

  /// <summary>
  /// Two fields (e.g. "hour of day" and "hour of half day") were mutually inconsistent.
  /// </summary>
  @internal static ParseResult<T> InconsistentValues<T>(String text, String field1, String field2, String tType) =>
      ForInvalidValuePostParse(text, TextErrorMessages.InconsistentValues2, [field1, field2, tType]);

  /// <summary>
  /// The month of year is inconsistent between the text and numeric specifications.
  /// We can't use InconsistentValues for this as the pattern character is the same in both cases.
  /// </summary>
  @internal static ParseResult<T> InconsistentMonthValues<T>(String text) => ForInvalidValuePostParse(text, TextErrorMessages.InconsistentMonthTextValue);

  /// <summary>
  /// The day of month is inconsistent with the day of week value.
  /// We can't use InconsistentValues for this as the pattern character is the same in both cases.
  /// </summary>
  @internal static ParseResult<T> InconsistentDayOfWeekTextValue<T>(String text) =>
      ForInvalidValuePostParse(text, TextErrorMessages.InconsistentDayOfWeekTextValue);

  /// <summary>
  /// We'd expected to get to the end of the string now, but we haven't.
  /// </summary>
  @internal static ParseResult<T> ExpectedEndOfString<T>(ValueCursor cursor) => ForInvalidValue(cursor, TextErrorMessages.ExpectedEndOfString);

  @internal static ParseResult<T> YearOfEraOutOfRange<T>(String text, int value, Era era, CalendarSystem calendar) =>
      ForInvalidValuePostParse(text, TextErrorMessages.YearOfEraOutOfRange, [value, era.name, calendar.name]);

  @internal static ParseResult<T> MonthOutOfRange<T>(String text, int month, int year) =>
      ForInvalidValuePostParse(text, TextErrorMessages.MonthOutOfRange, [month, year]);

  @internal static ParseResult<T> IsoMonthOutOfRange<T>(String text, int month) =>
      ForInvalidValuePostParse(text, TextErrorMessages.IsoMonthOutOfRange, [month]);

  @internal static ParseResult<T> DayOfMonthOutOfRange<T>(String text, int day, int month, int year) =>
      ForInvalidValuePostParse(text, TextErrorMessages.DayOfMonthOutOfRange, [day, month, year]);

  @internal static ParseResult<T> DayOfMonthOutOfRangeNoYear<T>(String text, int day, int month) =>
      ForInvalidValuePostParse(text, TextErrorMessages.DayOfMonthOutOfRangeNoYear, [day, month]);

  @internal static ParseResult<T> InvalidOffset<T>(String text) => ForInvalidValuePostParse(text, TextErrorMessages.InvalidOffset);

  @internal static ParseResult<T> SkippedLocalTime<T>(String text) => ForInvalidValuePostParse(text, TextErrorMessages.SkippedLocalTime);

  @internal static ParseResult<T> AmbiguousLocalTime<T>(String text) => ForInvalidValuePostParse(text, TextErrorMessages.AmbiguousLocalTime);

// #endregion
}