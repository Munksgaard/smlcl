include Makefile.inc

.PHONY: all
all : 
	make -C $(SIMPLECL)
	make -C $(SMLCL)

run : all
	make -C $(SMLCL)/test run

.PHONY: clean
clean :
	make -C $(SMLCL) clean
	make -C $(SIMPLECL) clean

