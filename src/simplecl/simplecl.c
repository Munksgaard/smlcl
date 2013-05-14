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

  err = clGetDeviceIDs(platform, CL_DEVICE_TYPE_GPU, 1, &device, &num_devices_returned);
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

simplecl_buffer sclCreateReadBuffer(simplecl_machine machine,
                                    int size,
                                    size_t type_size,
                                    void * array) {
  int err = CL_SUCCESS;

  cl_mem buffer;

  buffer = clCreateBuffer(machine->context,
                          CL_MEM_READ_ONLY,
                          type_size * size,
                          NULL,
                          &err);
  if (err != CL_SUCCESS) {
    printf("Error %d in clCreateBuffer, Line %u in file %s.\n\n",
           err, __LINE__, __FILE__);
    return NULL;
  }

  err = clEnqueueWriteBuffer(machine->queue,
                             buffer,
                             CL_FALSE,
                             0,
                             type_size * size,
                             array,
                             0,
                             NULL,
                             NULL);

  if (err != CL_SUCCESS) {
    printf("Error %d in clEnqueueWriteBuffer, Line %u in file %s.\n\n",
           err, __LINE__, __FILE__);
    return NULL;
  } else {
    return buffer;
  }
}

simplecl_buffer sclCreateWriteBuffer(simplecl_machine machine,
                                     int size,
                                     size_t type_size) {
  int err = CL_SUCCESS;

  cl_mem buffer;

  buffer = clCreateBuffer(machine->context,
                          CL_MEM_WRITE_ONLY,
                          type_size * size,
                          NULL,
                          &err);
  if (err != CL_SUCCESS) {
    printf("Error %d in clCreateBuffer, Line %u in file %s.\n\n",
           err, __LINE__, __FILE__);
    return NULL;
  } else {
    return (simplecl_buffer)buffer;
  }
}

simplecl_buffer sclCreateReadWriteBuffer(simplecl_machine machine,
                                         int size,
                                         size_t type_size,
                                         void * array) {
  int err = CL_SUCCESS;

  cl_mem buffer;

  buffer = clCreateBuffer(machine->context,
                          CL_MEM_READ_WRITE,
                          type_size * size,
                          NULL,
                          &err);
  if (err != CL_SUCCESS) {
    printf("Error %d in clCreateBuffer, Line %u in file %s.\n\n",
           err, __LINE__, __FILE__);
    return NULL;
  }

  if (array != NULL) {
    err = clEnqueueWriteBuffer(machine->queue,
                               buffer,
                               CL_FALSE,
                               0,
                               type_size * size,
                               array,
                               0,
                               NULL,
                               NULL);
    if (err != CL_SUCCESS) {
      printf("Error %d in clEnqueueWriteBuffer, Line %u in file %s.\n\n",
             err, __LINE__, __FILE__);
      return NULL;
    }
  }

  return (simplecl_buffer)buffer;
}

int sclReadBuffer(simplecl_machine machine,
                  simplecl_buffer buffer,
                  int size,
                  size_t type_size,
                  void * array) {
  int err;


  err = clEnqueueReadBuffer(machine->queue,
                            buffer,
                            CL_TRUE,
                            0,
                            type_size * size,
                            array,
                            0,
                            NULL,
                            NULL);
  if (err != CL_SUCCESS) {
    printf("Error in clEnqueueReadBuffer, Line %u in file %s !!!\n\n", __LINE__, __FILE__);
    printf("Error code is: %d\n\n", err);
    return 1;
  } else {
    return SIMPLECL_SUCCESS;
  }
}

int sclWriteBuffer(simplecl_machine machine,
                   simplecl_buffer buffer,
                   int size,
                   size_t type_size,
                   void * array) {
  int err;

  err = clEnqueueWriteBuffer(machine->queue,
                             buffer,
                             CL_FALSE,
                             0,
                             type_size * size,
                             array,
                             0,
                             NULL,
                             NULL);
  if (err != CL_SUCCESS) {
    printf("Error %d in clEnqueueWriteBuffer, Line %u in file %s.\n\n",
           err, __LINE__, __FILE__);
    return SIMPLECL_FAILURE;
  } else {
    return SIMPLECL_SUCCESS;
  }
}

