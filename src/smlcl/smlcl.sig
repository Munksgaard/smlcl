signature SMLCL = sig
  type machine;
  type 'a T;
  type 'a buf;
  type ('a1, 'a2, 'r)kern2

  exception OpenCL

  val Int : int T;
  val Real : real T;

  val init : unit -> machine;

  val mkKern2 : machine -> string -> (string*'a) -> (string * 'b)
                -> (string * 'c) -> string -> ('a,'b,'c)kern2;

  val mkBuf : machine -> 'a T -> 'a array -> 'a buf;

  val fromBuf : 'a buf -> 'a array;

  (* val toBuf : 'a array -> 'a buf -> unit *)

  val kcall2 : ('a T, 'b T, 'c T)kern2 -> ('a buf * 'b buf) -> int
               -> 'c buf;

end
