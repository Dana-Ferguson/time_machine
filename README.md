# Dart Time Machine

Time Machine is a date and time API for Dart (port of [Noda Time](https://www.nodatime.org)).
Time Machine is timezone and culture sensitive. Intended targets are DartVM, Dart4Web, and Flutter.

Example Code:

```dart
// Sets up timezone and culture information
await TimeMachine.initialize();
print('Hello, ${DateTimeZone.local} from the Dart Time Machine!');

var tzdb = await DateTimeZoneProviders.tzdb;
var paris = await tzdb["Europe/Paris"];

var now = SystemClock.instance.getCurrentInstant();

print('\nBasic');
print('UTC Time: $now');
print('Local Time: ${now.inLocalZone()}');
print('Paris Time: ${now.inZone(paris)}');

print('\nFormatted');
print('UTC Time: ${now.toString('dddd yyyy-MM-dd HH:mm')}');
print('Local Time: ${now.inLocalZone().toString('dddd yyyy-MM-dd HH:mm')}');

print('\nFormatted and French');
var culture = await Cultures.getCulture('fr-FR');
print('UTC Time: ${now.toString('dddd yyyy-MM-dd HH:mm', culture)}');
print('Local Time: ${
  now.inLocalZone().toString('dddd yyyy-MM-dd HH:mm', culture)}');

print('\nParse French Formatted DateTimeZone');
// without the 'z' parsing will be forced to interpret the timezone as UTC
var localText = now
    .inLocalZone()
    .toString('dddd yyyy-MM-dd HH:mm z', culture);

var localClone = ZonedDateTimePattern
    .createWithCulture('dddd yyyy-MM-dd HH:mm z', culture)
    .parse(localText);
print(localClone.value);
```

### VM

![selection_116](https://user-images.githubusercontent.com/7284858/41519375-bcbbc818-7295-11e8-9fd0-de2e8668b105.png)

### Flutter

![selection_117](https://user-images.githubusercontent.com/7284858/41519377-bebbde82-7295-11e8-8f10-d350afd1f746.png)

### Web

![selection_118](https://user-images.githubusercontent.com/7284858/41519378-c058d6a0-7295-11e8-845d-6782f1e7cbbe.png)

A lot of functionality works at this time, but the public API is starting to stabilize. TZDB QoL 
changes are in progress. This is a preview release. Documentation was also ported,
but some things changed for Dart and the documentation will have minor inaccuracies in some places (and we need
an additional formatting pass).

Don't use any functions annotated with `@internal`. As of v0.3 you should not find any, but if you do, let me know.

Todo:
 - [x] Port over major classes
 - [x] Port over corresponding unit tests
 - [ ] Dartification of the API
   - [X] First pass style updates
   - [X] Second pass ergonomics updates
   - [X] Synchronous TZDB timezone provider
   - [ ] Review all I/O and associated classes and their structure
 - [ ] Non-Gregorian/Julian calendar systems
 - [X] Text formatting and Parsing
 - [X] Remove XML tags from documentation and format them for pub (*human second pass still needed*)
 - [X] Implement Dart4Web features
 - [ ] Unit tests running in DartWeb (_for fidelity_: need a mirror-less version)
 - [ ] Create simple website with examples (at minimal a good set of examples under the examples directory)

External data: Timezones (TZDB via Noda Time) and Culture (ICU via BCL) are produced by a C# tool that is not included in this repository.

The unit testing framework uses reflection and won't work in Dart4Web 2.0 
or later; we'll cross this bridge later. Version 1.0 will not occur until after we get full unit testing in DDC and D2JS.
- [ ] That bridge has been crossed; a static non-mirror test-set can be produced from the dynamic mirror-ed test set,
 but Dart2JS fails on `Isolate.resolvePackageUri` -- and it's shouldn't. Action item = investigate. Verified the DDC test app
 after `pub build` will fail as well. This is sad.

Future Todo:
 - [ ] Produce our own TSDB files
 - [ ] Produce our own Culture files
 - [ ] Benchmarking & Optimizing Library for Dart

### Flutter Specific Notes

You'll need this entry in your pubspec.yaml.

```yaml
# The following section is specific to Flutter.
flutter:
  assets:
    - packages/time_machine/data/cultures/cultures.bin
    - packages/time_machine/data/tzdb/tzdb.bin
```

Your initialization function will look like this:
```dart
import 'package:flutter/services.dart';


await TimeMachine.initialize(rootBundle);
```

Once flutter gets [`Isolate.resolvePackageUri`](https://github.com/flutter/flutter/issues/14815) functionality,
we'll be able to merge VM and the Flutter code paths and no asset entry and no special import will be required.
It would look just like the VM example.

### DDC Specific Notes

```dart
class Foo {
  // Okay in Dart_VM 1.24 -- Okay in DartPad\Dart2JS
  // not Okay in DDC 1.24 -- Okay in DDC 2.0.0-dev63 (but no conditional imports? so TimeMachine doesn't work)
  @override String toString([int x = 0, int y = 0, int z = 0]) 
    => '${x + y+ x}';
}

void main() {
  var foo = new Foo();
  print(foo.toString());
  print(foo.toString(1, 2, 3));
}
```

Overriding `toString()` with optional arguments doesn't work in DDC. We use this technique to provide 
optional formatting. `Instant` and `ZonedDateTime` currently have `toStringDDC` functions available. 
Still investigating potential solutions, but looks like `waiting` might be an okay algorithm, since it works
in the newer DDC. I'm hoping Dart 2 stable launches [soon](https://github.com/dart-lang/sdk/issues?q=is%3Aopen+is%3Aissue+milestone%3ADart2Stable).

