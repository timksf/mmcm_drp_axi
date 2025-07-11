package BUFG;

interface BUFG_ifc;
    method Bit#(1) out();
endinterface

interface BUFG_bit_ifc;
    method Bit#(1) out();
endinterface

import "BVI" BUFG = 
module vMkBUFGBit(BUFG_bit_ifc);

    default_clock clk(I);
    default_reset no_reset;

    method O out ();    

    schedule out CF out;

    path(I, O);

endmodule

module mkBUFGBit(BUFG_bit_ifc);
    (* hide *)
    let _int <- vMkBUFGBit;
    return _int;
endmodule

endpackage