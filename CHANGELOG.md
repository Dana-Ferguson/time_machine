# Changelog

## 0.6.1
- Updated `LocalDateTime.at()` to reflect the LocalTime constructor update.
  - note: I don't like `.at()`, anyone got a better constructor name idea?
- Added Badi, Coptic, Hebrew, Islamic, Persian, and UmAlQura calendars.

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
