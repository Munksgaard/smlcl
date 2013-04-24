#include <stdlib.h>
#include <stdio.h>

#include "export.h";
#include "ml-types.h";
#include "platform.h"
#include "gc.h"

#include <simplecl.h>

Pointer cSclInit() {
  int err = SIMPLECL_SUCCESS;

  simplecl_machine machine = sclInit(&err);

  if (err != SIMPLECL_SUCCESS) {
    printf("Init failed\n");
    return NULL;
  } else {
    return (Pointer)machine;
  }
}

Pointer cSclCompile(Pointer p, char * name, char * src) {
  int err = SIMPLECL_SUCCESS;

  simplecl_machine machine = (simplecl_machine)p;

  simplecl_kernel kernel = sclCompile(machine, name, src, &err);
  if (err != SIMPLECL_SUCCESS) {
    printf("Compile failed\n");
    return NULL;
  } else {
    return (Pointer)kernel;
  }
}

Bool cSclRun(Pointer p_machine, Pointer p_kernel, Int32 worksize, Pointer p_inputs, Pointer p_outputs) {
  simplecl_machine machine = (simplecl_machine)p_machine;
  simplecl_kernel kernel = (simplecl_kernel)p_kernel;

  double ** input_arrays = (double*)p_inputs;
  int n_input = (int)GC_getArrayLength(p_inputs);
  size_t input_type_sizes[n_input];
  int input_sizes[n_input];

  double ** output_arrays = (double*)p_outputs;
  int n_output = (int)GC_getArrayLength(p_outputs);
  size_t output_type_sizes[n_output];
  int output_sizes[n_output];

  int i,j;

  int err;

  for (i=0; i<n_input; i++) {
    input_sizes[i] = (int)GC_getArrayLength((Pointer)input_arrays[i]);
    input_type_sizes[i] = sizeof(double);
  }

  for (i=0; i<n_output; i++) {
    output_sizes[i] = (int)GC_getArrayLength((Pointer)output_arrays[i]);
    output_type_sizes[i] = sizeof(double);
  }

  err = sclRun(machine, kernel, worksize, n_input, input_sizes,
               input_type_sizes, (void**)input_arrays, n_output, output_sizes,
               output_type_sizes, (void**)output_arrays);

  if (err != SIMPLECL_SUCCESS) {
    printf("Run failed\n");
    return 0;
  }

  return 1;

}
