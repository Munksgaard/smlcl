include ../Makefile.inc

.PHONY: all
all : primcl

primcl : primcl.mlb primcl.sml primcl.sig
	make -C $(SIMPLECL)
	mlton -show-basis .tmpbasis -link-opt -lsimplecl -link-opt -L$(SIMPLECL) -cc-opt -I$(SIMPLECL) -cc-opt -I$(CUDA)/include/ primcl.mlb primcl.c
	cat .tmpbasis
	rm .tmpbasis

.PHONY: test
test : primcl
	make -C test run

.PHONY: clean
clean :
	rm -f primcl .tmpbasis
	make -C test clean
