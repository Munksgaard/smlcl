#include <simplecl.h>

const char * vectoradd_src = "__kernel void VectorAdd(__global const float* a, __global const float* b, __global float* c, int iNumElements) {\n"
  "    int iGID = get_global_id(0);\n"
  "    if (iGID >= iNumElements) {\n"
  "        return;\n"
  "    }\n"
  "\n"
  "    c[iGID] = a[iGID] + b[iGID] * b[0];\n"
  "}\n";

int main() {
  int err;

  printf("Hello world!\n");

  simplecl_machine machine = sclInit(&err);
  if (err != SIMPLECL_SUCCESS) {
    printf("Something wrong?\n");
    return -1;
  }

  simplecl_kernel kernel = sclCompile(machine, "VectorAdd", vectoradd_src, &err);

  const cl_int num_values = 100000;
  size_t input_sizes[2] = {sizeof(cl_float), sizeof(cl_float)};
  cl_float array_1[num_values];
  cl_float array_2[num_values];
  cl_float * input_arrays[2] = {array_1, array_2};

  size_t output_sizes[1] = {sizeof(cl_float)};
  cl_float array_dst[num_values];
  cl_float * output_arrays[1] = {array_dst};

  // Initializing arrays
  for(int i = 0; i < num_values; i++) {
    array_1[i] = (cl_float) 2.0f;
    array_2[i] = (cl_float) i + 1.5f;
  }



  err = sclRun(machine, kernel, num_values, 2, input_sizes, (void**)input_arrays, 1, output_sizes, (void**)output_arrays);

  printf("The first 10 elements are:\n");
  for (int i=0; i<10; i++) {
    printf("%d: %f\n", i, array_dst[i]);
    printf("Should be: %f\n", array_1[i] + array_2[i] * array_2[0]);
  }

  printf("The last 10 elements are:\n");
  for (int i=num_values-1; i>= num_values - 10; i--) {
    printf("%d: %f\n", i, array_dst[i]);
    printf("Should be: %f\n", array_1[i] + array_2[i] * array_2[0]);
  }

  sclCleanupKernel(kernel);
  sclCleanupMachine(machine);

  return 0;
}
