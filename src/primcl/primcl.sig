signature PRIMCL = sig
  type machine;
  type kernel;
  type bufP;

  type sz;
  val intSize : sz;
  val realSize : sz;

  val mkBufInt : machine * sz * int * int array -> bufP option;
  val mkBufReal : machine * sz * int * real array -> bufP option;
  val mkBufEmpty : machine * sz * int -> bufP option;

  val readIntBuf : machine * sz * int * bufP * int array -> bool;
  val readRealBuf : machine * sz * int * bufP * real array -> bool;

  val writeIntBuf : machine * sz * bufP * int array -> bool;
  val writeRealBuf : machine * sz * bufP * real array -> bool;

  val init : unit -> machine option;
  val compile : machine * string * string -> kernel option

  val kcall1 : machine * kernel * int * bufP * bufP -> bool;
  val kcall2 : machine * kernel * int * bufP * bufP * bufP -> bool;

  val freeBuf : bufP -> bool;
  val cleanKern : kernel -> bool;
  val cleanMachine : machine -> bool;

end;
