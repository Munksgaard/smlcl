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
  type ('a1, 'a2, 'r)kern2 = machine * MLton.Pointer.t * string
                             * (string * 'a1) * (string * 'a2)
                             * (string * 'r) * string;

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

  fun mkKern2 m name (a1,b1) (a2, b2) (rname, r) src =
      let val k = compile (m, name, src) in
          if k = MLton.Pointer.null then
              raise OpenCL
          else
              (m, k, name, (a1,b1), (a2,b2), (rname,r), src)
      end;

  val mkBufEmpty = _import "cSclCreateBuffer" : MLton.Pointer.t * int * int
                                                * MLton.Pointer.t
                                                -> MLton.Pointer.t;

  val setBufArg = _import "cSclSetArg" : MLton.Pointer.t * int * int
                                         * MLton.Pointer.t -> unit;

  val kcall2_ = _import "cSclRun2_1" : MLton.Pointer.t * MLton.Pointer.t
                                       * int * MLton.Pointer.t
                                       * MLton.Pointer.t
                                       * MLton.Pointer.t -> bool;

  fun kcall2 (m, k, name, _, _, (r, rt), src)
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

end
