.PHONY: run, clean

vectoradd : host.c vectoradd.cl
	gcc -Wall -Wextra -pedantic host.c -o vectoradd -I/home/pmunksgaard/.local/cuda-5.0/include -L/home/pmunksgaard/.local/cuda-5.0/lib64 -lOpenCL -std=c99

run: vectoradd
	./vectoradd

clean:
	rm -f vectoradd
