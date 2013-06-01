signature UTILS = sig
    val rarr2list : real array -> real list;
    val iarr2list : int array -> int list;

    val printRList : real list -> unit;
    val printIList : int list -> unit;

    val randInt : unit -> int;
    val randReal : unit -> real;
    val randIList : int -> int list;
    val randRList : int -> real list;

    val dotimes : ('a -> unit) -> 'a -> int -> unit;

    val benchmark : (unit -> 'a) -> LargeInt.int;
end;

structure Utils : UTILS = struct
  open Timer;
  val rarr2list : real array -> real list = Array.foldr (fn (x, xs) => x :: xs) []
  val iarr2list : int array -> int list = Array.foldr (fn (x, xs) => x :: xs) []

  val printRList = app (fn x => print ((Real.toString x) ^ "\n"))
  val printIList = app (fn x => print ((Int.toString x) ^ "\n"))

  val _ = MLton.Random.srand (valOf (MLton.Random.seed()));

  fun randInt () =
      let (* val _ = print (Int.toString Word.wordSize ^ "\n") *)
          val w = MLton.Random.rand()
          (* val _ = print (Word.toString w ^ "\n") *)
          val s = (Word.>> (w, Word.fromInt 16))
          (* val _ = print (Word.toString s ^ "\n") *)
          val i = Word.toInt s;
      (* val _ = print (Int.toString i ^ "\n") *)
      in i end;

  fun randReal () =
      let val max = 65536.0;
          val i = randInt ();
      in real i / max end;

  fun randIList 0 = []
    | randIList n = randInt () :: randIList (n-1);

  fun randRList 0 = []
    | randRList n = randReal () :: randRList (n-1);

  fun dotimes _ _ 0 = ()
    | dotimes f x n = (f x; dotimes f x (n-1));

  fun benchmark f =
      let val t1 = Timer.startCPUTimer();
          val _ = f ();
          val t2 = Timer.checkCPUTimer t1;
      in
          Time.toMilliseconds (#usr t2)
      end;
end;