int sclSetArg(simplecl_kernel kernel,
              int index,
              int size,
              void * arg) {
  int err = CL_SUCCESS;
  printf("Argument index: %d\n", index);

  err |= clSetKernelArg(kernel->kernel, index, (size_t)size, arg);

  if (err != CL_SUCCESS) {
    printf("Error %d in clSetKernelArg, Line %u in file %s !!!\n\n", err, __LINE__, __FILE__);
    return SIMPLECL_FAILURE;
  } else {
    return SIMPLECL_SUCCESS;
  }
}


int sclRun(simplecl_machine machine,
           simplecl_kernel kernel,
           const size_t work_size,
           const int input_num,
           simplecl_buffer * input_buffers,
           const int output_num,
           simplecl_buffer * output_buffers) {

  int err = CL_SUCCESS;
  int i;

  cl_event event;

  for (i=0; i<input_num; i++) {
    err |= clSetKernelArg(kernel->kernel, i, sizeof(input_buffers[i]), (void*)&(input_buffers[i]));
  }

  if (err != CL_SUCCESS) {
    printf("Error in clSetKernelArg, Line %u in file %s !!!\n\n", __LINE__, __FILE__);
    return SIMPLECL_FAILURE;
  }

  for (i=0; i<output_num; i++) {
    err |= clSetKernelArg(kernel->kernel, input_num+i, sizeof(output_buffers[i]), (void*)&(output_buffers[i]));
  }

  if (err != CL_SUCCESS) {
    printf("Error in clSetKernelArg, Line %u in file %s !!!\n\n", __LINE__, __FILE__);
    return SIMPLECL_FAILURE;
  }

  err = clEnqueueNDRangeKernel(machine->queue, kernel->kernel, 1, NULL, &work_size, NULL, 0, NULL, &event);
  if (err != CL_SUCCESS) {
    printf("Error in clEnqueueNDRangeKernel, Line %u in file %s !!!\n", __LINE__, __FILE__);
    printf("Error code is: %d\n\n", err);
    return SIMPLECL_FAILURE;
  }

  return SIMPLECL_SUCCESS;
}

int sclRun1_1(simplecl_machine machine,
              simplecl_kernel kernel,
              const size_t work_size,
              simplecl_buffer input,
              simplecl_buffer output) {

  int err = CL_SUCCESS;

  cl_event event;

  err |= clSetKernelArg(kernel->kernel, 0, sizeof(input), (void*)&(input));

  if (err != CL_SUCCESS) {
    printf("Error in clSetKernelArg, Line %u in file %s !!!\n\n", __LINE__, __FILE__);
    return SIMPLECL_FAILURE;
  }

  err |= clSetKernelArg(kernel->kernel, 1, sizeof(output), (void*)&(output));

  if (err != CL_SUCCESS) {
    printf("Error in clSetKernelArg, Line %u in file %s !!!\n\n", __LINE__, __FILE__);
    return SIMPLECL_FAILURE;
  }

  err = clEnqueueNDRangeKernel(machine->queue, kernel->kernel, 1, NULL, &work_size, NULL, 0, NULL, &event);
  if (err != CL_SUCCESS) {
    printf("Error in clEnqueueNDRangeKernel, Line %u in file %s !!!\n", __LINE__, __FILE__);
    printf("Error code is: %d\n\n", err);
    return SIMPLECL_FAILURE;
  }

  return SIMPLECL_SUCCESS;
}

int sclRun2_1(simplecl_machine machine,
              simplecl_kernel kernel,
              const size_t work_size,
              simplecl_buffer input_1,
              simplecl_buffer input_2,
              simplecl_buffer output) {

  int err = CL_SUCCESS;

  cl_event event;

  err |= clSetKernelArg(kernel->kernel, 0, sizeof(input_1), (void*)&(input_1));
  err |= clSetKernelArg(kernel->kernel, 1, sizeof(input_2), (void*)&(input_2));

  if (err != CL_SUCCESS) {
    printf("Error in clSetKernelArg, Line %u in file %s !!!\n\n", __LINE__, __FILE__);
    return SIMPLECL_FAILURE;
  }

  err |= clSetKernelArg(kernel->kernel, 2, sizeof(output), (void*)&(output));

  if (err != CL_SUCCESS) {
    printf("Error in clSetKernelArg, Line %u in file %s !!!\n\n", __LINE__, __FILE__);
    return SIMPLECL_FAILURE;
  }

  err = clEnqueueNDRangeKernel(machine->queue, kernel->kernel, 1, NULL, &work_size, NULL, 0, NULL, &event);
  if (err != CL_SUCCESS) {
    printf("Error in clEnqueueNDRangeKernel, Line %u in file %s !!!\n", __LINE__, __FILE__);
    printf("Error code is: %d\n\n", err);
    return SIMPLECL_FAILURE;
  }

  return SIMPLECL_SUCCESS;
}

