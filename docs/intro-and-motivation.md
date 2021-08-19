# DrIggy DLang Standard Library

## Motivation

I was always interested in how things work on low level, but since life is too short to learn
everything I first had to define low level at some reasonable limit. For example: how to write an
operating system or device driver, although equally interesting would take too much time and I am
not sure how beneficial the learning would be to me. On the other hand learning how existing
operating systems I work on the most: Linux and Windows function and how I can best use what they
offer seems like it will benefit me the most in my work. In order to learn that I still have to go
pretty low.

The idea I came up with is to write my own standard library. No matter what language you use it will
have some standard library: a set of functions and abstractions over the operating system that
provide you an easy way to do file input/output, memory manipulation, network communication, process
manipulation, threading etc. and usually also provide some very common data structures with ways to
manipulate them, like string, hashtable, list and similar. My standard library will, of course, be
far from those in terms of completness. They are also usually written in a very general maner since
they have to fulfill every possible request a dev might have on a lot of different platforms. The
one I would work on would only contain things I personally find useful. For example there is no
platform I am interested in that uses big endian processor so I don't have to waste time writing
algorithms so they work in both low endian and big endian environment.

Another thing I always wanted to get better at is diving into open source projects and being able to
understand them and if needed contribute to them and the third thing I am currently interested in is
learning more about DLang. If you want to see why I find DLang the most interesting language look at
my [Intro to D](https://www.youtube.com/watch?v=OzASFrPzil4&list=PLNiswfy6ptAnw_QmqAuy-Bz02oeu4pnLL)
video.

Anyway, to combine all this I decided to write my standard library in DLang. For each part that I
want to implement I will look at how D standard library does it but also how other open source
solutions do it in other languages (but lets be realistic, it will in most cases be C or C++). I
would have to understand enough of it to be able to port it to D, clean it up for my needs, probably
modify it a bit to be more in spirit of D. Through this process I would have to learn a bit, at
least, of all those three things I want which is the reason this idea got me so exited.