#include <CL/opencl.h>
#include <CL/cl.h>
#include <stdlib.h>
#include <stdio.h>

#define MAX_SOURCE_SIZE (0x100000)
#define ELEMS 100

int main() {
  cl_platform_id platform;

  cl_uint num_devices_returned;
  cl_device_id device;

  cl_context context;
  cl_command_queue queue;

  cl_program program;
  cl_kernel kernel;
  cl_event event;

  cl_double arr1[ELEMS];
  cl_double arr2[ELEMS];
  cl_double arr3[ELEMS];
  cl_mem buf1, buf2, buf3;

  char * src;
  char src_file[] = "vectoradd.cl";
  FILE *fp;

  cl_int err = CL_SUCCESS;

  int i;
  const size_t worksize = ELEMS;

  // Populate input arrays
  for (i=0; i<ELEMS; i++) {
    arr1[i] = 0.1 * i;
    arr2[i] = 0.2 * i;
  }

  // Read source code into src
  fp = fopen(src_file, "r");
  src = (char*)malloc(MAX_SOURCE_SIZE);
  fread(src, 1, MAX_SOURCE_SIZE, fp);

  // Get platform and device IDs, create context and command queue
  err = clGetPlatformIDs(1, &platform, NULL);
  err = clGetDeviceIDs(platform, CL_DEVICE_TYPE_GPU, 1, &device, &num_devices_returned);
  context = clCreateContext (0, 1, &device, NULL, NULL, &err);
  queue = clCreateCommandQueue (context, device, CL_QUEUE_PROFILING_ENABLE, &err);

  // Read the program from source, comppile it and create the kernel
  program = clCreateProgramWithSource(context, 1, (const char**)(&src), NULL, &err);
  err = clBuildProgram(program, 0, NULL, 0, NULL, NULL);
  kernel = clCreateKernel(program, "vectoradd", &err);

  // Create buffers for input/output
  buf1 = clCreateBuffer(context, CL_MEM_READ_ONLY, sizeof(cl_double) * ELEMS, NULL, &err);
  buf2 = clCreateBuffer(context, CL_MEM_READ_ONLY, sizeof(cl_double) * ELEMS, NULL, &err);
  buf3 = clCreateBuffer(context, CL_MEM_WRITE_ONLY, sizeof(cl_double) * ELEMS, NULL, &err);

  // Write input-data to input-buffers
  err = clEnqueueWriteBuffer(queue, buf1, CL_FALSE, 0, sizeof(cl_double) * ELEMS, arr1, 0, NULL, NULL);
  err = clEnqueueWriteBuffer(queue, buf2, CL_FALSE, 0, sizeof(cl_double) * ELEMS, arr2, 0, NULL, NULL);

  // Set arguments to the kernel
  err = clSetKernelArg(kernel, 0, sizeof(buf1), (void*)&buf1);
  err = clSetKernelArg(kernel, 1, sizeof(buf2), (void*)&buf2);
  err = clSetKernelArg(kernel, 2, sizeof(buf3), (void*)&buf3);

  // Execute kernel
  err = clEnqueueNDRangeKernel(queue, kernel, 1, NULL, &worksize, NULL, 0, NULL, &event);

  // Read and print output from buffer
  err = clEnqueueReadBuffer(queue, buf3, CL_TRUE, 0, sizeof(cl_double) * ELEMS, arr3, 0, NULL, NULL);
  for (i=0; i<ELEMS; i++) {
    printf("arr3[%d] = %f\n", i, arr3[i]);
  }

  return 0;

}
