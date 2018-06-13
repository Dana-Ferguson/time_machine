# Dart Time Machine

Time Machine is a date and time API for Dart (port of [Noda Time](https://www.nodatime.org)).
Time Machine is timezone and culture sensitive. Intended targets are DartVM and Dart4Web.

A lot of functionality works at this time, but the public API is still changing a lot. TZDB needs
QoL changes that are coming, but are not here yet. This is a preview release. Documentation was also ported,
but some things changed for Dart and the documentation will have minor inaccuracies in some places.

Don't use any functions annotated with `@internal`. I don't intend to keep this annotation, but with
`part` \ `part of` [usage discouraged](https://www.dartlang.org/guides/libraries/create-library-packages#organizing-a-library-package)
and no [friend](https://github.com/dart-lang/sdk/issues/22841) semantics, I'm unsure of the direction to go with this. 

Todo:
 - [x] Port over major classes
 - [x] Port over corresponding unit tests
 - [ ] Dartification of the API
   - [X] First pass style updates
   - [ ] Second pass ergonomics updates
   - [ ] Synchronous TSDB timezone provider
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
 - [ ] Benchmarking & Optimizing Library for Dart

