open SimpleCL;

val rarr2list = Array.foldr (fn (x, xs) => x :: xs) []

(* eliminate type warning *)
val _ = rarr2list (Array.fromList [3.0]);

val printList = app (fn x => print ((Real.toString x) ^ "\n"))

fun test () =
    let val vectoradd_src = TextIO.inputAll (TextIO.openIn "test.cl")
        val machine = SimpleCL.init ();
        val kernel = SimpleCL.compile (machine, "VectorAdd",
                                      vectoradd_src);
        val array_1 = Array.fromList [2.0, 3.1, 5.2];
        val array_2 = Array.fromList [3.5, 2.1, 2.0];
        val array_out = Array.array(3, 0.0);
        val res = SimpleCL.run (machine, kernel, 3,
                              Array.fromList[array_1, array_2],
                              Array.fromList[array_out]);
    in
        printList (rarr2list array_out)
    end;

test ();
