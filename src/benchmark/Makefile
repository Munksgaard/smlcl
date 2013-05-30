include ../Makefile.inc

.PHONY: all
all :
	make -C utils
	make -C vectoradd
	make -C pi

.PHONY: test
test :
	make -C utils test
	make -C vectoradd test
	make -C pi test

.PHONY: clean
clean :
	make -C utils clean
	make -C vectoradd clean
	make -C pi clean
