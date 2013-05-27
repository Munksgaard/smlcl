signature SMLCL = sig
  type 'a T;
  type machine;
  type 'a buf;

  type index;
  type 'a expr

  type ('a, 'r)kern1
  type ('a1, 'a2, 'r)kern2

  exception OpenCL

  val Int : int T;
  val Real : real T;

  val init : unit -> machine;

  val mkKern1 : machine -> string -> ((index -> 'a expr) -> 'r expr)
                -> 'a T -> 'r T -> ('a, 'r)kern1;
  val mkKern2 : machine -> string -> ((index -> 'a expr) * (index -> 'b expr)
                                      -> 'r expr)
                -> ('a T * 'b T) -> 'r T -> ('a,'b,'r)kern2;

  val mkBuf : machine -> 'a T -> 'a array -> 'a buf;
  val readBuf : 'a buf -> 'a array;
  val writeBuf : 'a array -> 'a buf -> 'a buf;

  val kcall1 : ('a, 'r)kern1 -> 'a buf -> int -> 'r buf;
  val kcall2 : ('a, 'b, 'c)kern2 -> ('a buf * 'b buf) -> int -> 'c buf;

  val This : index;
  val Index : int -> index;
  val Offset : int -> index;

  val IntC : int -> int expr;
  val RealC : real -> real expr;
  val Add : 'a expr -> 'a expr -> 'a expr;
  val Sub : 'a expr -> 'a expr -> 'a expr;
  val Mul : 'a expr -> 'a expr -> 'a expr;
  val Div : 'a expr -> 'a expr -> 'a expr;

  val Eq : 'a expr -> 'a expr -> bool expr;
  val And : bool expr -> bool expr -> bool expr;
  val Or : bool expr -> bool expr -> bool expr;
  val Not : bool expr -> bool expr;

  val IntToReal : int expr -> real expr;
  val RealToInt : real expr -> int expr;

  type ('a, 'c)src1;
  type ('a, 'b, 'c)src2;
  val compile1 : ((index -> 'a expr) -> 'r expr) -> 'a T -> 'r T -> string
                 -> ('a, 'r)src1;
  val compile2 : ((index -> 'a expr) * (index -> 'b expr) -> 'r expr)
                 -> ('a T * 'b T) -> 'r T -> string -> ('a, 'b, 'r)src2;
  val src1toString : ('a, 'r)src1 -> string;
  val src2toString : ('a, 'b, 'r)src2 -> string;

end;
