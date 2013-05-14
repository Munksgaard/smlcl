include ../Makefile.inc

libsimplecl.so : simplecl.c simplecl.h
	gcc -fPIC -c -I. -I$(CUDA)/include -L$(CUDA)/lib64 simplecl.c -lOpenCL -Wall -Wextra -pedantic -std=c99 -lOpenCL
	gcc -shared -I. -I$(CUDA)/include -L$(CUDA)/lib64 -Wall -Wextra -pedantic -std=c99 -lOpenCL -o libsimplecl.so simplecl.o  -lOpenCL

clean :
	rm -f *.so *.o *.a 

