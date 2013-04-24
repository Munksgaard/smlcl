.PHONY: all
all : test

test : test.cl test.sml simplecl.c
	mlton -link-opt -lsimplecl -link-opt -L.. -cc-opt -I.. -cc-opt -I/home/pmunksgaard/.local/cuda-5.0/include/ test.mlb simplecl.c

run : test
	LD_LIBRARY_PATH=..:$LD_LIBRARY_PATH ./test

clean :
	rm test
