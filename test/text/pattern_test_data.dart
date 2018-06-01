import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_globalization.dart';
import 'package:time_machine/time_machine_text.dart';
import 'package:time_machine/time_machine_utilities.dart';

/// <summary>
/// Alternative to AbstractFormattingData for tests which deal with patterns directly. This does not
/// include properties which are irrelevant to the pattern tests but which are used by the BCL-style
/// formatting tests (e.g. thread culture).
/// </summary>
abstract class PatternTestData<T> {
  @internal final T Value;

  /*final*/
  T DefaultTemplate;

  /// <summary>
  /// Culture of the pattern.
  /// </summary>
  @internal CultureInfo Culture = CultureInfo.invariantCulture;

  /// <summary>
  /// Standard pattern, expected to format/parse the same way as Pattern.
  /// </summary>
  @internal IPattern<T> StandardPattern;

  /// <summary>
  /// Pattern text.
  /// </summary>
  @internal String Pattern;

  /// <summary>
  /// String value to be parsed, and expected result of formatting.
  /// </summary>
  @internal String Text;

  /// <summary>
  /// Template value to specify in the pattern
  /// </summary>
  @internal T Template;

  /// <summary>
  /// Extra description for the test case
  /// </summary>
  @internal String Description;

  /// <summary>
  /// Message format to verify for exceptions.
  /// </summary>
  @internal String Message;

  /// <summary>
  /// Message parameters to verify for exceptions.
  /// </summary>
  @internal final List Parameters = new List();

  @internal PatternTestData(this.Value) {
    Template = DefaultTemplate;
  }

  @internal IPattern<T> CreatePattern();

  @internal void TestParse() {
    assert(Message == null);
    IPattern<T> pattern = CreatePattern();
    var result = pattern.Parse(Text);
    var actualValue = result.Value;
    assert(Value == actualValue);

    if (StandardPattern != null) {
      assert(Value == StandardPattern
          .Parse(Text)
          .Value);
    }
  }

  @internal void TestFormat() {
    assert(Message == null);
    IPattern<T> pattern = CreatePattern();
    assert(Text == pattern.Format(Value));

    if (StandardPattern != null) {
      assert(Text == StandardPattern.Format(Value));
    }
  }

  @internal void TestParsePartial() {
    var pattern = CreatePartialPattern();
    assert(Message == null);
    var cursor = new ValueCursor("^" + Text + "#");
    // Move to the ^
    cursor.MoveNext();
    // Move to the start of the text
    cursor.MoveNext();
    var result = pattern.ParsePartial(cursor);
    var actualValue = result.Value;
    assert(Value == actualValue);
    assert('#' == cursor.Current);
  }

  @internal /*virtual*/ IPartialPattern<T> CreatePartialPattern() {
    throw new UnimplementedError();
  }

  @internal void TestAppendFormat() {
    assert(Message == null);
    var pattern = CreatePattern();
    var builder = new StringBuffer("x");
    pattern.AppendFormat(Value, builder);
    assert("x" + Text == builder.toString());
  }

  @internal void TestInvalidPattern() {
    String expectedMessage = FormatMessage(Message, Parameters);
    try {
      CreatePattern();
      // "Expected InvalidPatternException"
      assert(false);
    }
    on InvalidPatternError catch (e) {
      // Expected... now let's check the message
      assert(expectedMessage == e.message);
    }
  }

  void TestParseFailure() {
    String expectedMessage = FormatMessage(Message, Parameters);
    IPattern<T> pattern = CreatePattern();
    var result = pattern.Parse(Text);
    assert(result.Success == false);
    try {
      result.GetValueOrThrow();
      // "Expected UnparsableValueException"
      assert(false);
    }
    on UnparsableValueError catch (e) {
      // Expected... now let's check the message *starts* with the right part.
      // We're not currently validating the bit that reproduces the bad value.
      assert(e.message.startsWith(expectedMessage),
      "Expected message to start with \n'${expectedMessage}'; was actually \n'${e.message}'");
    }
  }

  @override String toString() {
    try {
      StringBuffer builder = new StringBuffer();
      builder.write("Value=$Value; ");
      builder.write("Pattern=$Pattern; ");
      builder.write("Text=$Text; ");
      if (Culture != CultureInfo.invariantCulture) {
        builder.write("Culture=$Culture; ");
      }
      if (Description != null) {
        builder.write("Description=$Description; ");
      }
      // if (!Template.Equals(DefaultTemplate)) {
      if (Template != DefaultTemplate) {
        builder.write("Template=$Template;");
      }
      return builder.toString();
    }
    catch (Exception) {
      return "Formatting of test name failed";
    }
  }

  /// <summary>
  /// Formats a message, giving a *useful* error message on failure. It can be a pain checking exactly what
  /// the message format is when writing tests...
  /// </summary>
  @private static String FormatMessage(String message, List parameters) {
    try {
      return stringFormat(message, parameters);
    }
    on FormatException // catch ()
        {
      throw new FormatException("Failed to format String '${message}' with ${parameters.length} parameters");
    }
  }
}