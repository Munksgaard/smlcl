.PHONY: all
all: libsimplecl.so test

libsimplecl.so : simplecl.c simplecl.h
	gcc -fPIC -c -I. -I/home/pmunksgaard/.local/cuda-5.0/include -L/home/pmunksgaard/.local/cuda-5.0/lib64 simplecl.c -lOpenCL -Wall -Wextra -pedantic -std=c99 -lOpenCL
	gcc -shared -I. -I/home/pmunksgaard/.local/cuda-5.0/include -L/home/pmunksgaard/.local/cuda-5.0/lib64 -Wall -Wextra -pedantic -std=c99 -lOpenCL -o libsimplecl.so simplecl.o  -lOpenCL

test : test.c
	gcc -Wall -Wextra -pedantic test.c  -o test -I. -I/home/pmunksgaard/.local/cuda-5.0/include -L. -lsimplecl -std=c99

clean :
	rm -f *.so *.o *.a test

run : test
	./test
