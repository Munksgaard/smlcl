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
  val kcall2 : ('a, 'b, 'r)kern2 -> ('a buf * 'b buf) -> int -> 'r buf;

  val map : machine -> ('a expr -> 'r expr) -> 'a T -> 'r T -> ('a, 'r)kern1;
  val red : ('a expr * 'r expr -> 'r expr) -> 'r expr -> 'a buf -> 'r T -> 'r;
  val iter : machine -> (int expr * 'a expr -> 'a expr) -> 'a T -> (int * int) -> ('a,'a)kern1;

  val This : index;
  val Index : int expr -> index;
  val Offset : int expr -> index;

  val IntC : int -> int expr;
  val RealC : real -> real expr;
  val Add : 'a expr -> 'a expr -> 'a expr;
  val Sub : 'a expr -> 'a expr -> 'a expr;
  val Mul : 'a expr -> 'a expr -> 'a expr;
  val Div : 'a expr -> 'a expr -> 'a expr;

  val True : bool expr;
  val False : bool expr;
  val Eq : 'a expr -> 'a expr -> bool expr;
  val And : bool expr -> bool expr -> bool expr;
  val Or : bool expr -> bool expr -> bool expr;
  val Not : bool expr -> bool expr;
  val Lt : 'a expr -> 'a expr -> bool expr;
  val Gt : 'a expr -> 'a expr -> bool expr;
  val Leq : 'a expr -> 'a expr -> bool expr;
  val Geq : 'a expr -> 'a expr -> bool expr;

  val If : bool expr -> 'a expr -> 'a expr -> 'a expr;

  val IntToReal : int expr -> real expr;
  val RealToInt : real expr -> int expr;

  val kern1src : ('a, 'c)kern1 -> string;
  val kern2src : ('a, 'b, 'c)kern2 -> string;

  val freeBuf : 'a buf -> unit;
  val cleanKern1 : ('a, 'b)kern1 -> unit;
  val cleanKern2 : ('a, 'b, 'c)kern2 -> unit;
  val cleanMachine : machine -> unit;

end;
