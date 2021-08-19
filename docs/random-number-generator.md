# Random Number Generator

If you are anything like me you probably used these in whatever languages you worked with and took
it for granted. Any programming language you can think of today has a facility that provides you
with a random number generator and I thought this is a problem that was solved a long time ago and
it will be just a matter of learning that solution. So I was surprised to learn people are comming
up with new algorithms even today and are also comming up with better tests that verify how good are
these algorithms statistically. Then there are new issues branching from those solutions, like how
to provide uniform distribution with arbitrary boundaries if you have algorithms that output 32
random bits, or produce a random floating point number from that. The best resource on this topic I
found is the [pcg-random.org](https://www.pcg-random.org) website. It gives an overview of different
algorithms, provides what they think is the best solution with implementations in C and C++, it has
a video lecture about the history of it all and fantastic blog posts.

## DLang std.random

Phobos offers us a few RNG algorithms in its std.random package. We have Linear Congruential,
Mersenne Twister and XorShift engines. Important to note is that all engines are implemented as
structs that keep some state needed for their work and all of them have methods `empty`, `front` and
`popfront`. It means that each can be used as an
[InputRange](http://ddili.org/ders/d.en/ranges.html), a very important and useful concept in DLang.
They also have a save method which actully makes them a ForwardRange, which is an Input Range that
can also make a copy of its current state. This is definitely the interface I want to keep for my
implementation. The default engine is Mt19937 which is the most known Mersenne Twister variant. Its
documentation says this is the recommended generator unless *memory is severly restricted*. Seems
like a strange limit for something that just needs to generate 32 random bits. If we
[research](https://en.wikipedia.org/wiki/Mersenne_Twister) about it a bit we can find that it is
used in many languages, libraries and programs but that its flaws are a huge state of 2.5KiB, not so
good throughtput and it actually doesn't pass some of the statistical tests. Surely there is
something better.

## PCG Algorithm

So if we research what else is
[available](https://en.wikipedia.org/wiki/List_of_random_number_generators) we can discover the
already mentioned [PCG](https://www.pcg-random.org) algorithm. It passes all the known tests, it is
much simpler and faster than MT and it is also open source. It comes in three versions. There is a
minimal C library, a complete C++ library and a complete C library that is just automatically
generated from C++ version. It seems like all I need is in minimal lib but when I saw that C++
version is implemented with heavy use of templates I wanted to try and port a part of it to D in
order to learn more about D templates, although I'll probably simplify a lot of it at the end. The
original has implementation for generating 32bit but also 64bit random numbers. Unfortunately for
the later 128bit math is needed and in case the language doesn't support that you need to manually
simulate it so I decided 32bit version is good enough. Reading the C++ lib documentation I conclude
there are four generator variations that I am interested in:

- pcg32
- pcg32Oneseq
- pcg32Unique
- pcg32Fast

So what is the difference between them. You could say that the state of PCG generator is split into
two numbers. One number that tells you what stream of random numbers are you using and the other
number that tells you which number in the stream is next. The first generator lets you tell it both
numbers as its seed value. The second one has a hard coded stream so the actual state that needs to
be kept is halved. The third one also keeps only half the state but gives you a unique stream for
each instance of the RNG and it does that by using the address of that instance as a stream number
which in most modern environments will also be different each time you run the program. The last one
is the same as second one but uses a bit simpler operations so it is faster but a bit less
statistically good.

Here I directly ported the functionality of those 4 generators with the idea to later clean it up
and make it more D like.