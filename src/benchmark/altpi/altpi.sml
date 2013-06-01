open PrimCL;
open TextIO;
open Utils;
open Timer;

val elems = 10000;
val ntests = 100;

val m = valOf (init ())

val src = "#pragma OPENCL EXTENSION cl_khr_fp64 : enable\n"
          ^ "__kernel void parallelpi(__global int* bufr, __global int* bufx) {\n"
          ^ "  int iGID = get_global_id(0);\n"
          ^ "  int global_size= get_global_size(0);\n"
          ^ "\n"
          ^ "  int i;\n"
          ^ "  double x;\n"
          ^ "  double y = (double)iGID / (double)global_size;\n"
          ^ "\n"
          ^ "  int acc = 0;\n"
          ^ "\n"
          ^ "  for (i=0; i<global_size; i++) {\n"
          ^ "    x = (double)i / (double)global_size;\n"
          ^ "    if (x*x+y*y <= 1.0) {\n"
          ^ "      acc++;\n"
          ^ "    }\n"
          ^ "  }\n"
          ^ "  bufr[iGID] = acc;\n"
          ^ "\n"
          ^ "  barrier(CLK_GLOBAL_MEM_FENCE);\n"
          ^ "\n"
          ^ "  acc = 0;\n"
          ^ "  if (iGID == 0) {\n"
          ^ "    for (i=0; i<global_size; i++) {\n"
          ^ "      acc = acc + bufr[i];\n"
          ^ "    }\n"
          ^ "    bufr[0] = acc;\n"
          ^ "  }\n"
          ^ "}\n";

val k = valOf (compile (m, "parallelpi", src));

val b1 = valOf (mkBufEmpty (m, intSize, elems));
val b2 = valOf (mkBufEmpty (m, intSize, 1));
val arr = Array.array(elems, 0);

fun gpu () =
    let val _ = kcall1 (m, k, elems, b1, b2);
        val _ = readIntBuf (m, intSize, elems, b1, arr);
    in 
        print ("pi = " ^ Real.toString (real (Array.sub(arr, 0)) / (real elems * real elems) * 4.0) ^ "\n")
    end;

fun cpu (i, j, acc) =
    if i < elems then
        if j < elems then
            let val y = real i / real elems;
                val x = real j / real elems;
                val tmp = if x*x+y*y <= 1.0 then 1 else 0;
            in cpu (i, j+1, acc + tmp) end
        else
            cpu (i+1, 0, acc)
    else
        print ("pi = " ^ Real.toString ((real acc) / (real elems * real elems) * 4.0) ^ "\n");

print ("GPU took " ^ LargeInt.toString (benchmark (fn () => dotimes gpu () ntests)) ^ "\n");
print ("CPU took " ^ LargeInt.toString (benchmark (fn () => dotimes cpu (0, 0, 0) ntests)) ^ "\n");
