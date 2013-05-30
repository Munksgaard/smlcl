val rarr2list : real array -> real list = Array.foldr (fn (x, xs) => x :: xs) []
val iarr2list : int array -> int list = Array.foldr (fn (x, xs) => x :: xs) []

val printRList = app (fn x => print ((Real.toString x) ^ "\n"))
val printIList = app (fn x => print ((Int.toString x) ^ "\n"))

open PrimCL;

val m = valOf (init ());

val vectoradd_src = TextIO.inputAll (TextIO.openIn "vectoradd.cl")

val b1 = valOf (mkBufReal (m, realSize, 3, Array.fromList [1.0, 2.0, 3.0]));
val a1 = Array.array(3, 0.0);
val _ = readRealBuf (m, realSize, 3, b1, a1);

printRList (rarr2list a1);

val b2 = valOf (mkBufReal (m, realSize, 3, Array.fromList [9.0, 5.0, 7.0]));
val a2 = Array.array(3, 0.0);
val _ = readRealBuf (m, realSize, 3, b2, a2);
printRList (rarr2list a2);

val k = valOf (compile (m, "VectorAdd", vectoradd_src));

val rbuf = valOf (mkBufEmpty (m, realSize, 3));
val _ = kcall2 (m, k, 3, b1, b2, rbuf);

val a3 = Array.array(3, 0.0);
val _ = readRealBuf (m, realSize, 3, rbuf, a3);
printRList (rarr2list a3);

freeBuf b1;
freeBuf b2;
freeBuf rbuf;
cleanKern k;
cleanMachine m;
