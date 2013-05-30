include ../../Makefile.inc

.PHONY: all
all : vectoradd

vectoradd: vectoradd.mlb vectoradd.sml ../utils/utils.sml
	make -C $(SIMPLECL)
	make -C $(SMLCL)
	mlton -link-opt -lsimplecl -link-opt -L$(SIMPLECL) -cc-opt -I$(SIMPLECL) -cc-opt -I$(CUDA)/include/ vectoradd.mlb $(PRIMCL)/primcl.c

.PHONY: run
run : vectoradd
	LD_LIBRARY_PATH=$(SIMPLECL):$(LD_LIBRARY_PATH) ./vectoradd

.PHONY: clean
clean :
	rm -f vectoradd
