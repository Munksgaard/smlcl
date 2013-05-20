structure Smlcl : SMLCL = struct

  type machine = MLton.Pointer.t;
  type 'a buffP = MLton.Pointer.t;
  type sz = int;
  datatype 'a T = Int_ of (machine * 'a array -> 'a buffP)
                          * (machine * sz * 'a buffP -> 'a array)
                          * (machine * 'a buffP * 'a array -> bool)
                | Real_ of (machine * 'a array -> 'a buffP)
                           * (machine * sz * 'a buffP -> 'a array)
                           * (machine * 'a buffP * 'a array -> bool);
  type 'a buf = 'a T * sz * 'a buffP * machine;
  type ('a1, 'a2, 'r)kern2 = machine * MLton.Pointer.t * string * 'r T * string;

  type ('a, 'c)src1 = string;
  type ('a, 'b, 'c)src2 = string;

  datatype index = This
                 | Index of int
                 | Offset of int;

  datatype primExpr = BinExpr of binOp * primExpr * primExpr
                    | UnExpr of unOp * primExpr
                    | ConstInt of int
                    | ConstReal of real
                    | Buf1Expr of index
                    | Buf2Expr of index

       and binOp = OpEq | OpAnd | OpAdd | OpSub | OpMul | OpDiv | OpOr

       and unOp = OpNot | OpIntToReal | OpRealToInt

       and 'a expr = Expr of primExpr;

  exception OpenCL;

  val init_ = _import "cSclInit" : unit -> MLton.Pointer.t;
  fun init () = let val machine = init_ ();
                in if machine = MLton.Pointer.null then
                       raise OpenCL
                   else
                       machine
                end;

  val intSize = 4;
  val realSize = 8;

  val mkBufInt =
      _import "cSclCreateBuffer" : MLton.Pointer.t * int * int
                                   * int array -> MLton.Pointer.t;
  val mkBufReal =
      _import "cSclCreateBuffer" : MLton.Pointer.t * int * int
                                   * real array -> MLton.Pointer.t;

  fun intArr2buf (m, arr) =
      mkBufInt (m, intSize, Array.length arr, arr);
  fun realArr2buf (m, arr) =
      mkBufReal (m, realSize, Array.length arr, arr);

  val fromIntBuf =
      _import "cSclReadBuffer" : MLton.Pointer.t * int * int
                                 * MLton.Pointer.t * int array -> bool;
  val fromRealBuf =
      _import "cSclReadBuffer" : MLton.Pointer.t * int * int
                                 * MLton.Pointer.t * real array -> bool;
  fun intBuf2arr (m, n, b) =
      let val arr = Array.array(n, 0) in
          if fromIntBuf (m, intSize, n, b, arr) then
              arr
          else
              raise Fail "Something went wrong"
      end;

  fun realBuf2arr (m, n, b) =
      let val arr = Array.array(n, 0.0) in
          if fromRealBuf (m, realSize, n, b, arr) then
              arr
          else
              raise Fail "Something went wrong"
      end;

  val toRealBuf =
      _import "cSclWriteBuffer" : MLton.Pointer.t * int *
                                  MLton.Pointer.t * real array -> bool;

  val toIntBuf =
      _import "cSclWriteBuffer" : MLton.Pointer.t * int *
                                  MLton.Pointer.t * int array -> bool;

  val Int = Int_(intArr2buf, intBuf2arr,
                 fn (m, b, a) => toIntBuf (m, intSize, b, a));
  val Real = Real_(realArr2buf, realBuf2arr,
                  fn (m, b, a) => toRealBuf (m, realSize, b, a));

  fun mkBuf m (t as Int_(f, _, _)) arr =
      (t, Array.length arr, f (m, arr), m)
    | mkBuf m (t as Real_(f, _, _)) arr =
      (t, Array.length arr, f (m, arr), m);

  fun fromBuf (Int_ (_, f, _), n, b, m) = f (m, n, b)
    | fromBuf (Real_ (_, f, _), n, b, m) = f (m, n, b);

  fun toBuf arr (t as Int_ (_, _, f), n, b, m) =
      if Array.length arr <= n then
          if f (m, b, arr) then
              (t, Array.length arr, b, m)
          else
              raise OpenCL
      else
          raise Fail "buffer not big enough"
    | toBuf arr (t as Real_ (_, _, f), n, b, m) =
      if Array.length arr <= n then
          if f (m, b, arr) then
              (t, Array.length arr, b, m)
          else
              raise OpenCL
      else
          raise Fail "buffer not big enough";

  val compile = _import "cSclCompile" : MLton.Pointer.t * string * string
                                        -> MLton.Pointer.t;

  val mkBufEmpty = _import "cSclCreateBuffer" : MLton.Pointer.t * int * int
                                                * MLton.Pointer.t
                                                -> MLton.Pointer.t;

  val setBufArg = _import "cSclSetArg" : MLton.Pointer.t * int * int
                                         * MLton.Pointer.t -> unit;

  val kcall2_ = _import "cSclRun2_1" : MLton.Pointer.t * MLton.Pointer.t
                                       * int * MLton.Pointer.t
                                       * MLton.Pointer.t
                                       * MLton.Pointer.t -> bool;

  fun kcall2 (m, k, name, rt, src)
             ((t1, sz1, bp1, _), (t2, sz2, bp2, _))
             worksize =
      case rt of
          Int_ (_, _, _) => let val rbuf = mkBufEmpty (m, intSize, worksize,
                                                    MLton.Pointer.null);
                             val _ = kcall2_ (m, k, worksize, bp1, bp2, rbuf)
                         in (rt, worksize, rbuf, m) end
        | Real_ (_, _, _) => let val rbuf = mkBufEmpty (m, realSize, worksize,
                                                     MLton.Pointer.null);
                              val _ = kcall2_ (m, k, worksize, bp1, bp2, rbuf)
                          in (rt, worksize, rbuf, m) end;

  fun IntC n = Expr (ConstInt n);
  fun RealC n = Expr (ConstReal n);
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

  fun src1toString src = src;
  fun src2toString src = src;

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
      | expr (Buf1Expr i) = "buf1[" ^ indexStr i ^ "]"
      | expr (Buf2Expr i) = "buf2[" ^ indexStr i ^ "]"

    fun clType (Real_ _) n = "__global const double* buf" ^ Int.toString n ^ ",\n"
      | clType (Int_ _) n = "__global const int* buf" ^ Int.toString n ^ ",\n";

    fun rType (Real_ _) = "__global const double* bufr) {\n"
      | rType (Int_ _) = "__global const int* bufr) {\n";

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
              ^ s ^ "(\n" ^ clType t1 1 ^ rType r
              ^ "int iGID = get_global_id(0);\nbufr[iGID] = " ^ src ^ ";\n}\n"
          end;
      fun compile2 f (t1, t2) r s =
          let
              val src = src2toString(expr2 f (t1, t2) r s)
          in
              "#pragma OPENCL EXTENSION cl_khr_fp64 : enable\n __kernel void "
              ^ s ^ "(\n" ^ clType t1 1 ^ clType t2 2 ^ rType r
              ^ "int iGID = get_global_id(0);\nbufr[iGID] = " ^ src ^ ";\n}\n"
          end;
  end;


  fun mkKern2 m name f (t1, t2) rt =
      let val src = compile2 f (t1, t2) rt name
          val k = compile (m, name, src)
      in
          if k = MLton.Pointer.null then
              raise OpenCL
          else
              (m, k, name, rt, src)
      end;


end;
