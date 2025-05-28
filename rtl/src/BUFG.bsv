package BUFG;

interface BUFG_ifc;
    method Bit#(1) out();
    method Action in(Bit#(1) i);
endinterface

import "BVI" BUFG = 
module vMkBUFG(BUFG_ifc);

    default_clock clk();
    default_reset no_reset;

    method in(I) enable((*inhigh*) EN);
    method O out ();    

    schedule (in, out) CF (in, out);

endmodule

module mkBUFG(BUFG_ifc);
    (* hide *)
    let _int <- vMkBUFG;
    return _int;
endmodule

endpackage