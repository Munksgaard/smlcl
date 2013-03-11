#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <CL/opencl.h>
#include <CL/cl.h>

#define SIMPLECL_SUCCESS 0
#define SIMPLECL_FAILURE -1

typedef struct _simplecl_machine * simplecl_machine;

typedef struct _simplecl_kernel * simplecl_kernel;

simplecl_machine sclInit(int * err);

simplecl_kernel sclCompile(simplecl_machine machine, const char * name, const char * src, int * err);

int sclRun(simplecl_machine machine /* queue */,
           simplecl_kernel kernel /* kernel */,
           const size_t work_size /* work size */,
           const int input_num /* number of input arrays */,
           const size_t * input_sizes /* size of types in input arrays */,
           void ** input_arrays /* input arrays */,
           const int output_num /* number of output arrays */,
           const size_t * output_sizes /* size of types in output arrays */,
           void ** output_arrays /* output arrays */ );



int sclCleanupKernel(simplecl_kernel kernel);

int sclCleanupMachine(simplecl_machine machine);
