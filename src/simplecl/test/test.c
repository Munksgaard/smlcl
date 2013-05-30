#include <simplecl.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

const char * vectordouble_src = "#pragma OPENCL EXTENSION cl_khr_fp64 : enable \n\n__kernel void VectorDouble(__global const double* a, __global double* c) {\n"
  "    int iGID = get_global_id(0);\n"
  "    c[iGID] = a[iGID] * 2;\n"
  "}\n";

const char * vectoradd_src = "#pragma OPENCL EXTENSION cl_khr_fp64 : enable \n\n__kernel void VectorAdd(__global const double* a, __global const double* b, __global double* c) {\n"
  "    int iGID = get_global_id(0);\n"
  "    c[iGID] = a[iGID] + b[iGID];\n"
  "}\n";

int main() {
  int err = SIMPLECL_SUCCESS;

  simplecl_machine machine = sclInit(&err);
  if (err != SIMPLECL_SUCCESS) {
    printf("Something wrong?\n");
    return -1;
  }
  printf("Successfully initiated\n");
  simplecl_kernel kernel1 = sclCompile(machine, "VectorDouble", vectordouble_src, strlen(vectordouble_src), &err);
  simplecl_kernel kernel2 = sclCompile(machine, "VectorAdd", vectoradd_src, strlen(vectoradd_src), &err);
  printf("Compiled kernel\n");

  const cl_int num_values = 100000;

  cl_double array_1[num_values];
  cl_double array_2[num_values];
  cl_double output[num_values];

  // Initializing arrays
  for(int i = 0; i < num_values; i++) {
    array_1[i] = (cl_double) 2.2f * i;
    array_2[i] = (cl_double) i + 1.5f;
  }

  simplecl_buffer rbuf1 = sclCreateBuffer(machine, num_values, sizeof(cl_double), array_1);
  simplecl_buffer rbuf2 = sclCreateBuffer(machine, num_values, sizeof(cl_double), array_2);
  simplecl_buffer wbuf = sclCreateBuffer(machine, num_values, sizeof(cl_double), NULL);

  printf("Created buffers\n");

  /* simplecl_buffer input_buffers[2] = {rbuf1, rbuf2}; */
  /* simplecl_buffer output_buffers[1] = {wbuf}; */

  printf("Running VectorDouble\n");
  err = sclRun1(machine, kernel1, num_values, rbuf1, wbuf);

  err = sclReadBuffer(machine, wbuf, num_values, sizeof(cl_double), output);
  printf("The first 10 elements are:\n");
  for (int i=0; i<10; i++) {
    printf("%d: %f (expected: %f)\n", i, output[i], array_1[i] * 2);
  }

  err = sclWriteBuffer(machine, rbuf1, num_values, sizeof(cl_double), output);

  err = sclRun2(machine, kernel2, num_values, rbuf1, rbuf2, wbuf);
  printf("Runing VectorAdd\n");
  err = sclReadBuffer(machine, wbuf, num_values, sizeof(cl_double), output);

  printf("The first 10 elements are:\n");
  for (int i=0; i<10; i++) {
    printf("%d: %f (expected: %f)\n", i, output[i], array_1[i] * 2 + array_2[i]);
  }

  printf("The last 10 elements are:\n");
  for (int i=num_values-1; i>= num_values - 10; i--) {
    printf("%d: %f (expected: %f)\n", i, output[i], array_1[i] * 2 + array_2[i]);
  }

  sclFreeBuffer(rbuf1);
  sclFreeBuffer(rbuf2);
  sclFreeBuffer(wbuf);

  sclCleanupKernel(kernel1);
  sclCleanupKernel(kernel2);
  sclCleanupMachine(machine);

  return 0;
}
