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

  val toBuf : 'a array -> 'a buf -> 'a buf

  val kcall2 : ('a T, 'b T, 'c T)kern2 -> ('a buf * 'b buf) -> int
               -> 'c buf;

  type ('a, 'c)src1;
  type ('a, 'b, 'c)src2;

  type index;
  val This : index;
  val Index : int -> index;
  val Offset : int -> index;

  type 'a expr
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

  val compile1 : ((index -> 'a expr) -> 'r expr) -> 'a T -> 'r T -> string
                 -> ('a, 'r)src1;
  val compile2 : ((index -> 'a expr) * (index -> 'b expr) -> 'r expr)
                 -> ('a T * 'b T) -> 'r T -> string -> ('a, 'b, 'r)src2;

  val src1toString : ('a, 'b)src1 -> string;
  val src2toString : ('a, 'b, 'c)src2 -> string;

end
