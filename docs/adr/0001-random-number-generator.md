# 1. Random number generator

Date: 2021-08-19

## Status

Status: Accepted on 2021-08-19  


## Context

Phobos implements Mersenne Twister and XorShift random number generators. The first one needs a lot of memory for such an easy task and the second one isn't statistically that good. What is good is that they are using a [Range](http://ddili.org/ders/d.en/ranges.html) interface.

## Decision

The best RNG algorithm we found is [PCG](https://www.pcg-random.org). We will port that algorithm, without extensions, and structure it to also work as a Range. We will also add helpers for generating 64bit integers and floats and doubles from the 32bit generators.

## Consequences

We will have the state of the art RNG that is fast and compact.
