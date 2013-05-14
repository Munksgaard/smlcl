include ../../Makefile.inc

test : test.c
	gcc -Wall -Wextra -pedantic test.c  -o test -I$(SIMPLECL) -I$(CUDA)/include -L$(SIMPLECL) -lsimplecl -std=c99
	LD_LIBRARY_PATH=$(SIMPLECL):$(LD_LIBRARY_PATH) ./test

clean :
	rm -f *.so *.o *.a test

run : test
	./test
