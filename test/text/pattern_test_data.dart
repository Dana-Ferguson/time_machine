// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'package:test/test.dart';
import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/text/globalization/time_machine_globalization.dart';
import 'package:time_machine/src/text/time_machine_text.dart';
import 'package:time_machine/src/utility/time_machine_utilities.dart';

/// Alternative to AbstractFormattingData for tests which deal with patterns directly. This does not
/// include properties which are irrelevant to the pattern tests but which are used by the BCL-style
/// formatting tests (e.g. thread culture).
abstract class PatternTestData<T> {
  @internal final T Value;

  /*final*/
  late T defaultTemplate;

  /// Culture of the pattern.
  @internal Culture culture = Culture.invariant;

  /// Standard pattern, expected to format/parse the same way as Pattern.
  @internal IPattern<T>? standardPattern;

  /// This lets the JS_Test_Gen know what to put. (This is a total cop-out ~ complexity level is too high)
  /// rational: there are 33 usages of StandardPattern, it's easier to annotate than spend a week creating the most beautiful reflection program
  @internal late String standardPatternCode;

  /// Pattern text.
  @internal String pattern = '***undefined pattern***';

  /// String value to be parsed, and expected result of formatting.
  @internal String text = '***undefined text***';


  /// Template value to specify in the pattern
  @internal late T template;

  /// Extra description for the test case
  @internal late String description;

  /// Message format to verify for exceptions.
  @internal String? message;

  /// Message parameters to verify for exceptions.
  @internal final List parameters = [];

  @internal PatternTestData(this.Value) {
    template = defaultTemplate;
  }

  @internal IPattern<T> CreatePattern();

  @internal void TestParse() {
    assert(message == null);
    IPattern<T> pattern = CreatePattern();
    var result = pattern.parse(text);
    var actualValue = result.value;
    expect(actualValue, Value);

    if (standardPattern != null) {
      assert(Value == standardPattern!
          .parse(text)
          .value);
    }
  }

  @internal void TestFormat() {
    assert(message == null);
    IPattern<T> pattern = CreatePattern();
    expect(pattern.format(Value), text);

    if (standardPattern != null) {
      expect(standardPattern!.format(Value), text);
    }
  }

  @internal void TestParsePartial() {
    var pattern = CreatePartialPattern();
    assert(message == null);
    var cursor = ValueCursor('^' + text + "#");
    // Move to the ^
    cursor.moveNext();
    // Move to the start of the text
    cursor.moveNext();
    var result = pattern.parsePartial(cursor);
    var actualValue = result.value;
    assert(Value == actualValue);
    assert('#' == cursor.current);
  }

  @internal /*virtual*/ IPartialPattern<T> CreatePartialPattern() {
    throw UnimplementedError();
  }

  @internal void TestAppendFormat() {
    assert(message == null);
    var pattern = CreatePattern();
    var builder = StringBuffer('x');
    pattern.appendFormat(Value, builder);
    // assert('x' + Text == builder.toString());
    expect(builder.toString(), 'x' + text );
  }

  @internal void TestInvalidPattern() {
    String expectedMessage = FormatMessage(message!, parameters);
    try {
      CreatePattern();
      // 'Expected InvalidPatternException'
      assert(false);
    }
    on InvalidPatternError catch (e) {
      // Expected... now let's check the message
      assert(expectedMessage == e.message, '$expectedMessage != ${e.message}');
    }
  }

  void TestParseFailure() {
    String expectedMessage = FormatMessage(message!, parameters);
    IPattern<T> pattern = CreatePattern();

    var result = pattern.parse(text);
    assert(result.success == false);
    try {
      result.getValueOrThrow();
      // 'Expected UnparsableValueException'
      assert(false);
    }
    on UnparsableValueError catch (e) {
      // Expected... now let's check the message *starts* with the right part.
      // We're not currently validating the bit that reproduces the bad value.
      assert(e.message.startsWith(expectedMessage),
      "Expected message to start with \n'$expectedMessage'; was actually \n'${e.message}'");
    }
  }

  @override String toString() {
    try {
      StringBuffer builder = StringBuffer();
      builder.write('Value=$Value; ');
      builder.write('Pattern=$pattern; ');
      builder.write('Text=$text; ');
      if (culture != Culture.invariant) {
        builder.write('Culture=$culture; ');
      }
      // if (!Template.Equals(DefaultTemplate)) {
      if (template != defaultTemplate) {
        builder.write('Template=$template;');
      }
      return builder.toString();
    }
    on Exception {
      return 'Formatting of test name failed';
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
      throw FormatException("Failed to format String '$message' with ${parameters.length} parameters");
    }
  }
}
