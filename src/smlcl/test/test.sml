val rarr2list : real array -> real list = Array.foldr (fn (x, xs) => x :: xs) []
val iarr2list : int array -> int list = Array.foldr (fn (x, xs) => x :: xs) []

val printRList = app (fn x => print ((Real.toString x) ^ "\n"))
val printIList = app (fn x => print ((Int.toString x) ^ "\n"))

open Smlcl

val m = init ();
val b1 = mkBuf m Real (Array.fromList [1.0, 2.0, 3.0]);
val a1 = fromBuf b1;

printRList (rarr2list a1);

val b2 = mkBuf m Real (Array.fromList [9.0, 5.0, 7.0]);
val a2 = fromBuf b2;
printRList (rarr2list a2);

val vectoradd_src = TextIO.inputAll (TextIO.openIn "vectoradd.cl")

val k = mkKern2 m "VectorAdd" ("", Real) ("", Real) ("", Real) vectoradd_src;

val rbuf = kcall2 k (b1, b2) 3;

val r = fromBuf rbuf;
printRList (rarr2list r);

val b3 = toBuf (Array.fromList [42.0, 43.0, 44.0]) rbuf;
val a3 = fromBuf b3;
printRList (rarr2list a3);

val b4 = toBuf (Array.fromList [11.0, 12.0]) rbuf;
val a4 = fromBuf b4;
printRList (rarr2list a4);

val b5 = (toBuf (Array.fromList [11.0, 12.0, 13.0, 14.0]) rbuf;
          print "This shouldn't happen\n") handle Fail _ => print "yes\n";
