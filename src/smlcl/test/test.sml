val rarr2list : real array -> real list = Array.foldr (fn (x, xs) => x :: xs) []
val iarr2list : int array -> int list = Array.foldr (fn (x, xs) => x :: xs) []

val printRList = app (fn x => print ((Real.toString x) ^ "\n"))
val printIList = app (fn x => print ((Int.toString x) ^ "\n"))

open SmlCL

val m = init ();
val b1 = mkBuf m Real (Array.fromList [1.0, 2.0, 3.0]);
val a1 = readBuf b1;

printRList (rarr2list a1);

val b2 = mkBuf m Real (Array.fromList [9.0, 5.0, 7.0]);
val a2 = readBuf b2;
printRList (rarr2list a2);

val k = mkKern2 m "VectorAdd" (fn (b1, b2) => Add (b1 This) (b2 This)) (Real, Real) Real;

val rbuf = kcall2 k (b1, b2) 3;

val r = readBuf rbuf;
printRList (rarr2list r);

val b3 = writeBuf (Array.fromList [42.0, 43.0, 44.0]) rbuf;
val a3 = readBuf b3;
printRList (rarr2list a3);

val b4 = writeBuf (Array.fromList [11.0, 12.0]) rbuf;
val a4 = readBuf b4;
printRList (rarr2list a4);

val b5 = (writeBuf (Array.fromList [11.0, 12.0, 13.0, 14.0]) rbuf;
          print "This shouldn't happen\n") handle Fail _ => print "yes\n";

print (kern2src k);

val mapk = map m (fn b => Mul (IntC 2) b) Int Int;
printIList(iarr2list (readBuf (kcall1 mapk (mkBuf m Int (Array.fromList [42,43,44,54])) 4)));

print (Int.toString (red (fn (x, a) => If (Gt x a) x a) (IntC 0) (mkBuf m Int (Array.fromList [1,2,3,4])) Int) ^ "\n");

fun lst 0 = []
  | lst n = n :: lst (n-1);

print (Int.toString (red (fn (x, a) => Add x a) (IntC 0) (mkBuf m Int (Array.fromList (lst 60000))) Int) ^ "\n");

fun rlst 0 = []
  | rlst n = real n :: rlst (n-1);

print (Real.toString (red (fn (x, a) => Add x a) (RealC 0.0) (mkBuf m Real (Array.fromList (rlst 60000))) Real) ^ "\n");

val mapk = map m (fn x => Add x x) Int Int;

print (kern1src mapk);

printIList(iarr2list (readBuf (tabulate m 1000 (fn i => i) Int)));
