#include <simplecl.h>

const char * vectoradd_src = "#pragma OPENCL EXTENSION cl_khr_fp64 : enable \n\n__kernel void VectorAdd(__global const double* a, __global const double* b, __global double* c) {\n"
  "    int iGID = get_global_id(0);\n"
  "    c[iGID] = a[iGID] + b[iGID] * b[0];\n"
  "}\n";

int main() {
  int err = SIMPLECL_SUCCESS;

  printf("Hello world!\n");

  simplecl_machine machine = sclInit(&err);
  if (err != SIMPLECL_SUCCESS) {
    printf("Something wrong?\n");
    return -1;
  }

  simplecl_kernel kernel = sclCompile(machine, "VectorAdd", vectoradd_src, &err);

  const cl_int num_values = 100000;

  cl_double array_1[num_values];
  cl_double array_2[num_values];
  cl_double output[num_values];

  // Initializing arrays
  for(int i = 0; i < num_values; i++) {
    array_1[i] = (cl_double) 2.0f;
    array_2[i] = (cl_double) i + 1.5f;
  }

  simplecl_buffer rbuf1 = sclCreateReadBuffer(machine, num_values, sizeof(cl_double), array_1);
  simplecl_buffer rbuf2 = sclCreateReadBuffer(machine, num_values, sizeof(cl_double), array_2);
  simplecl_buffer wbuf = sclCreateWriteBuffer(machine, num_values, sizeof(cl_double));

  /* simplecl_buffer input_buffers[2] = {rbuf1, rbuf2}; */
  /* simplecl_buffer output_buffers[1] = {wbuf}; */

  err = sclRun2_1(machine, kernel, num_values, rbuf1, rbuf2, wbuf);

  err = sclReadBuffer(machine, wbuf, num_values, sizeof(cl_double), output);

  printf("The first 10 elements are:\n");
  for (int i=0; i<10; i++) {
    printf("%d: %f (expected: %f)\n", i, output[i], array_1[i] + array_2[i] * array_2[0]);
  }

  printf("The last 10 elements are:\n");
  for (int i=num_values-1; i>= num_values - 10; i--) {
    printf("%d: %f (expected: %f)\n", i, output[i], array_1[i] + array_2[i] * array_2[0]);
  }

  sclCleanupKernel(kernel);
  sclCleanupMachine(machine);

  return 0;
}
