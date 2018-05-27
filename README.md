# time_machine

Time Machine is a date and time API for Dart (port of Noda Time).  Intended targets are DartVM and Dart4Web.

The majority of the classes and unit tests are ported over (and passing!).

Todo:
 - [x] Port over major classes
 - [x] Port over corresponding unit tests
 - [ ] Dartification of the API
 - [ ] Non-Gregorian/Julian calendar systems
 - [ ] Text formatting and Parsing (CLDR or CultureInfo?)
 - [ ] Remove XML tags from documentation and format them for pub
 - [ ] *maybe*: Create simple website with samples (at minimal a samples directory in github)

I'm hoping to hit a release candidate about the time Dart 2 comes out (Jun 15th... or much later this year?).

There is a C# project that converts the Noda Time's tzdb into pieces (not included in this repository).
After this project is stable, the goal is to continually port changes from Noda Time over to Time Machine (as language features support and use cases make sense).
As a longer term goal, the plan is to benchmark and optimize the library for Dart.

I'm thinking that JS/VM specific functions will function via conditional imports, but will be VM by default for right now. (*fingers crossed* that this makes it into Dart 2?) The unit testing framework uses reflection and won't work in Dart4Web 2.0 or later; we'll cross this bridge later.
