module igi.random;

/**
 * Each PCG generator is available in four variants, based on how it applies
 * the additive constant for its underlying LCG; the variations are:
 *
 *     single stream   - all instances use the same fixed constant, thus
 *                       the RNG always somewhere in same sequence
 *     mcg             - adds zero, resulting in a single stream and reduced
 *                       period
 *     specific stream - the constant can be changed at any time, selecting
 *                       a different random sequence
 *     unique stream   - the constant is based on the memory address of the
 *                       object, thus every RNG has its own unique sequence
 *
 * This variation is provided though mixin classes which define a function
 * value called increment() that returns the nesessary additive constant.
 */

///
template defaultMultiplier(T) {
	static if (is(T == uint))
		enum defaultMultiplier = 747_796_405U;
	else static if (is(T == ulong)) 
		enum defaultMultiplier = 6_364_136_223_846_793_005UL;
}

///
template defaultIncrement(T) {
	static if (is(T == uint))
		enum defaultIncrement = 2_891_336_453U;
	else static if (is(T == ulong)) 
		enum defaultIncrement = 1_442_695_040_888_963_407UL;
}

/// Unique stream per RNG instance
mixin template UniqueStream(IType)
{
	public IType increment() { return cast(IType)(cast(size_t)&this | 1); }
}

/// No stream used for mcg
mixin template NoStream(IType)
{
	public enum IType increment = 0;
}

/// Single stream/sequence
mixin template OneSeqStream(IType)
{
	public enum IType increment = defaultIncrement!(IType);
}

/// Specific stream
mixin template SpecificStream(IType)
{
	private IType inc = defaultIncrement!(IType);

	public IType increment() const { return inc; }

	public IType stream() { return inc >> 1; }
	public void stream(IType specificSeq) { inc = specificSeq << 1 | 1; }
}

private enum isMcg(alias T) = __traits(compiles, { enum e = T.increment; }) && T.increment == 0;

/**
 * This is where it all comes together.  This struct joins together three
 * mixins which define
 *    - the LCG additive constant (the stream)
 *    - the LCG multiplier
 *    - the output function
 * 
 * in addition, we specify the type of the LCG state, and the result type,
 * and whether to use the pre-advance version of the state for the output
 * (increasing instruction-level parallelism) or the post-advance version
 * (reducing register pressure).
 */
private struct Engine(XType, IType,
						alias outputFunc,
						bool outputPrevious = true,
						alias streamMixin = OneSeqStream,
						IType multiplierValue = defaultMultiplier!IType)
{
	private IType state = cast(IType)0xcafef00dd15ea5e5UL;

	private static auto make(IType state = cast(IType)0xcafef00dd15ea5e5UL)
	{
		typeof(this) res;
		static if (isMcg!streamMixin) {
			res.state = state | 3U;
		} else {
			res.state = res.bump(state + res.increment);
		}
		return res;
	}

	mixin streamMixin!IType;
	private enum multiplier = multiplierValue;

	private IType bump(IType state) {
		return state * multiplier + increment;
	}

	static if (outputPrevious) {
		public XType opCall() {
			auto oldState = state;
			state = bump(state);
			return outputFunc(oldState);
		}
	} else {
		public XType opCall() {
			state = bump(state);
			return outputFunc(state);
		}
	}

	public XType opCall(XType upperBound) {
		immutable XType threshold = ((XType.max - XType.min) + 1 - upperBound) % upperBound;
		for (;;) {
			XType r = opCall() - XType.min;
			if (r >= threshold) return r % upperBound;
		}
	}
}

/*
 * OUTPUT FUNCTIONS.
 *
 * These are the core of the PCG generation scheme.  They specify how to
 * turn the base LCG's internal state into the output value of the final
 * generator.
 *
 * All of the classes have code that is written to allow it to be applied
 * at *arbitrary* bit sizes, although in practice they'll only be used at
 * standard sizes supported by C++.
 */

/**
 * XSH RR -- high xorshift, followed by a random rotate
 *
 * Fast. A good performer. Slightly better statistically than XSH RS.
 */
