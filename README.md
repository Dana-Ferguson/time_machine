# Dart Time Machine

Time Machine is a date and time library for
[Flutter](https://flutter.io/), [Web](https://webdev.dartlang.org/), and [Server](https://www.dartlang.org/dart-vm)
with support for timezones, calendars, cultures, formatting and parsing.

Time Machine is a port of [Noda Time](https://www.nodatime.org); use it for all your .NET needs.

### Ready for [Dart 2](https://github.com/dart-lang/sdk/issues?q=is%3Aopen+is%3Aissue+milestone%3ADart2Stable) 

If you are using TimeMachine for Dart 1.24.3, you'll want to depend directly on `0.7.1` or earlier.

```yaml
dependencies:
  time_machine: "0.7.1"
```

### Example Code:

```dart
// Sets up timezone and culture information
await TimeMachine.initialize();
print('Hello, ${DateTimeZone.local} from the Dart Time Machine!\n');

var tzdb = await DateTimeZoneProviders.tzdb;
var paris = await tzdb["Europe/Paris"];

var now = Instant.now();

print('Basic');
print('UTC Time: $now');
print('Local Time: ${now.inLocalZone()}');
print('Paris Time: ${now.inZone(paris)}\n');

print('Formatted');
print('UTC Time: ${now.toString('dddd yyyy-MM-dd HH:mm')}');
print('Local Time: ${now.inLocalZone().toString('dddd yyyy-MM-dd HH:mm')}\n');

print('Formatted and French');
var culture = await Cultures.getCulture('fr-FR');
print('UTC Time: ${now.toString('dddd yyyy-MM-dd HH:mm', culture)}');
print('Local Time: ${
  now.inLocalZone().toString('dddd yyyy-MM-dd HH:mm', culture)}\n');

print('Parse French Formatted DateTimeZone');
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

### Web (Dart2JS and DDC)

![selection_118](https://user-images.githubusercontent.com/7284858/41519378-c058d6a0-7295-11e8-845d-6782f1e7cbbe.png)

All unit tests pass on DartVM and DartWeb (just _Chrome_ at this time).
Tests have been run on preview versions of Dart2,
but the focus is on DartStable, and they are not run before every pub publish.
The public API is stabilizing -- mostly focusing on taking C# idiomatic code
and making it Dart idiomatic code, so I wouldn't expect any over zealous changes.
This is a preview release -- but, I'd feel comfortable using it. (_Author Stamp of Approval!_)

Documentation was ported, but some things changed for Dart and the documentation is being slowly updated (and we need
an additional automated formatting pass).

Don't use any functions annotated with `@internal`. As of v0.3 you should not find any, but if you do, let me know.

Todo (before v1):
 - [x] Port Noda Time
 - [x] Unit tests passing in DartVM
 - [ ] Dartification of the API
   - [X] First pass style updates
   - [X] Second pass ergonomics updates
   - [X] Synchronous TZDB timezone provider
   - [ ] Review all I/O and associated classes and their structure
   - [ ] Simplify the API and make the best use of named constructors
 - [X] Non-Gregorian/Julian calendar systems
 - [X] Text formatting and Parsing
 - [X] Remove XML tags from documentation and format them for pub (*human second pass still needed*)
 - [X] Implement Dart4Web features
 - [X] Unit tests passing in DartWeb
 - [ ] Fix DartDoc Formatting
 - [ ] Create simple website with examples (at minimal a good set of examples under the examples directory)

External data: Timezones (TZDB via Noda Time) and Culture (ICU via BCL) are produced by a C# tool that is not 
included in this repository. The goal is to port all this functionality to Dart, the initial tool was created for
bootstrapping -- and guaranteeing that our data is exactly the same thing that Noda Time would see (to ease porting).

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

// you can get Timezone information directly from the native interface or TimeMachine will heuristically
// figure out the Timezone for you if you don't supply it with a timezone (native interface = cheaper)
// see: https://pub.dartlang.org/packages/flutter_native_timezone
await TimeMachine.initialize({rootBundle: rootBundle, timeZone: await Timezone.getLocalTimezone()});
```

Once flutter gets [`Isolate.resolvePackageUri`](https://github.com/flutter/flutter/issues/14815) functionality,
we'll be able to merge VM and the Flutter code paths and no asset entry and no special import will be required.
It would look just like the VM example.

### DDC Specific Notes

**Research in progress**: We don't get a compiler error in DDC 2 (like we do in DDC 1.24.3), but it erases the arguments.
I've been unable to build a minimal test case for this behavior (other than a large library in aggregate).

```js
// Instant.toString() via step through debugger
dart.toString = function(obj) {
  if (obj == null) return "null";
  if (typeof obj == 'string') return obj;
  return obj[$toString](); // <--- HERE. Y U Do Dis, DDC?
};

// this is what it looks like for Foo.toString();
dart.notNull = function(x) {
    if (x == null) dart.throwNullValueError();
    return x;
```

This outputs the correct behavior in DDC. But, TimeMachine.toString([]) overloads, do not.

```dart
class Foo {
  // Okay in Dart_VM 1.24 -- Okay in DartPad\Dart2JS
  // not Okay in DDC 1.24 -- Okay in DDC 2.0.0-dev67
  @override String toString([int x = 0, int y = 0, int z = 0]) 
    => '${x + y+ x}';
}

void main() {
  var foo = new Foo();
  print(foo.toString());
  print(foo.toString(1, 2, 3));
}
```

`Instant` and `ZonedDateTime` currently have `toStringDDC` functions available. 

`toStringDDC` instead of `toStringFormatted` to attempt to get a negative 
[contagion](https://engineering.riotgames.com/news/taxonomy-tech-debt) coefficient. If you are writing on DartStable today 
and you need some extra string support because of this bug, let me know.
