include ../../Makefile.inc

.PHONY: all
all : pi

pi: pi.mlb pi.sml ../utils/utils.sml
	mlton -link-opt -lsimplecl -link-opt -L$(SIMPLECL) -cc-opt -I$(SIMPLECL) -cc-opt -I$(CUDA)/include/ pi.mlb $(PRIMCL)/primcl.c

.PHONY: run
run: pi
	LD_LIBRARY_PATH=$(SIMPLECL):$(LD_LIBRARY_PATH) ./pi

.PHONY: clean
clean :
	rm -f pi
