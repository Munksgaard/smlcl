open Utils;
open Timer;
open SmlCL;

val elems = 1000000;
val testn = 100;

val m = init ();

print "Initialized GPU\n";

fun map_cpu () =
    let
        val arr1 = Array.fromList (randRList elems);

        val tmparr = Array.tabulate
                         (elems, (fn x => (Array.sub (arr1, x) * Array.sub(arr1, x)) / 1.5))
    in () end;

fun map_gpu (b1, k) =
    let
        val arr1 = Array.fromList (randRList elems);

        val b1 = writeBuf arr1 b1;

        val tmpbuf = kcall1 k b1 elems;

        val tmparr = readBuf tmpbuf
        val _ = freeBuf tmpbuf;
    in
        ()
    end;

print "\nRunning GPU benchmark...\n";
val b1 = mkBuf m Real (Array.fromList (randRList elems));
val k = map m (fn x => Div (Mul x x) (RealC 1.5)) Real Real;
val gpu_t1 = Timer.startCPUTimer ();
dotimes map_gpu (b1, k) testn;
val gpu_t2 = Timer.checkCPUTimer gpu_t1;

print "Running CPU benchmark...\n";
val cpu_t1 = Timer.startCPUTimer ();
dotimes map_cpu () testn;
val cpu_t2 = Timer.checkCPUTimer cpu_t1;

print ("GPU took " ^ LargeInt.toString (Time.toMilliseconds (#usr gpu_t2))
       ^ " milliseconds.\n");
print ("CPU took " ^ LargeInt.toString (Time.toMilliseconds (#usr cpu_t2))
       ^ " milliseconds.\n");

freeBuf b1;
cleanKern1 k;
cleanMachine m;
