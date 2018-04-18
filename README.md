# time_machine

Port of Nodatime.
It didn't start that way. I just wanted some TimeZone functionality -- but, I don't know how to stop.

1) (done) Porting classes over.
0) (done for non-CLDR features) Getting rid of all the red squiggles.
0) (in progress) Implementing Unit Tests
0) (TSDB done) TSDB\CLDR loading
0) Dartify classes (they are very dotnetified atm)
0) Remove @internal's before 1.0 (do not consider an @internal annotated field as a public API)

I'm working more on #4 and since it leads to being able to do #2 and #3.

There is a C# project that converts the NodaTime db into pieces (not included in this repository).

I'm thinking that JS/VM specific functions will be VM by default, and I'm thinking we can use
transformers to use the JS specific versions so the import's will be consistent between projects.


