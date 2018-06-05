# time_machine

Time Machine is a date and time API for Dart (port of Noda Time). Time Machine is timezone and culture sensitive. Intended targets are DartVM and Dart4Web.

The majority of the classes and unit tests are ported over (and passing!).

Todo:
 - [x] Port over major classes
 - [x] Port over corresponding unit tests
 - [ ] Dartification of the API
 - [ ] Non-Gregorian/Julian calendar systems
 - [X] Text formatting and Parsing
 - [ ] Remove XML tags from documentation and format them for pub
 - [ ] Implement Dart4Web features (default is VM right now)
 - [ ] *maybe*: Create simple website with samples (at minimal a samples directory in github)

I'm hoping to hit a release candidate about the time Dart 2 comes out (Jun 15th... or much later this year?).

External data: Timezones (TZDB via Noda Time) and Culture (ICU via BCL) are produced by a C# tool that is not included in this repository.
Future goals include, benchmarking and optimizing the library for Dart.

I'm thinking that JS/VM specific functions will function via conditional imports, but will be VM by default for right now. (*fingers crossed* that this makes it into Dart 2?) The unit testing framework uses reflection and won't work in Dart4Web 2.0 or later; we'll cross this bridge later.

Future Todo:
 - [ ] Produce our own TSDB files
 - [ ] Produce our own Culture files
 - [ ] Synchronous TSDB timezone provider
