structure SmlCL :> SMLCL = struct

  type machine = PrimCL.machine;
  type kernel = PrimCL.kernel;
  type 'a bufP = PrimCL.bufP;
  type sz = int;
  datatype 'a T = Int_ of (machine * 'a array -> 'a bufP)
                          * (machine * sz * 'a bufP -> 'a array)
                          * (machine * 'a bufP * 'a array -> bool)
                | Real_ of (machine * 'a array -> 'a bufP)
                           * (machine * sz * 'a bufP -> 'a array)
                           * (machine * 'a bufP * 'a array -> bool);
  type 'a buf = 'a T * sz * 'a bufP * machine;

  type ('a, 'r)kern1 = machine * kernel * string * 'r T * string;
  type ('a1, 'a2, 'r)kern2 = machine * kernel * string * 'r T * string;

  type ('a, 'c)src1 = string;
  type ('a, 'b, 'c)src2 = string;

  datatype primExpr = TriExpr of triOp * primExpr * primExpr * primExpr
                    | BinExpr of binOp * primExpr * primExpr
                    | UnExpr of unOp * primExpr
                    | ConstInt of int
                    | ConstReal of real
                    | Buf1Expr of index
                    | Buf2Expr of index

       and triOp = OpIf

       and binOp = OpEq | OpAnd | OpAdd | OpSub | OpMul | OpDiv | OpOr

       and unOp = OpNot | OpIntToReal | OpRealToInt

       and 'a expr = Expr of primExpr

       and index = This
                 | OpIndex of primExpr
                 | OpOffset of primExpr

  exception OpenCL;

  fun init () = let val m = PrimCL.init ()
                in case m of
                       NONE => raise OpenCL
                     | SOME x => x
                end;

  fun mkBufInt (m, arr) =
      PrimCL.mkBufInt (m, PrimCL.intSize, Array.length arr, arr);
  fun mkBufReal (m, arr) =
      PrimCL.mkBufReal (m, PrimCL.realSize, Array.length arr, arr);

  fun readIntBuf (m, n, b) =
      let val arr = Array.array(n, 0) in
          if PrimCL.readIntBuf (m, PrimCL.intSize, n, b, arr) then
              arr
          else
              raise Fail "Something went wrong"
      end;

  fun readRealBuf (m, n, b) =
      let val arr = Array.array(n, 0.0) in
          if PrimCL.readRealBuf (m, PrimCL.realSize, n, b, arr) then
              arr
          else
              raise Fail "Something went wrong"
      end;

  fun writeIntBuf (m, b, a) =
      PrimCL.writeIntBuf (m, PrimCL.intSize, b, a);
  fun writeRealBuf (m, b, a) =
      PrimCL.writeRealBuf (m, PrimCL.realSize, b, a);

  val Int = Int_(mkBufInt, readIntBuf, writeIntBuf);
  val Real = Real_(mkBufReal, readRealBuf, writeRealBuf);

  fun mkBuf m (t as Int_(f, _, _)) arr =
      (t, Array.length arr, f (m, arr), m)
    | mkBuf m (t as Real_(f, _, _)) arr =
      (t, Array.length arr, f (m, arr), m);

  fun readBuf (Int_ (_, f, _), n, b, m) = f (m, n, b)
    | readBuf (Real_ (_, f, _), n, b, m) = f (m, n, b);

  fun writeBuf arr (t as Int_ (_, _, f), n, b, m) =
      if Array.length arr <= n then
          if f (m, b, arr) then
              (t, Array.length arr, b, m)
          else
              raise OpenCL
      else
          raise Fail "buffer not big enough"
    | writeBuf arr (t as Real_ (_, _, f), n, b, m) =
      if Array.length arr <= n then
          if f (m, b, arr) then
              (t, Array.length arr, b, m)
          else
              raise OpenCL
      else
          raise Fail "buffer not big enough";

  val mkBufEmpty = PrimCL.mkBufEmpty;

  fun kcall1 (m, k, name, rt, src) (t1, sz1, bp1, _) worksize =
      case rt of
          Int_ (_, _, _) => let val rbuf = mkBufEmpty (m, PrimCL.intSize,
                                                       worksize);
                             val _ = PrimCL.kcall1 (m, k, worksize, bp1, rbuf)
                         in (rt, worksize, rbuf, m) end
        | Real_ (_, _, _) => let val rbuf = mkBufEmpty (m, PrimCL.realSize,
                                                        worksize);
                              val _ = PrimCL.kcall1 (m, k, worksize, bp1, rbuf)
                          in (rt, worksize, rbuf, m) end;

  fun kcall2 (m, k, name, rt, src)
             ((t1, sz1, bp1, _), (t2, sz2, bp2, _))
             worksize =
      case rt of
          Int_ (_, _, _) => let val rbuf = mkBufEmpty (m, PrimCL.intSize,
                                                       worksize);
                             val _ = PrimCL.kcall2 (m, k, worksize, bp1, bp2, rbuf)
                         in (rt, worksize, rbuf, m) end
        | Real_ (_, _, _) => let val rbuf = mkBufEmpty (m, PrimCL.realSize,
                                                        worksize);
                              val _ = PrimCL.kcall2 (m, k, worksize, bp1, bp2, rbuf)
                          in (rt, worksize, rbuf, m) end;

  fun Index (Expr e) = OpIndex e;
  fun Offset (Expr e) = OpOffset e;

  fun IntC n = Expr (ConstInt n);
  fun RealC n = Expr (ConstReal n);
  fun Add (Expr x) (Expr y) = Expr (BinExpr (OpAdd, x, y));
  fun Sub (Expr x) (Expr y) = Expr (BinExpr (OpSub, x, y));
  fun Mul (Expr x) (Expr y) = Expr (BinExpr (OpMul, x, y));
  fun Div (Expr x) (Expr y) = Expr (BinExpr (OpDiv, x, y));

  val True = Expr (ConstInt 1);
  val False = Expr (ConstInt 0);
  fun And (Expr x) (Expr y) = Expr (BinExpr (OpAnd, x, y));
  fun Or (Expr x) (Expr y) = Expr (BinExpr (OpOr, x, y));
  fun Eq (Expr x) (Expr y) = Expr (BinExpr (OpEq, x, y));
  fun Not (Expr x) = Expr (UnExpr (OpNot, x));

  fun If (Expr x) (Expr y) (Expr z) = Expr (TriExpr (OpIf, x, y, z));

  fun IntToReal (Expr x) = Expr (UnExpr (OpIntToReal, x));
  fun RealToInt (Expr x) = Expr (UnExpr (OpRealToInt, x));

  fun Buf1 (_: 'a T) i : 'a expr = Expr (Buf1Expr i);
  fun Buf2 (_: 'a T) i : 'a expr = Expr (Buf2Expr i);

  fun parens s = "(" ^ s ^ ")"

  local
    fun indexStr This = "iGID"
      | indexStr (OpIndex e) = expr e
      | indexStr (OpOffset e) = "iGID + " ^ expr e

    and unop OpNot e = "!" ^ parens (expr e)
      | unop OpIntToReal e = "(real)" ^ parens (expr e)
      | unop OpRealToInt e = "(int)" ^ parens (expr e)

    and binop OpEq e1 e2 = parens (expr e1 ^ " == " ^ expr e2)
      | binop OpOr e1 e2 = parens (expr e1 ^ " || " ^ expr e2)
      | binop OpAnd e1 e2 = parens (expr e1 ^ " && " ^ expr e2)
      | binop OpAdd e1 e2 = parens (expr e1 ^ " + " ^ expr e2)
      | binop OpSub e1 e2 = parens (expr e1 ^ " - " ^ expr e2)
      | binop OpMul e1 e2 = parens (expr e1 ^ " * " ^ expr e2)
      | binop OpDiv e1 e2 = parens (expr e1 ^ " / " ^ expr e2)

    and triop OpIf c e1 e2 = parens (expr c ^ " ? " ^ expr e1 ^ " : " ^ expr e2)

    and expr (ConstInt n) = Int.toString n
      | expr (ConstReal r) = Real.toString r
      | expr (UnExpr (ope, e)) = unop ope e
      | expr (BinExpr (ope, e1, e2)) = binop ope e1 e2
      | expr (TriExpr (ope, c, e1, e2)) = triop ope c e1 e2
      | expr (Buf1Expr i) = "buf1[" ^ indexStr i ^ "]"
      | expr (Buf2Expr i) = "buf2[" ^ indexStr i ^ "]"

    fun clType (Real_ _) n = "__global const double* buf" ^ Int.toString n ^ ",\n"
      | clType (Int_ _) n = "__global const int* buf" ^ Int.toString n ^ ",\n";

    fun rType (Real_ _) = "__global double* bufr) {\n"
      | rType (Int_ _) = "__global int* bufr) {\n";

    fun expr1 f t1 r s =
        case f (Buf1 t1) of
            Expr e => expr e
    fun expr2 f (t1, t2) r s =
        case f (Buf1 t1, Buf2 t2) of
            Expr e => expr e
  in
      fun compile1 f t1 r s =
          let
              val src = expr1 f t1 r s
          in
              "#pragma OPENCL EXTENSION cl_khr_fp64 : enable\n__kernel void "
              ^ s ^ "(\n" ^ clType t1 1 ^ rType r
              ^ "int iGID = get_global_id(0);\nbufr[iGID] = " ^ src ^ ";\n}\n"
          end;
      fun compile2 f (t1, t2) r s =
          let
              val src = expr2 f (t1, t2) r s
          in
              "#pragma OPENCL EXTENSION cl_khr_fp64 : enable\n__kernel void "
              ^ s ^ "(\n" ^ clType t1 1 ^ clType t2 2 ^ rType r
              ^ "int iGID = get_global_id(0);\nbufr[iGID] = " ^ src ^ ";\n}\n"
          end;
  end;

  fun mkKern1 m name f t1 rt =
      let val src = compile1 f t1 rt name
          val k = PrimCL.compile (m, name, src)
      in
          case k of
              NONE => raise OpenCL
            | SOME x => (m, x, name, rt, src)
      end;

  fun mkKern2 m name f (t1, t2) rt =
      let val src = compile2 f (t1, t2) rt name
          val k = PrimCL.compile (m, name, src)
      in
          case k of
              NONE => raise OpenCL
            | SOME x => (m, x, name, rt, src)
      end;

  fun kern1src (_, _, _, _, src) = src;
  fun kern2src (_, _, _, _, src) = src;

end;
