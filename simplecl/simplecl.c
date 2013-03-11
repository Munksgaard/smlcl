#include <CL/opencl.h>
#include <CL/cl.h>
#include <simplecl.h>

struct _simplecl_machine {
  cl_context context;
  cl_command_queue queue;
};

struct _simplecl_kernel {
  cl_kernel kernel;
  cl_program program;
} ;

simplecl_machine sclInit(int *return_err) {
  cl_int err = CL_SUCCESS;

  cl_platform_id platform;

  cl_uint num_devices_returned;
  cl_device_id device;

  cl_context context;
  cl_command_queue queue;

  //  simplecl_machine machine;

  err = clGetPlatformIDs(1, &platform, NULL);
  if (err != CL_SUCCESS) {
    printf("Error in clGetPlatformID, Line %u in files %s !!!\n\n", __LINE__, __FILE__);
    *return_err = SIMPLECL_FAILURE;
    return NULL;
  }

  err = clGetDeviceIDs(platform, CL_DEVICE_TYPE_GPU , 1, &device, &num_devices_returned);
  if (err != CL_SUCCESS) {
    printf("Error n clGetDeviceIDs, Line %u in file %s !!! \n\n", __LINE__, __FILE__);
    *return_err = SIMPLECL_FAILURE;
    return NULL;
  }

  context = clCreateContext (0, 1, &device, NULL, NULL, &err);
  if (err != CL_SUCCESS) {
    printf("Error in clCreateContext, Line %u in file %s !!! \n\n", __LINE__, __FILE__);
    *return_err = SIMPLECL_FAILURE;
    return NULL;
  }

  queue = clCreateCommandQueue (context, device, CL_QUEUE_PROFILING_ENABLE, &err);
  if (err != CL_SUCCESS) {
    printf("Error in clCreateCommandQueue, Line %u in file %s !!!\n\n", __LINE__, __FILE__);
    *return_err = SIMPLECL_FAILURE;
    return NULL;
  }

  simplecl_machine machine = malloc(sizeof(simplecl_machine));
  machine->context = context;
  machine->queue = queue;

  return machine;

}

simplecl_kernel sclCompile(simplecl_machine machine, const char * name, const char * src, int * return_err) {
  int err = CL_SUCCESS;

  cl_program program = clCreateProgramWithSource(machine->context, 1, &src, NULL, &err);
  if (err != CL_SUCCESS) {
    printf("Error in clCreateProgramWithSource, Line %u in file %s !!!\n\n", __LINE__, __FILE__);
    *return_err = SIMPLECL_FAILURE;
    return NULL;
  }

  err = clBuildProgram(program, 0, NULL, 0, NULL, NULL);
  if (err != CL_SUCCESS) {
    printf("Error in clBuildProgram, Line %u in file %s !!!\n\n", __LINE__, __FILE__);
    printf("The error is: %d\n\n", (int) err);
    printf("The source code is:\n%s\n\n", src);
    *return_err = SIMPLECL_FAILURE;
    return NULL;
  }

  cl_kernel kernel = clCreateKernel(program, name, &err);
  if (err != CL_SUCCESS) {
    printf("Error in clCreateKernel, Line %u in file %s !!!\n\n", __LINE__, __FILE__);
    printf("The error is: %d\n\n", (int) err);
    printf("The source code is:\n%s\n\n", src);

    *return_err = SIMPLECL_FAILURE;
    return NULL;
  }

  simplecl_kernel result = malloc(sizeof(simplecl_kernel));

  result->kernel = kernel;
  result->program = program;

  return result;
}

