#include <stdlib.h>
#include <stdio.h>

#include <CL/opencl.h>
#include <CL/cl.h>

#define SIZEINFO(x) printf(#x": %d\n", (int)sizeof(x));

int main() {
  SIZEINFO(int);
  SIZEINFO(cl_int);
  SIZEINFO(char);
  SIZEINFO(cl_char);
  SIZEINFO(double);
  SIZEINFO(cl_double);
  return 0;
}
