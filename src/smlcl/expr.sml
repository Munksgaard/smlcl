signature EXPR = sig

  type 'a T;
  type ('a, 'c)src1;
  type ('a, 'b, 'c)src2;

  val RealT : real T;
  val IntT : int T;

  type index;
  val This : index;
  val Index : int -> index;
  val Offset : int -> index;

  type 'a expr
  val Int : int -> int expr;
  val Real : real -> real expr;
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

end;

structure Expr :> EXPR = struct

  datatype index = This
                 | Index of int
                 | Offset of int;

  datatype 'a T = RealT | IntT;
  type ('a, 'c)src1 = string;
  type ('a, 'b, 'c)src2 = string;

  datatype primExpr = BinExpr of binOp * primExpr * primExpr
                    | UnExpr of unOp * primExpr
                    | ConstInt of int
                    | ConstReal of real
                    | Buf1Expr of index
                    | Buf2Expr of index
       and binOp = OpEq | OpAnd | OpAdd | OpSub | OpMul | OpDiv | OpOr
       and unOp = OpNot | OpIntToReal | OpRealToInt

  and 'a expr = Expr of primExpr

  fun Int n = Expr (ConstInt n);
  fun Real n = Expr (ConstReal n);
  fun Add (Expr x) (Expr y) = Expr (BinExpr (OpAdd, x, y));
  fun Sub (Expr x) (Expr y) = Expr (BinExpr (OpSub, x, y));
  fun Mul (Expr x) (Expr y) = Expr (BinExpr (OpMul, x, y));
  fun Div (Expr x) (Expr y) = Expr (BinExpr (OpDiv, x, y));

  fun And (Expr x) (Expr y) = Expr (BinExpr (OpAnd, x, y));
  fun Or (Expr x) (Expr y) = Expr (BinExpr (OpOr, x, y));
  fun Eq (Expr x) (Expr y) = Expr (BinExpr (OpEq, x, y));
  fun Not (Expr x) = Expr (UnExpr (OpNot, x));

  fun IntToReal (Expr x) = Expr (UnExpr (OpIntToReal, x));
  fun RealToInt (Expr x) = Expr (UnExpr (OpRealToInt, x));

  fun Buf1 (_: 'a T) i : 'a expr = Expr (Buf1Expr i);
  fun Buf2 (_: 'a T) i : 'a expr = Expr (Buf2Expr i);

  fun parens s = "(" ^ s ^ ")"

  local
    fun indexStr This = "iGID"
      | indexStr (Index n) = Int.toString n
      | indexStr (Offset n) = "iGID + " ^ Int.toString n;

    fun unop OpNot e = "!" ^ parens (expr e)
      | unop OpIntToReal e = "(real)" ^ parens (expr e)
      | unop OpRealToInt e = "(int)" ^ parens (expr e)

    and binop OpEq e1 e2 = parens (expr e1 ^ " == " ^ expr e2)
      | binop OpOr e1 e2 = parens (expr e1 ^ " || " ^ expr e2)
      | binop OpAnd e1 e2 = parens (expr e1 ^ " && " ^ expr e2)
      | binop OpAdd e1 e2 = parens (expr e1 ^ " + " ^ expr e2)
      | binop OpSub e1 e2 = parens (expr e1 ^ " - " ^ expr e2)
      | binop OpMul e1 e2 = parens (expr e1 ^ " * " ^ expr e2)
      | binop OpDiv e1 e2 = parens (expr e1 ^ " / " ^ expr e2)

    and expr (ConstInt n) = Int.toString n
      | expr (ConstReal r) = Real.toString r
      | expr (UnExpr (ope, e)) = unop ope e
      | expr (BinExpr (ope, e1, e2)) = binop ope e1 e2
      | expr (Buf1Expr i) = "buf0[" ^ indexStr i ^ "]"
      | expr (Buf2Expr i) = "buf1[" ^ indexStr i ^ "]"

    fun clType RealT n = "__global const double* buf" ^ Int.toString n ^ ",\n"
      | clType IntT n = "__global const int* buf" ^ Int.toString n ^ ",\n";

    fun rType RealT = "__global const double* bufr) {\n"
      | rType IntT = "__global const int* bufr) {\n";

    fun expr1 f t1 r s =
        case f (Buf1 t1) of
            Expr e => expr e
    fun expr2 f (t1, t2) r s =
        case f (Buf1 t1, Buf2 t2) of
            Expr e => expr e
  in
      fun compile1 f t1 r s =
          let
              val src = src1toString(expr1 f t1 r s)
          in
              "#pragma OPENCL EXTENSION cl_khr_fp64 : enable\n __kernel void "
              ^ s ^ "(\n" ^ clType t1 0 ^ rType r
              ^ "int iGID = get_global_id(0);\nbufr[iGID] = " ^ src ^ ";\n}\n"
          end;
      fun compile2 f (t1, t2) r s =
          let
              val src = src2toString(expr2 f (t1, t2) r s)
          in
              "#pragma OPENCL EXTENSION cl_khr_fp64 : enable\n __kernel void "
              ^ s ^ "(\n" ^ clType t1 0 ^ clType t1 1 ^ rType r
              ^ "int iGID = get_global_id(0);\nbufr[iGID] = " ^ src ^ ";\n}\n"
          end;
  end;

  fun src1toString src = src;
  fun src2toString src = src;

end;
