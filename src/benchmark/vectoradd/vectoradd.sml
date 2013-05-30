open Utils;
open Timer;
open SmlCL;

val elems = 1000000;

fun sequentialAddReal n =
    let
        val seqArr = Array.array(n, 0.0);
        fun seqAdd 0 = ()
          | seqAdd i =
            let
                val arr = Array.fromList (randRList elems)
                val _ = Array.update (seqArr,
                                      i,
                                      Array.foldl (fn (x,acc) => acc + x)
                                                  0.0 arr)
            in seqAdd (i-1) end;

        val timer = Timer.startCPUTimer ();
        (* val _ = Array.appi (fn (i,x) => Array.update (arr1, i, Array.sub (arr2, i) + x)) arr1; *)
        val _ = seqAdd (n-1)

        val stop = Timer.checkCPUTimer timer
        (* val _ = (printRList o rarr2list) seqArr; *)
        val microsecs = Time.toMicroseconds (#usr stop)
    in print (LargeInt.toString microsecs ^ "\n")  end;

fun parallelAddReal n =
    let
        val m = init ();
        fun parAdd 0 = ()
          | parAdd i =
            let
                val b1 = mkBuf m Real (Array.fromList (randRList elems))
                val br = red (fn (x, a) => Add x a) (RealC 0.0) b1 Real;
            in parAdd (i-1) end;

        val timer = Timer.startCPUTimer ();
        (* val _ = Array.appi (fn (i,x) => Array.update (arr1, i, Array.sub (arr2, i) + x)) arr1; *)
        val _ = parAdd (n-1)

        val stop = Timer.checkCPUTimer timer
        (* val _ = (printRList o rarr2list) seqArr; *)
        val microsecs = Time.toMicroseconds (#usr stop)
    in print (LargeInt.toString microsecs ^ "\n")  end;

sequentialAddReal 100;
parallelAddReal 100;


(* val arr1 = Array.fromList (randRList elems); *)
(* val b1 = mkBuf m Real arr1; *)
(* print "Summing array using SmlCL.red...\n"; *)
(* print (Real.toString (red (fn (x, a) => Add x a) (RealC 0.0) b1 Real) ^ "\n"); *)
