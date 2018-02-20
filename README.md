# time_machine

Port of Nodatime.
It didn't start that way. I just wanted some TimeZone functionality -- but, I don't know how to stop.

0) Porting classes over.
0) Getting rid of all the red squiggles.
0) Implementing Unit Tests 
0) TSDB loading 
0) Dartify classes (they are very dotnetified atm)

Current Step == 0 & 1

Text/Globalization are not yet ported. I want to look into Intl to see what it provides. 
Calendar support is limited to the basics right now, but the goal is to add them all. 
TimeZone/IO (&Cldr) are not yet ported, the tzdb source will not be in the same format.
There is a C# project that converts the NodaTime db into deferrable pieces. The plan is to
load from there.
