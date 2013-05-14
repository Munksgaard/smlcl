#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <CL/opencl.h>
#include <CL/cl.h>

#define SIMPLECL_SUCCESS 0
#define SIMPLECL_FAILURE -1

typedef struct _simplecl_machine * simplecl_machine;

typedef struct _simplecl_kernel * simplecl_kernel;

typedef cl_mem simplecl_buffer;

simplecl_machine sclInit(int * err);

simplecl_kernel sclCompile(simplecl_machine machine,
                           const char * name,
                           const char * src,
                           int * err);

/* Creates a read-only buffer on the device with the contents of array */
simplecl_buffer sclCreateReadBuffer(simplecl_machine machine,
                                    int size,
                                    size_t type_size,
                                    void * array);

/* Creates a write-only buffer on the device */
simplecl_buffer sclCreateWriteBuffer(simplecl_machine machine,
                                     int size,
                                     size_t type_size);

/* Creates a read-write buffer on the device.
   If array != NULL fills the buffer with the contents of array */
simplecl_buffer sclCreateReadWriteBuffer(simplecl_machine machine,
                                         int size,
                                         size_t type_size,
                                         void * array);

/* Reads the contents of buffer into array.
   Returns SIMPLECL_SUCCESS on success and SIMPLECL_FAILURE otherwise */
int sclReadBuffer(simplecl_machine machine,
                  simplecl_buffer buffer,
                  int size,
                  size_t type,
                  void * array);

/* Writes the contents of the buffer into the array */
int sclWriteBuffer(simplecl_machine machine,
                   simplecl_buffer buffer,
                   int size,
                   size_t type_size,
                   void * array);

int sclRun(simplecl_machine machine /* queue */,
           simplecl_kernel kernel /* kernel */,
           const size_t work_size /* work size */,
           const int input_num /* number of input arrays */,
           simplecl_buffer * input_buffers /* input arrays */,
           const int output_num /* number of output arrays */,
           simplecl_buffer * output_buffers /* output arrays */ );

int sclRun1_1(simplecl_machine machine,
              simplecl_kernel kernel,
              const size_t work_size,
              simplecl_buffer input,
              simplecl_buffer output);

int sclRun2_1(simplecl_machine machine,
              simplecl_kernel kernel,
              const size_t work_size,
              simplecl_buffer input_1,
              simplecl_buffer input_2,
              simplecl_buffer output);

int sclRun2_2(simplecl_machine machine,
              simplecl_kernel kernel,
              const size_t work_size,
              simplecl_buffer input_1,
              simplecl_buffer input_2,
              simplecl_buffer output_1,
              simplecl_buffer output_2);

int sclRun3_1(simplecl_machine machine,
              simplecl_kernel kernel,
              const size_t work_size,
              simplecl_buffer input_1,
              simplecl_buffer input_2,
              simplecl_buffer input_3,
              simplecl_buffer output);

/* Frees a buffer from the device */
int sclFreeBuffer(simplecl_buffer buffer);

int sclCleanupKernel(simplecl_kernel kernel);

int sclCleanupMachine(simplecl_machine machine);
