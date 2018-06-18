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
but some things changed for Dart and the documentation will have minor inaccuracies in some places.

Don't use any functions annotated with `@internal`. I don't intend to keep this annotation, but with
`part` \ `part of` [usage discouraged](https://www.dartlang.org/guides/libraries/create-library-packages#organizing-a-library-package)
and no [friend](https://github.com/dart-lang/sdk/issues/22841) semantics, I'm unsure of the direction to go with this.
 - [ ] Prototype an automated tool to produce public interface files?

Todo:
 - [x] Port over major classes
 - [x] Port over corresponding unit tests
 - [ ] Dartification of the API
   - [X] First pass style updates
   - [X] Second pass ergonomics updates
   - [ ] Synchronous TZDB timezone provider
 - [ ] Non-Gregorian/Julian calendar systems
 - [X] Text formatting and Parsing
 - [X] Remove XML tags from documentation and format them for pub (*human second pass still needed*)
 - [X] Implement Dart4Web features
 - [ ] *maybe*: Create simple website with samples (at minimal a samples directory in github)

External data: Timezones (TZDB via Noda Time) and Culture (ICU via BCL) are produced by a C# tool that is not included in this repository.

I'm hoping that JS/VM specific functions will work via conditional imports. For testing atm, VM is default, but full JS
support is planned. 
([*fingers crossed*](https://github.com/dart-lang/sdk/issues/24581) that this makes it into Dart 2)

The unit testing framework uses reflection and won't work in Dart4Web 2.0 
or later; we'll cross this bridge later.

Future Todo:
 - [ ] Produce our own TSDB files
 - [ ] Produce our own Culture files
 - [ ] Benchmarking & Optimizing Library for Dart

