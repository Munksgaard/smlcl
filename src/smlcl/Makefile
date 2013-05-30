include ../Makefile.inc

.PHONY: all
all : smlcl

smlcl : smlcl.mlb smlcl.sml smlcl.sig
	make -C $(SIMPLECL)
	make -C $(PRIMCL)
	mlton -show-basis .tmpbasis -default-ann 'allowFFI true' -link-opt -lsimplecl -link-opt -L$(SIMPLECL) -cc-opt -I$(SIMPLECL) -cc-opt -I$(CUDA)/include/ smlcl.mlb
	cat .tmpbasis
	rm .tmpbasis

.PHONY: test
test : all
	make -C test run

.PHONY: clean
clean :
	rm -f smlcl .tmpbasis
	make -C test clean
