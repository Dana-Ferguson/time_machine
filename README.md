# time_machine

Port of Nodatime.
It didn't start that way. I just wanted some TimeZone functionality -- but, I don't know how to stop.

1) (done) Porting classes over.
0) (done for non-CLDR features) Getting rid of all the red squiggles.
0) (in progress) Implementing Unit Tests
0) (TSDB done) TSDB\CLDR loading
0) Dartify classes (they are very dotnetified atm)
0) Remove @internal's before 1.0 (do not consider an @internal annotated field as a public API)

There is a C# project that converts the NodaTime db into pieces (not included in this repository).

I'm thinking that JS/VM specific functions will function via conditional imports, but will be VM by default for right now.

The goal is to get a fairly complete usable working prototype. CLDR and non-Gregorian/Julian calendar systems (see: lib/src/calendar_system.dart) are being
pushed back until all applicable unit tests are ported. I'm hoping to hit a release candidate about the time Dart 2 comes out (Jun 15th... or much later this year?).
