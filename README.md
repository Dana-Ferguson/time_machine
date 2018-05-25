# time_machine

Port of Noda Time. Intended targets are DartVM and Dart4Web.
It didn't start that way. I just wanted some TimeZone functionality -- but, I don't know how to stop.

The majority of the classes and unit tests are ported over (and passing!).

Todo:
[ ] Dartification of the API.
[ ] Non-Gregorian/Julian calendar systems.
[ ] Text formatting and Parsing (CLDR or CultureInfo?)

I'm hoping to hit a release candidate about the time Dart 2 comes out (Jun 15th... or much later this year?).

There is a C# project that converts the Noda Time's tzdb into pieces (not included in this repository).
After this project is stable, the goal is to continually port changes from Noda Time over to Time Machine (as language features support and use cases make sense).
As a longer term goal, the plan is to benchmark and optimize the library for Dart.

I'm thinking that JS/VM specific functions will function via conditional imports, but will be VM by default for right now. (*fingers crossed* that this makes it into Dart 2?)
