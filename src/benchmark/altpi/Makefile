include ../../Makefile.inc

TARGET=altpi

.PHONY: all
all : ${TARGET}

${TARGET}: ${TARGET}.mlb ${TARGET}.sml ../utils/utils.sml
	mlton -link-opt -lsimplecl -link-opt -L$(SIMPLECL) -cc-opt -I$(SIMPLECL) -cc-opt -I$(CUDA)/include/ ${TARGET}.mlb $(PRIMCL)/primcl.c

.PHONY: run
run: ${TARGET}
	LD_LIBRARY_PATH=$(SIMPLECL):$(LD_LIBRARY_PATH) ./${TARGET}

.PHONY: clean
clean :
	rm -f ${TARGET}
