open Utils;
open Timer;
open SmlCL;

val elems = 10000000;

val m = init ();

print "Initialized GPU\n";

fun pi_cpu () =
    let
        val arr1 = Array.fromList (randRList elems);
        val arr2 = Array.fromList (randRList elems);

        val tmparr = Array.tabulate
                         (elems, (fn x => let val a = Array.sub (arr1, x);
                                              val b = Array.sub (arr2, x);
                                              val c = a * a + b * b
                                          in if c < 1.0 then 1 else 0 end));
        val sum = Array.foldr (fn (x, acc) => x + acc) 0 tmparr;
    in real sum / real elems * 4.0 end;

fun pi_gpu (b1, b2, k) =
    let
        val arr1 = Array.fromList (randRList elems);
        val arr2 = Array.fromList (randRList elems);

        val b1 = writeBuf arr1 b1;
        val b2 = writeBuf arr2 b2;

        val tmpbuf = kcall2 k (b1, b2) elems;

        val sum = red (fn (x, y) => Add x y) (IntC 0) tmpbuf Int;
        val _ = freeBuf tmpbuf;
    in
        print (Real.toString (real sum / real elems * 4.0) ^ "\n")
    end;

print "Running CPU benchmark...\n";
val cpu_t1 = Timer.startCPUTimer ();
dotimes (fn _ => print (Real.toString (pi_cpu ()) ^ "\n")) () 100;
val cpu_t2 = Timer.checkCPUTimer cpu_t1;

print "\nRunning GPU benchmark...\n";
val gpu_t1 = Timer.startCPUTimer ();
val b1 = mkBuf m Real (Array.fromList (randRList elems));
val b2 = mkBuf m Real (Array.fromList (randRList elems));
val k = mkKern2 m "bum" (fn (x,y) => If (Lt (Add (Mul (x This)
                                                      (x This))
                                                 (Mul (y This)
                                                      (y This)))
                                            (RealC 1.0))
                                        (IntC 1)
                                        (IntC 0))
                        (Real, Real) Int;
dotimes pi_gpu (b1, b2, k) 100;
val gpu_t2 = Timer.checkCPUTimer gpu_t1;

print ("GPU took " ^ LargeInt.toString (Time.toMilliseconds (#sys gpu_t2))
       ^ " milliseconds.\n");
print ("CPU took " ^ LargeInt.toString (Time.toMilliseconds (#sys cpu_t2))
       ^ " milliseconds.\n");