int sclRun2_2(simplecl_machine machine,
              simplecl_kernel kernel,
              const size_t work_size,
              simplecl_buffer input_1,
              simplecl_buffer input_2,
              simplecl_buffer output_1,
              simplecl_buffer output_2) {

  int err = CL_SUCCESS;

  cl_event event;

  err |= clSetKernelArg(kernel->kernel, 0, sizeof(input_1), (void*)&(input_1));
  err |= clSetKernelArg(kernel->kernel, 1, sizeof(input_2), (void*)&(input_2));

  if (err != CL_SUCCESS) {
    printf("Error in clSetKernelArg, Line %u in file %s !!!\n\n", __LINE__, __FILE__);
    return SIMPLECL_FAILURE;
  }

  err |= clSetKernelArg(kernel->kernel, 2, sizeof(output_1), (void*)&(output_1));
  err |= clSetKernelArg(kernel->kernel, 3, sizeof(output_2), (void*)&(output_2));

  if (err != CL_SUCCESS) {
    printf("Error in clSetKernelArg, Line %u in file %s !!!\n\n", __LINE__, __FILE__);
    return SIMPLECL_FAILURE;
  }

  err = clEnqueueNDRangeKernel(machine->queue, kernel->kernel, 1, NULL, &work_size, NULL, 0, NULL, &event);
  if (err != CL_SUCCESS) {
    printf("Error in clEnqueueNDRangeKernel, Line %u in file %s !!!\n", __LINE__, __FILE__);
    printf("Error code is: %d\n\n", err);
    return SIMPLECL_FAILURE;
  }

  return SIMPLECL_SUCCESS;
}

int sclRun3_1(simplecl_machine machine,
              simplecl_kernel kernel,
              const size_t work_size,
              simplecl_buffer input_1,
              simplecl_buffer input_2,
              simplecl_buffer input_3,
              simplecl_buffer output) {

  int err = CL_SUCCESS;

  cl_event event;

  err |= clSetKernelArg(kernel->kernel, 0, sizeof(input_1), (void*)&(input_1));
  err |= clSetKernelArg(kernel->kernel, 1, sizeof(input_2), (void*)&(input_2));
  err |= clSetKernelArg(kernel->kernel, 2, sizeof(input_3), (void*)&(input_3));

  if (err != CL_SUCCESS) {
    printf("Error in clSetKernelArg, Line %u in file %s !!!\n\n", __LINE__, __FILE__);
    return SIMPLECL_FAILURE;
  }

  err |= clSetKernelArg(kernel->kernel, 3, sizeof(output), (void*)&(output));

  if (err != CL_SUCCESS) {
    printf("Error in clSetKernelArg, Line %u in file %s !!!\n\n", __LINE__, __FILE__);
    return SIMPLECL_FAILURE;
  }

  err = clEnqueueNDRangeKernel(machine->queue, kernel->kernel, 1, NULL, &work_size, NULL, 0, NULL, &event);
  if (err != CL_SUCCESS) {
    printf("Error in clEnqueueNDRangeKernel, Line %u in file %s !!!\n", __LINE__, __FILE__);
    printf("Error code is: %d\n\n", err);
    return SIMPLECL_FAILURE;
  }

  return SIMPLECL_SUCCESS;
}


int sclFreeBuffer(simplecl_buffer buffer) {
  int err = clReleaseMemObject(buffer);
  if (err != CL_SUCCESS) {
    return SIMPLECL_FAILURE;
  } else {
    return SIMPLECL_SUCCESS;
  }
}

int sclCleanupKernel(simplecl_kernel kernel) {
  if (kernel->kernel) clReleaseKernel(kernel->kernel);
  if (kernel->program) clReleaseProgram(kernel->program);

  if (kernel) free(kernel);

  return SIMPLECL_SUCCESS;
}

int sclCleanupMachine(simplecl_machine machine) {
  if (machine->queue) clReleaseCommandQueue(machine->queue);
  if (machine->context) clReleaseContext(machine->context);

  if (machine) free(machine);

  return SIMPLECL_SUCCESS;
}
