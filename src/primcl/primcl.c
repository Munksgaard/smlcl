#include <stdlib.h>
#include <stdio.h>

#include "export.h";
#include "ml-types.h";
#include "platform.h"
#include "gc.h"

#include <simplecl.h>

Pointer init() {
  int err = SIMPLECL_SUCCESS;

  simplecl_machine machine = sclInit(&err);

  if (err != SIMPLECL_SUCCESS) {
    printf("Init failed\n");
    return NULL;
  } else {
    return (Pointer)machine;
  }
}

Pointer compile(Pointer p, char * name, char * src) {
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

Pointer createBuffer(Pointer p1,
                         int type_size,
                         int size,
                         Pointer p2) {
  simplecl_machine machine = (simplecl_machine)p1;
  void * arr = (void*)p2;
  return (Pointer)sclCreateBuffer(machine, size, (size_t)type_size, arr);
}

/* Should only be called with a read or read-write buffer */
Bool readBuffer(Pointer p1 /* simplecl_machine */,
                    int type_size,
                    int size,
                    Pointer p2 /* buffer */,
                    Pointer p3 /* array */) {
  int err = sclReadBuffer((simplecl_machine)p1,
                          (cl_mem)p2,
                          size,
                          (size_t)type_size,
                          (void*)p3);

  if (err != SIMPLECL_SUCCESS) {
    return 0;
  } else {
    return 1;
  }
}

/* Should only be called with a write or read-write buffer */
Bool writeBuffer(Pointer p_machine /* simplecl_machine */,
                     int type_size,
                     Pointer p_buffer /* buffer to read from */,
                     Pointer p_array /* array to read to */) {
  int size = GC_getArrayLength(p_array);
  int i = sclWriteBuffer((simplecl_machine)p_machine,
                         (cl_mem)p_buffer,
                         size,
                         (size_t)type_size,
                         (void*)p_array);

  if (i != SIMPLECL_SUCCESS) {
    return 0;
  } else {
    return 1;
  }
}


Bool run1(Pointer p_machine,
                Pointer p_kernel,
                Int32 worksize,
                Pointer inputp,
                Pointer outputp) {
  simplecl_machine machine = (simplecl_machine)p_machine;
  simplecl_kernel kernel = (simplecl_kernel)p_kernel;

  cl_mem input = (cl_mem)inputp;

  cl_mem output = (cl_mem)outputp;

  int err;

  err = sclRun1(machine,
                  kernel,
                  worksize,
                  input,
                  output);

  if (err != SIMPLECL_SUCCESS) {
    printf("Run failed\n");
    return 0;
  } else {
    return 1;
  }
}

Bool run2(Pointer p_machine,
                Pointer p_kernel,
                Int32 worksize,
                Pointer inputp_1,
                Pointer inputp_2,
                Pointer outputp) {
  simplecl_machine machine = (simplecl_machine)p_machine;
  simplecl_kernel kernel = (simplecl_kernel)p_kernel;

  cl_mem input_1 = (cl_mem)inputp_1;
  cl_mem input_2 = (cl_mem)inputp_2;

  cl_mem output = (cl_mem)outputp;

  int err;

  err = sclRun2(machine,
                  kernel,
                  worksize,
                  input_1,
                  input_2,
                  output);

  if (err != SIMPLECL_SUCCESS) {
    printf("Run failed\n");
    return 0;
  } else {
    return 1;
  }
}

Bool freeBuffer(Pointer p_buffer) {
  if (sclFreeBuffer((cl_mem)p_buffer) != SIMPLECL_SUCCESS) {
    return 0;
  } else {
    return 1;
  }
}

Bool cleanupKernel(Pointer p_kernel) {
  if (sclCleanupKernel((simplecl_kernel)p_kernel) != SIMPLECL_SUCCESS) {
    return 0;
  } else {
    return 1;
  }
}

Bool cleanupMachine(Pointer p_machine) {
  if (sclCleanupMachine((simplecl_machine)p_machine) != SIMPLECL_SUCCESS) {
    return 0;
  } else {
    return 1;
  }
}
