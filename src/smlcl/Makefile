include ../Makefile.inc

.PHONY: all
all : smlcl

smlcl : smlcl.mlb smlcl.sml smlcl.sig
	make -C $(SIMPLECL)
	mlton -show-basis .tmpbasis -default-ann 'allowFFI true' -link-opt -lsimplecl -link-opt -L$(SIMPLECL) -cc-opt -I$(SIMPLECL) -cc-opt -I$(CUDA)/include/ smlcl.mlb smlcl.c
	cat .tmpbasis
	rm .tmpbasis

.PHONY: run
run :
	make -C test run

.PHONY: clean
clean :
	rm -f smlcl .tmpbasis
	make -C test clean
