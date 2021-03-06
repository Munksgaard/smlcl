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
                    | BufrExpr of index
                    | Variable of string

       and triOp = OpIf

       and binOp = OpEq | OpAnd | OpAdd | OpSub | OpMul | OpDiv | OpOr | OpLt
                   | OpGt | OpLeq | OpGeq

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
      case PrimCL.mkBufInt (m, PrimCL.intSize, Array.length arr, arr) of
          NONE => raise Fail "Error creating buffer"
        | SOME x => x;

  fun mkBufReal (m, arr) =
      case PrimCL.mkBufReal (m, PrimCL.realSize, Array.length arr, arr) of
          NONE => raise Fail "Error creating buffer"
        | SOME x => x;

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

  fun mkBufEmpty x = case PrimCL.mkBufEmpty x of
                         NONE => raise Fail "Error creating buffer"
                       | SOME x => x;

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

  fun freeBuf (_, _, b, m) = if PrimCL.freeBuf b then
                                 ()
                             else
                                 raise Fail "Error trying to free buffer";

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
  fun Lt (Expr x) (Expr y) = Expr (BinExpr (OpLt, x, y));
  fun Gt (Expr x) (Expr y) = Expr (BinExpr (OpGt, x, y));
  fun Leq (Expr x) (Expr y) = Expr (BinExpr (OpLeq, x, y));
  fun Geq (Expr x) (Expr y) = Expr (BinExpr (OpGeq, x, y));

  fun If (Expr x) (Expr y) (Expr z) = Expr (TriExpr (OpIf, x, y, z));

  fun IntToReal (Expr x) = Expr (UnExpr (OpIntToReal, x));
  fun RealToInt (Expr x) = Expr (UnExpr (OpRealToInt, x));

  fun Var s = Expr (Variable s)
  fun Buf1 (_: 'a T) i : 'a expr = Expr (Buf1Expr i);
  fun Buf2 (_: 'a T) i : 'a expr = Expr (Buf2Expr i);
  fun Bufr (_: 'a T) i : 'a expr = Expr (BufrExpr i);

  fun parens s = "(" ^ s ^ ")"

  local
    fun indexStr This = "iGID"
      | indexStr (OpIndex e) = expr e
      | indexStr (OpOffset e) = "iGID + " ^ expr e

    and unop OpNot e = "!" ^ parens (expr e)
      | unop OpIntToReal e = "(double)" ^ parens (expr e)
      | unop OpRealToInt e = "(int)" ^ parens (expr e)

    and binop OpEq e1 e2 = parens (expr e1 ^ " == " ^ expr e2)
      | binop OpOr e1 e2 = parens (expr e1 ^ " || " ^ expr e2)
      | binop OpAnd e1 e2 = parens (expr e1 ^ " && " ^ expr e2)
      | binop OpAdd e1 e2 = parens (expr e1 ^ " + " ^ expr e2)
      | binop OpSub e1 e2 = parens (expr e1 ^ " - " ^ expr e2)
      | binop OpMul e1 e2 = parens (expr e1 ^ " * " ^ expr e2)
      | binop OpDiv e1 e2 = parens (expr e1 ^ " / " ^ expr e2)
      | binop OpLt e1 e2 = parens (expr e1 ^ " < " ^ expr e2)
      | binop OpGt e1 e2 = parens (expr e1 ^ " > " ^ expr e2)
      | binop OpLeq e1 e2 = parens (expr e1 ^ " <= " ^ expr e2)
      | binop OpGeq e1 e2 = parens (expr e1 ^ " >= " ^ expr e2)

    and triop OpIf c e1 e2 = parens (expr c ^ " ? " ^ expr e1 ^ " : " ^ expr e2)

    and expr (ConstInt n) = Int.toString n
      | expr (ConstReal r) = Real.toString r
      | expr (UnExpr (ope, e)) = unop ope e
      | expr (BinExpr (ope, e1, e2)) = binop ope e1 e2
      | expr (TriExpr (ope, c, e1, e2)) = triop ope c e1 e2
      | expr (Buf1Expr i) = "buf1[" ^ indexStr i ^ "]"
      | expr (Buf2Expr i) = "buf2[" ^ indexStr i ^ "]"
      | expr (BufrExpr i) = "bufr[" ^ indexStr i ^ "]"
      | expr (Variable s) = s

    fun ctype (Real_ _) = "double"
      | ctype (Int_ _) = "int";

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
              "#pragma OPENCL EXTENSION cl_khr_fp64 : enable\n"
              ^ "\n"
              ^ "__kernel void " ^ s ^ "(__global " ^ ctype t1 ^ "* buf1,\n"
              ^ "                        __global " ^ ctype r ^ "* bufr) {\n"
              ^ "  int iGID = get_global_id(0);\n"
              ^ "  bufr[iGID] = " ^ src ^ ";\n"
              ^ "}\n"
          end;
      fun compile2 f (t1, t2) r s =
          let
              val src = expr2 f (t1, t2) r s
          in
              "#pragma OPENCL EXTENSION cl_khr_fp64 : enable\n\n"
              ^ "__kernel void " ^ s ^ "(__global " ^ ctype t1 ^ "* buf1,\n"
              ^ "                        __global " ^ ctype t2 ^ "* buf2,\n"
              ^ "                        __global " ^ ctype r ^ "* bufr) {\n"
              ^ "  int iGID = get_global_id(0);\n"
              ^ "  bufr[iGID] = " ^ src ^ ";\n"
              ^ "}\n"
          end;

      fun map m f t1 t2 =
          let val src = compile1 (fn b => f (b This)) t1 t2 "map"
          in case PrimCL.compile (m, "map", src) of
                          NONE => raise OpenCL
                        | SOME x => (m, x, "map", t2, src)
          end

      fun red f a (b as (t1, n, _, m)) rt =
          let val exp = case f (Buf1 t1 (Index (Var "i")), Var "acc") of
                            Expr e => expr e;
              val acc = case a of
                            Expr e => expr e;
              val src1 = "#pragma OPENCL EXTENSION cl_khr_fp64 : enable\n"
                       ^ "\n"
                       ^ "__kernel void reduce1(__global " ^ ctype t1 ^ "* buf1,\n"
                       ^ "                      __global int* buf2,\n"
                       ^ "                      __global " ^ ctype rt ^ "* bufr) {\n"
                       ^ "  int length = buf2[0];\n"
                       ^ "  int iGID = get_global_id(0);\n"
                       ^ "  int global_size = get_global_size(0);\n"
                       ^ "\n"
                       ^ "  int i;\n"
                       ^ "\n"
                       ^ "  " ^ ctype rt ^ " acc = " ^ acc ^ ";\n"
                       ^ "  for (i=iGID; i<length; i = i + global_size) {\n"
                       ^ "    acc = " ^ exp ^ ";\n"
                       ^ "  }\n"
                       ^ "  bufr[iGID] = acc;\n"
                       ^ "}\n\n";
              val src2 =  "#pragma OPENCL EXTENSION cl_khr_fp64 : enable\n"
                       ^ "\n"
                       ^ "__kernel void reduce2(__global " ^ ctype t1 ^ "* buf1,\n"
                       ^ "                      __global int* buf2,\n"
                       ^ "                      __global " ^ ctype rt ^ "* bufr) {\n"
                       ^ "  int length = buf2[0];\n"
                       ^ "  int iGID = get_global_id(0);\n"
                       ^ "  int global_size = get_global_size(0);\n"
                       ^ "\n"
                       ^ "  int i;\n"
                       ^ "\n"
                       ^ "  " ^ ctype rt ^ " acc = " ^ acc ^ ";\n"
                       ^ "  for (i=0; i<length && i<256; i++) {\n"
                       ^ "    acc = " ^ exp ^ ";\n"
                       ^ "  }\n"
                       ^ "  bufr[0] = acc;\n"
                       ^ "}\n\n";
              val k1 = case PrimCL.compile (m, "reduce1", src1) of
                           NONE => raise OpenCL
                         | SOME x => (m, x, "reduce1", rt, src1);
              val k2 = case PrimCL.compile (m, "reduce2", src2) of
                           NONE => raise OpenCL
                         | SOME x => (m, x, "reduce2", rt, src2);
              val lenb = mkBuf m Int (Array.fromList [n]);
              val rbuf1 = kcall2 k1 (b, lenb) 256;
              val rbuf2 = kcall2 k2 (rbuf1, lenb) 1;
              val arr = readBuf rbuf2;
              val _ = freeBuf rbuf1;
              val _ = freeBuf rbuf2;
              val _ = freeBuf lenb;

          in
              Array.sub (arr, 0)
          end;

      fun tabulate m n f rt =
          let val exp = case f (Var "iGID") of
                            Expr e => expr e;
              val src1 = "#pragma OPENCL EXTENSION cl_khr_fp64 : enable\n"
                       ^ "\n"
                       ^ "__kernel void tabulate(__global int* buf1,\n"
                       ^ "                       __global " ^ ctype rt ^ "* bufr) {\n"
                       ^ "  int length = buf1[0];\n"
                       ^ "  int iGID = get_global_id(0);\n"
                       ^ "  int global_size = get_global_size(0);\n"
                       ^ "\n"
                       ^ "  bufr[iGID] = " ^ exp ^ ";\n"
                       ^ "}\n\n";
              val k = case PrimCL.compile (m, "tabulate", src1) of
                           NONE => raise OpenCL
                         | SOME x => (m, x, "tabulate", rt, src1);
              val lenb = mkBuf m Int (Array.fromList [n]);
          in
              kcall1 k lenb n
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

  fun cleanKern1 (_, k, _, _ ,_) =
      if PrimCL.cleanKern k
      then ()
      else raise Fail "Error trying to cleanup kernel";

  fun cleanKern2 (_, k, _, _ ,_) =
      if PrimCL.cleanKern k
      then ()
      else raise Fail "Error trying to cleanup kernel";

  fun cleanMachine m =
      if PrimCL.cleanMachine m
      then ()
      else raise Fail "Error trying to cleanup machine";

end;
