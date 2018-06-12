// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'package:test/test.dart';
import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_globalization.dart';
import 'package:time_machine/time_machine_text.dart';
import 'package:time_machine/time_machine_utilities.dart';

/// Alternative to AbstractFormattingData for tests which deal with patterns directly. This does not
/// include properties which are irrelevant to the pattern tests but which are used by the BCL-style
/// formatting tests (e.g. thread culture).
abstract class PatternTestData<T> {
  @internal final T Value;

  /*final*/
  T DefaultTemplate;

  /// Culture of the pattern.
  @internal CultureInfo Culture = CultureInfo.invariantCulture;

  /// Standard pattern, expected to format/parse the same way as Pattern.
  @internal IPattern<T> StandardPattern;

  /// Pattern text.
  @internal String Pattern;

  /// String value to be parsed, and expected result of formatting.
  @internal String Text;

  /// Template value to specify in the pattern
  @internal T Template;

  /// Extra description for the test case
  @internal String Description;

  /// Message format to verify for exceptions.
  @internal String Message;

  /// Message parameters to verify for exceptions.
  @internal final List Parameters = new List();

  @internal PatternTestData(this.Value) {
    Template = DefaultTemplate;
  }

  @internal IPattern<T> CreatePattern();

  @internal void TestParse() {
    assert(Message == null);
    IPattern<T> pattern = CreatePattern();
    var result = pattern.parse(Text);
    var actualValue = result.Value;
    expect(actualValue, Value);

    if (StandardPattern != null) {
      assert(Value == StandardPattern
          .parse(Text)
          .Value);
    }
  }

  @internal void TestFormat() {
    assert(Message == null);
    IPattern<T> pattern = CreatePattern();
    expect(pattern.format(Value), Text);

    if (StandardPattern != null) {
      expect(StandardPattern.format(Value), Text);
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
    var result = pattern.parsePartial(cursor);
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
    pattern.appendFormat(Value, builder);
    // assert("x" + Text == builder.toString());
    expect(builder.toString(), "x" + Text );
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

    var result = pattern.parse(Text);
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

  /// Formats a message, giving a *useful* error message on failure. It can be a pain checking exactly what
  /// the message format is when writing tests...
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
