# time_machine

Port of Nodatime.
It didn't start that way. I just wanted some TimeZone functionality -- but, I don't know how to stop.

Main classes are ported over. Unit Tests are currently being ported over. To follow is the Dartification of the API.
At this point I'd consider this a usable library. CLDR and non-Gregorian/Julian calendar systems will be written/ported last.
I'm hoping to hit a release candidate about the time Dart 2 comes out (Jun 15th... or much later this year?).

There is a C# project that converts the NodaTime db into pieces (not included in this repository).

I'm thinking that JS/VM specific functions will function via conditional imports, but will be VM by default for right now. (*fingers crossed* that this makes it into Dart 2?)
