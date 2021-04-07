# Changelog

## 0.9.16
- Update TZDB to 2020d.
- Fixed loading issues with web, flutter web, and flutter.

## 0.9.15
- :bug: fix related to #39

## 0.9.14
- Updated TZDB to 2020b.
- Merged PR's #35, #36, #37, and #39.

## 0.9.13
- Updated TZDB to 2020a.

## 0.9.12
- Made some changes because of Pana.

## 0.9.11
- Added Interval.overlaps;
- Made some changes because of Pana.

## 0.9.10
- Fixes for ddc.
- Updated TZDB to 2019b.

## 0.9.9
- Fix for issue #15. Updated TZDB to 2018i.

## 0.9.8
- Fix for issue #13. May investigate better solution in the future.

## 0.9.7
- Updated TZDB to 2018g.

## 0.9.6
- Merged #1 - Fix for when cultureId is null

## 0.9.5
- Many API changes.
- LocalTime is now backed by a Nanosecond based Time Instance.
- Additional tests added.
- Performance improvements.

## 0.9.4
- Many API changes.
- Fix for Dart 2.0.

## 0.9.1
- Continued the API normalization work; removed add*, minus* where it did not
 add any performance gains. `Time` `plus`\\`minus` --> `add`\\`subtract`, added an `abs` method.
- `LocalDateTime`\\`LocalDate`\\`LocalTime` added `periodUntil`\\`periodSince`, removed `difference`, made static
 method `difference` from `differenceBetween`
  - same with `OffsetDateTime` except `time` vs `period`

## 0.9.0
- Added a `LocalDate.today()`, `LocalDateTime.now()`, `LocalTime.timeOfToday()`
 constructors.
- Refined `Local*` api's to be more like `dart:core.DateTime`
  - Did the same with `Instant`, `ZonedDateTime`, `OffsetDateTime`, `Offset`, `Period`

## 0.8.5
- Constructor is now `LocalDateTime.localDateAtTime(LocalDate, LocalTime)`
- Formatted much API Documentation.
- Removed operator based dynamic dispatch from all `operator -` methods. Many times it makes sense to for example,
  subtract to do this, `end_date - start_date = delta_time` and to do this, `end_date - delta_time = start_date`
  but only makes sense for addition to do this, `start_date + delta_time = end_date`, you'd never do this,
  `start_date + end_date = delta_time` (doesn't really make sense) -- so, the `operator -` methods have been
  defaulted to do the same operation as the `operator +` methods. If Dart 3 gets compile time dispatch, these
  other methods will be re-enabled.

## 0.8.4
- Bugfix for Flutter.

## 0.8.3
- Removed all the `Period.from*` constructors, added a named constructor, constructor
`const Period({this.years: 0, this.months: 0, this.weeks: 0, this.days: 0,
this.hours: 0, this.minutes: 0, this.seconds: 0,
this.milliseconds: 0, this.microseconds: 0, this.nanoseconds: 0});` instead of `Period.fromYears(int years)`.
- Moved collection: "^1.14.10" to collection: "^1.14.6" in order to satisfy Flutter unit testing requirements.
  time_machine can not be unit tested directly in flutter because of a breaking change between
  matcher: ^0.12.2+1 and matcher: 0.12.3 with regards to `TypeMatcher` going from an abstract non-instanced class to a
  regular instanced class. See [flutter_test/pubspec.yaml](https://github.com/flutter/flutter/blob/master/packages/flutter_test/pubspecz.yaml).

## 0.8.2
- Instant constructors condensed: `Instant.utc`, `Instant`, `Instant.julianDate`, `Instant.dateTime`, `Instant.epochTime`
- Removed `from` from a lot of constructors, heavily redundant (well, maybe not so redundant with the loss of `new`)
- Added a `timeZone` override to TimeMachine.init() so you can supply a local `DateTimeZone` to Flutter if you something
  like `flutter_native_timezone` loaded as well.
- CalendarSystem cleaned up.

## 0.8.0
- Dart 2.0 ready to go. TimeMachine 0.7.1 was the last version that will work on Dart 1.24.3.
  - Added a lot of BigInt code, there is no going back now. Added `Time.canNanosecondsBeInteger`,
  `Time.fromBigIntNanoseconds()`, `Time.totalNanosecondsAsBigInt`
  - The Dart2JS example compiled sized dropped by about 11%.

## 0.7.1
- No more dart analysis errors on 1.24.3.
  - Refactored away the port-helper KeyValuePair and OutBox classes.
  - Fixed (or annotated) all unused variables, fields, elements, and imports issues.

## 0.7.0
- Updated `LocalDateTime.at()` to reflect the LocalTime constructor update.
  - note: renamed `LocalDateTime.at()` to `LocalDateTime()` and then renamed the original `LocalDateTime(LocalDate, LocalTime)` to
  `LocalDateTime.combine(LocalDate, LocalTime)`
- Added Badi, Coptic, Hebrew, Islamic, Persian, and UmAlQura calendars.
  - Tested sat on VM/JS.

## 0.6.0
- Removed the concept of `ticks` and replaced all the functions with `microseconds`;
  Rational: the only place `ticks` shows up as a concept is here `https://api.dartlang.org/stable/1.24.3/dart-core/Stopwatch/elapsedTicks.html`;
  `ticks` from .NET-land is 100 nanosecond unit of time; `ticks` from dart is based on a dynamic `frequency` number,
  on my machines it's 1 us in the browser and 1 ns in the vm.
- Simplified LocalTime constructors; now one generic + one that takes a `Time` sinceMidnight. (from 7 initial)
- Added microsecond/millisecond logic around `DateTime` conversions wrt `Platform`
- Cleaned up Offset - removed subsecond constructors, since Offset can't be subsecond, and made the fromSeconds constructor
  the default constructor.

## 0.5.0

- Major API Changes (Sorry!)
- Span (denotatively and connotatively wrong) to Time (to just connotatively wrong)
- text_patterns moved to time_machine_text_patterns from time_machine global (still thinking about what things should be not visible by default)

## 0.4.1

- Missed a logging reference (took it out).

## 0.4

- DartVM mirrors based unit tests can now be used to compute DartWeb non-mirrors based unit tests. All web-compatible
unit tests are now passing, and TimeMachine is safe for use when compiling via Dart2JS.

## 0.3

- Coalesced imports into a single import and all `@internal` functionality is now hidden.

## 0.2.2

- Fixed bug introduced in 0.2.1; (Conditional Imports are hard); `dart.library.js` seems to evaluate to false in DDC stable.
  Put back as `dart.library.html`.

## 0.2.1

- Fixed bug introduced in 0.2.0 causing TimeMachine.Initialize() to not fully await.

## 0.2.0

- No more specific imports for your platform. Flutter usage was streamlined significantly.

## 0.1.1

- Broke some things while making this work on many platforms. Fixed them (still need to do unit tests on js).

## 0.1.0

- Made some changes to try and less confuse Pana.

## 0.0.4

- Now works on Flutter, Web, and VM!

## 0.0.2

- Many things have been Dartified. Constructors consolidated, names are lowercased, @private usage heavily reduced.

## 0.0.1

- Initial version.
