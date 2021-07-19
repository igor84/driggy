import core.bitop;
import core.stdc.stdio;
import igi.random;
import core.math: ldexp;

extern(C)
void main()
{
	auto rng1 = pcg32();
	auto rng2 = pcg32Oneseq();
	auto rng3 = pcg32Unique();
	auto rng4 = pcg32Fast();

	for (auto i = 0; i < 10; i++)
	{
		auto r1 = rng1();
		auto r2 = rng2();
		auto r3 = rng3();
		auto r4 = rng4();
		printf("Res: %u %u %u %u\n", r1, r2, r3, r4);
	}
}
