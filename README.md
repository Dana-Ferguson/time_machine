![logo-dtm](https://user-images.githubusercontent.com/7284858/43960873-65f3f080-9c81-11e8-9d4d-c34c7e4cc46c.png)

The Dart Time Machine is a date and time library for
[Flutter](https://flutter.io/), [Web](https://webdev.dartlang.org/), and [Server](https://www.dartlang.org/dart-vm)
with support for timezones, calendars, cultures, formatting and parsing.

Time Machine provides an alternative date and time API over Dart Core.
For comparision:

**Dart Core API**
* Duration - an amount of time with microsecond precision
* DateTime - a unique point on the utc_timeline or a point in localtime with microsecond or millisecond precision

**Time Machine API**
* Time - an amount of time with nanosecond precision
* Instant - a unique point on the utc_timeline
* LocalTime - the time on the clock
* LocalDate - the date on the calendar
* LocalDateTime - a location on the clock and calendar
* Period - amount of time on the clock and calendar
* Offset - the timezone offset from the utc_timeline
* DateTimeZone - a mapping between the utc_timeline, and clock and calendar locations
* ZonedDateTime - a unique point on the utc_timeline and a location on the clock and calendar
* Culture - formatting and parsing rules specific to a locale

**Time Machine's Goals**
* Flexibility - multiple representations of time to fit different use cases
* Consistency - works the same across all platforms
* Testable - easy to test your date and time dependent code
* Clarity - clear, concise, and intuitive
* Easy - the library should do the hard things for you

The last two/three? are generic library goals.

Time Machine is a port of [Noda Time](https://www.nodatime.org); use it for all your .NET needs.

Current TZDB Version: 2020d

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

var french = await Cultures.getCulture('fr-FR');
print('Formatted and French ($french)');
print('UTC Time: ${now.toString('dddd yyyy-MM-dd HH:mm', french)}');
print('Local Time: ${now.inLocalZone().toString('dddd yyyy-MM-dd HH:mm', french)}\n');

print('Parse French Formatted ZonedDateTime');

// without the 'z' parsing will be forced to interpret the timezone as UTC
var localText = now
    .inLocalZone()
    .toString('dddd yyyy-MM-dd HH:mm z', french);

var localClone = ZonedDateTimePattern
    .createWithCulture('dddd yyyy-MM-dd HH:mm z', french)
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

// TimeMachine discovers your TimeZone heuristically (it's actually pretty fast).
await TimeMachine.initialize({'rootBundle': rootBundle});
```

Once flutter gets [`Isolate.resolvePackageUri`](https://github.com/flutter/flutter/issues/14815) functionality,
we'll be able to merge VM and the Flutter code paths and no asset entry and no special import will be required.
It would look just like the VM example.

Or with: https://pub.dartlang.org/packages/flutter_native_timezone

```dart
import 'package:flutter/services.dart';

// you can get Timezone information directly from the native interface with flutter_native_timezone
await TimeMachine.initialize({
  'rootBundle': rootBundle,
  'timeZone': await Timezone.getLocalTimezone(),
});
```

### DDC Specific Notes

`toString` on many of the classes will not propagate `patternText` and `culture` parameters.
`Instant` and `ZonedDateTime` currently have `toStringDDC` functions available to remedy this.

This also works:

```dart
dynamic foo = new Foo();
var foo = new Foo() as dynamic;
(foo as dynamic).toString(patternText, culture);
```

We learned in [Issue:33876](https://github.com/dart-lang/sdk/issues/33876) that `dynamic` code uses a different flow path.
Wrapping your code as dynamic will allow `toString()` to work normally. It will unfortunately ruin your intellisense.

See [Issue:33876](https://github.com/dart-lang/sdk/issues/33876) for more information. The [fix](https://dart-review.googlesource.com/c/sdk/+/65282)
exists, now we just wait for it to hit a live build.

`toStringDDC` instead of `toStringFormatted` to attempt to get a negative
[contagion](https://engineering.riotgames.com/news/taxonomy-tech-debt) coefficient. If you are writing on DartStable today
and you need some extra string support because of this bug, let me know.

_Update_: Dart 2.0 stable did not launch with the fix. Stable release windows are 6 weeks.
Hopefully we get the fix in the next release (second half of September).
