package BUFG;

interface BUFG_ifc;
    method Bit#(1) out();
endinterface

import "BVI" BUFG = 
module vMkBUFG(BUFG_ifc);

    default_clock clk(I);
    default_reset no_reset;

    method O out ();    

    schedule out CF out;

    path(I, O);

endmodule

module mkBUFG(BUFG_ifc);
    (* hide *)
    let _int <- vMkBUFG;
    return _int;
endmodule

endpackage