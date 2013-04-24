signature SIMPLECL =
sig
    type machine
    type kernel
    exception OpenCL
    val init : unit -> machine;
    val compile : machine * string * string -> kernel
    val run : machine * kernel * int * real array array * real array array
              -> unit
end
