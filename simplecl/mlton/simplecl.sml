structure SimpleCL :> SIMPLECL =
struct

datatype simplecl_machine = Machine of MLton.Pointer.t;
datatype simplecl_kernel = Kernel of MLton.Pointer.t;

type machine = simplecl_machine
type kernel = simplecl_kernel

exception OpenCL

val sclInit = _import "cSclInit" : unit -> MLton.Pointer.t;
fun init () = let val machine = sclInit ();
                 in if machine = MLton.Pointer.null then
                        raise OpenCL
                    else
                        Machine machine
                 end;

val sclCompile = _import "cSclCompile" : MLton.Pointer.t * string * string
                                         -> MLton.Pointer.t;
fun compile (Machine machine, name, src) =
    let val kernel = sclCompile (machine, name, src);
    in if kernel = MLton.Pointer.null then
           raise OpenCL
       else
           Kernel kernel
    end;

val sclRun = _import "cSclRun" : MLton.Pointer.t * MLton.Pointer.t * int
                                 * real array array * real array array
                                 -> bool;
fun run (Machine machine, Kernel kernel, n, inarr, outarr) =
    if sclRun (machine, kernel, n, inarr, outarr) then
        ()
    else
        raise OpenCL

end