private XType xshRrMixin(XType, IType)(IType internal)
{
	enum bits = IType.sizeof * 8;
	enum xtypebits = XType.sizeof * 8;
	enum sparebits = bits - xtypebits;
	enum wantedopbits = xtypebits >= 128 ? 7
						: xtypebits >=  64 ? 6
						: xtypebits >=  32 ? 5
						: xtypebits >=  16 ? 4
						:                    3;
	enum opbits = sparebits >= wantedopbits ? wantedopbits : sparebits;
	enum amplifier = wantedopbits - opbits;
	enum mask = (1 << opbits) - 1;
	enum topspare = opbits;
	enum bottomspare = sparebits - topspare;
	enum xshift = (topspare + xtypebits)/2;
	immutable ubyte rot = opbits ? cast(ubyte)(internal >> (bits - opbits)) & mask : 0;
	immutable ubyte amprot = (rot << amplifier) & mask;
	internal ^= internal >> xshift;
	XType result = cast(XType)(internal >> bottomspare);
	import core.bitop: ror;
	result = ror(result, amprot);
	return result;
}

/**
 * XSH RS -- high xorshift, followed by a random shift
 *
 * Fast. A good performer.
 */
private XType xshRsMixin(XType, IType)(IType internal)
{
	enum bits = IType.sizeof * 8;
	enum xtypebits = XType.sizeof * 8;
	enum sparebits = bits - xtypebits;
	enum opbits = sparebits - 5 >= 64 ? 5
				: sparebits - 4 >= 32 ? 4
				: sparebits - 3 >= 16 ? 3
				: sparebits - 2 >= 4  ? 2
				: sparebits - 1 >= 1  ? 1
				:                     0;
	enum mask = (1 << opbits) - 1;
	enum maxrandshift = mask;
	enum topspare = opbits;
	enum bottomspare = sparebits - topspare;
	enum xshift = topspare + (xtypebits + maxrandshift) / 2;
	immutable ubyte rshift = opbits ? cast(ubyte)(internal >> (bits - opbits)) & mask : 0;
	internal ^= internal >> xshift;
	XType result = cast(XType)(internal >> (bottomspare - maxrandshift + rshift));
	return result;
}

private template setseqBase(XType, IType,
							alias outputMixin,
							bool outputPrevious = (IType.sizeof <= 8),
							IType multiplierMixin = defaultMultiplier!IType)
{
	alias setseqBase = Engine!(XType, IType,
								outputMixin!(XType, IType),
								outputPrevious,
								SpecificStream,
								multiplierMixin);
}
private alias setseqXshRr6432 = setseqBase!(uint, ulong, xshRrMixin);

private template oneseqBase(XType, IType,
							alias outputMixin,
							bool outputPrevious = (IType.sizeof <= 8),
							IType multiplierMixin = defaultMultiplier!IType)
{
	alias oneseqBase = Engine!(XType, IType,
								outputMixin!(XType, IType),
								outputPrevious,
								OneSeqStream,
								multiplierMixin);
}
private alias oneseqXshRr6432 = oneseqBase!(uint, ulong, xshRrMixin);

private template uniqueBase(XType, IType,
							alias outputMixin,
							bool outputPrevious = (IType.sizeof <= 8),
							IType multiplierMixin = defaultMultiplier!IType)
{
	alias uniqueBase = Engine!(XType, IType,
								outputMixin!(XType, IType),
								outputPrevious,
								UniqueStream,
								multiplierMixin);
}
private alias uniqueXshRr6432 = uniqueBase!(uint, ulong, xshRrMixin);

private template mcgBase(XType, IType,
							alias outputMixin,
							bool outputPrevious = (IType.sizeof <= 8),
							IType multiplierMixin = defaultMultiplier!IType)
{
	alias mcgBase = Engine!(XType, IType,
								outputMixin!(XType, IType),
								outputPrevious,
								NoStream,
								multiplierMixin);
}
private alias mcgXshRs6432 = mcgBase!(uint, ulong, xshRsMixin);

alias pcg32 = setseqXshRr6432.make;
alias pcg32Oneseq = oneseqXshRr6432.make;
alias pcg32Unique = uniqueXshRr6432.make;
alias pcg32Fast = mcgXshRs6432.make;
