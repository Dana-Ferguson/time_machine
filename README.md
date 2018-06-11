# Dart Time Machine

Time Machine is a date and time API for Dart (port of [Noda Time](nodatime.org)).
Time Machine is timezone and culture sensitive. Intended targets are DartVM and Dart4Web.

A lot of functionality works at this time, but the public API is still changing a lot. TZDB needs
QoL changes that are coming, but are not here yet. This is a preview release. Documentation was also ported,
but some things changed for Dart and the documentation will have minor inaccuracies in some places.

Todo:
 - [x] Port over major classes
 - [x] Port over corresponding unit tests
 - [ ] Dartification of the API
 - [ ] Non-Gregorian/Julian calendar systems
 - [X] Text formatting and Parsing
 - [X] Remove XML tags from documentation and format them for pub (*human second pass still needed*)
 - [ ] Implement Dart4Web features (default is VM right now)
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
 - [ ] Synchronous TSDB timezone provider (priority being raised - it really helps with ZonedDateTime parsing)
 - [ ] Benchmarking & Optimizing Library for Dart

