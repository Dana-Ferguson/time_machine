# time_machine

Port of Nodatime.
It didn't start that way. I just wanted some TimeZone functionality -- but, I don't know how to stop.

1) (done) Porting classes over.
0) Getting rid of all the red squiggles.
0) Implementing Unit Tests 
0) TSDB\CLDR loading 
0) Dartify classes (they are very dotnetified atm)
0) Remove @internal's before 1.0 (do not consider an @internal annotated field as a public API)

Current Step == 2 & 3 & 4 (I'm an obelisk of focus... fear me)

I'm working more on #4 and since it leads to being able to do #2 and #3.

There is a C# project that converts the NodaTime db into deferrable pieces. 
I'm going to look into a `deferred` strategy for the browser platform - so 
we don't need to load the whole library at once (unsure if it matters -- 
tree shaking is the best).

Thinking that JS/VM function splits will be VM by default, but with transformers for the JS version
that swaps to compatible classes.


