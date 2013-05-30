structure PrimCL :> PRIMCL = struct

  type machine = MLton.Pointer.t;
  type kernel = MLton.Pointer.t;
  type bufP = MLton.Pointer.t;

  type sz = int;
  val intSize = 4;
  val realSize = 8;

  val mkBufInt_ =
      _import "createBuffer" : machine * int * int
                                   * int array -> bufP;
  fun mkBufInt x =
      let val b = mkBufInt_ x
      in if b = MLton.Pointer.null then
             NONE
         else
             SOME b
      end;

  val mkBufReal_ =
      _import "createBuffer" : machine * int * int
                                   * real array -> bufP;
  fun mkBufReal x =
      let val b = mkBufReal_ x
      in if b = MLton.Pointer.null then
             NONE
         else
             SOME b
      end;

  val mkBufEmpty_ = _import "createBuffer" : machine * sz * int * MLton.Pointer.t
                                             -> bufP;
  fun mkBufEmpty (m, t, n) =
      let val b = mkBufEmpty_(m, t, n, MLton.Pointer.null)
      in if b = MLton.Pointer.null then
             NONE
         else
             SOME b
      end;

  val readIntBuf =
      _import "readBuffer" : machine * int * int * bufP * int array -> bool;
  val readRealBuf =
      _import "readBuffer" : machine * int * int * bufP * real array -> bool;
  val writeRealBuf =
      _import "writeBuffer" : machine * int * bufP * real array -> bool;

  val writeIntBuf =
      _import "writeBuffer" : MLton.Pointer.t * int *
                                  MLton.Pointer.t * int array -> bool;

  val init_ = _import "init" : unit -> machine;
  fun init () = let val machine = init_ ();
                in if machine = MLton.Pointer.null then
                       NONE
                   else
                       SOME machine
                end;

  val compile_ = _import "compile" : machine * string * string * int -> kernel;
  fun compile (m, name, src) =
      let val len = size src;
          val k = compile_ (m, name, src, len);
      in
          if k = MLton.Pointer.null then
              NONE
          else
              SOME k
      end;

  val kcall1 = _import "run1" : machine * kernel * int * bufP * bufP -> bool;

  val kcall2 = _import "run2" : machine * kernel * int * bufP * bufP
                                * bufP -> bool;

  val freeBuf = _import "freeBuffer" : bufP -> bool;
  val cleanKern = _import "cleanupKernel" : kernel -> bool;
  val cleanMachine = _import "cleanupMachine" : machine -> bool;

end;