int sclRun(simplecl_machine machine,
           simplecl_kernel kernel,
           const size_t work_size,
           const int input_num,
           const size_t * input_sizes,
           void ** input_arrays,
           const int output_num,
           const size_t * output_sizes,
           void ** output_arrays) {

  int err = CL_SUCCESS;
  int i;

  cl_mem input_buffers[input_num];
  cl_mem output_buffers[output_num];

  for (i=0; i<input_num; i++) {
    input_buffers[i] = clCreateBuffer(machine->context,
                                      CL_MEM_READ_ONLY,
                                      input_sizes[i] * work_size,
                                      NULL,
                                      &err);
    if (err != CL_SUCCESS) {
      printf("Error in clCreateBuffer, Line %u in file %s !!!\n\n", __LINE__, __FILE__);
      return 1;
    }

    err = clEnqueueWriteBuffer(machine->queue,
                               input_buffers[i],
                               CL_FALSE,
                               0,
                               input_sizes[i] * work_size,
                               input_arrays[i],
                               0,
                               NULL,
                               NULL);
    if (err != CL_SUCCESS) {
      printf("Error in clEnqueueWriteBuffer, Line %u in file %s !!!\n\n", __LINE__, __FILE__);
      return 1;
    }
  }

  for (i=0; i<output_num; i++) {
    output_buffers[i] = clCreateBuffer(machine->context,
                                       CL_MEM_WRITE_ONLY,
                                       output_sizes[i] * work_size,
                                       NULL,
                                       &err);
    if (err != CL_SUCCESS) {
      printf("Error in clCreateBuffer, Line %u in file %s !!!\n\n", __LINE__, __FILE__);
      return 1;
    }
  }

  for (i=0; i<input_num; i++) {
    err |= clSetKernelArg(kernel->kernel, i, sizeof(input_buffers[i]), (void*)&(input_buffers[i]));
  }

  if (err != CL_SUCCESS) {
    printf("Error in clSetKernelArg, Line %u in file %s !!!\n\n", __LINE__, __FILE__);
    return 1;
  }

  for (i=0; i<output_num; i++) {
    err |= clSetKernelArg(kernel->kernel, input_num+i, sizeof(output_buffers[i]), (void*)&(output_buffers[i]));
  }

  if (err != CL_SUCCESS) {
    printf("Error in clSetKernelArg, Line %u in file %s !!!\n\n", __LINE__, __FILE__);
    return 1;
  }

  err |= clSetKernelArg(kernel->kernel, 3, sizeof(cl_int), (void*)&(work_size));
  if (err != CL_SUCCESS) {
    printf("Error in clSetKernelArg, Line %u in file %s !!!\n", __LINE__, __FILE__);
    printf("Error code is: %d\n\n", err);
    return 1;
  }

  cl_event event;

  err = clEnqueueNDRangeKernel(machine->queue, kernel->kernel, 1, NULL, &work_size, NULL, 0, NULL, &event);
  if (err != CL_SUCCESS) {
    printf("Error in clEnqueueNDRangeKernel, Line %u in file %s !!!\n", __LINE__, __FILE__);
    printf("Error code is: %d\n\n", err);
    return 1;
  }

  for (i=0; i<output_num; i++) {
    err = clEnqueueReadBuffer(machine->queue,
                              output_buffers[i],
                              CL_FALSE,
                              0,
                              output_sizes[i] * work_size,
                              output_arrays[i],
                              0,
                              NULL,
                              NULL);
    if (err != CL_SUCCESS) {
      printf("Error in clEnqueueReadBuffer, Line %u in file %s !!!\n\n", __LINE__, __FILE__);
      printf("Error code is: %d\n\n", err);
      return 1;
    }
  }

  for (i=0; i<input_num; i++) {
    if(input_buffers[i]) clReleaseMemObject(input_buffers[i]);
  }

  for (i=0; i<output_num; i++) {
    if(output_buffers[i]) clReleaseMemObject(output_buffers[i]);
  }
  return SIMPLECL_SUCCESS;
}

int sclCleanupKernel(simplecl_kernel kernel) {
  if (kernel->kernel) clReleaseKernel(kernel->kernel);
  if (kernel->program) clReleaseProgram(kernel->program);

  if (kernel) free(kernel);

  return 0;
}

int sclCleanupMachine(simplecl_machine machine) {
  if (machine->queue) clReleaseCommandQueue(machine->queue);
  if (machine->context) clReleaseContext(machine->context);

  if (machine) free(machine);

  return 0;
}
