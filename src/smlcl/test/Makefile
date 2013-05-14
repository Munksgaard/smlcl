include ../../Makefile.inc

.PHONY: all
all : test

test : vectoradd.cl test.sml
	make -C $(SIMPLECL)
	make -C $(SMLCL)
	mlton -link-opt -lsimplecl -link-opt -L$(SIMPLECL) -cc-opt -I$(SIMPLECL) -cc-opt -I$(CUDA)/include/ test.mlb $(SMLCL)/smlcl.c

.PHONY: run
run : test
	LD_LIBRARY_PATH=$(SIMPLECL):$LD_LIBRARY_PATH ./test

.PHONY: clean
clean :
	rm -f test
