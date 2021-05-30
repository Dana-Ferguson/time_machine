

class SkipMe {
  final String? reason;

  const SkipMe([this.reason]);
  const SkipMe.unimplemented() : reason = 'unimplemented';
  const SkipMe.parseIds() : reason = 'cannot parse dtz ids';
  const SkipMe.noCompareInfo() : reason = 'compare info is not ported';
  const SkipMe.text() : reason = 'text';
}

class Test {
  final String? name;
  const Test([this.name]);
}

class TestCase {
  final Iterable arguments;
  final String? description;

  const TestCase(this.arguments, [this.description]);
}

class TestCaseSource {
  // List of Lists (n-arguments), or just a List (single argument)
  final Symbol source;
  final String? description;

  const TestCaseSource(this.source, [this.description]);
}

class TestCaseData {
  String? name;
  Object arguments;
  TestCaseData(this.arguments);
}
