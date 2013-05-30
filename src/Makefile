include Makefile.inc

.PHONY: all, clean, test, run
all : 
	make -C $(SIMPLECL)
	make -C $(PRIMCL)
	make -C $(SMLCL)

test : clean all
	make -C $(SIMPLECL) test
	make -C $(PRIMCL) test
	make -C $(SMLCL) test

clean :
	make -C $(SMLCL) clean
	make -C $(PRIMCL) clean
	make -C $(SIMPLECL) clean

