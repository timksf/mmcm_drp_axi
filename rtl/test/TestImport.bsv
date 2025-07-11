package TestImport;

import StmtFSM :: *;
import Clocks :: *;
import DefaultValue :: *;

import TestHelper :: *;
import MMCME4_ADV :: *;
import BUFG :: *;
import GLBL :: *;

(* synthesize *)
module mkDummy(Empty);
endmodule

(* synthesize *)
module [Module] mkTestImport(TestHandler);

    Clock clk_200 <- mkAbsoluteClock(0, 5000);
    Clock clk_100 <- mkAbsoluteClock(0, 10000);

    Reset mmcm_rst <- mkInitialReset(10, clocked_by clk_200);

    let glbl <- vMkGLBL;

    Wire#(Bit#(1)) clkfb <- mkWire;

    let mmcm_cfg = defaultValue;
    mmcm_cfg.p_CLKFBOUT_MULT_F = 48;
    mmcm_cfg.p_DIVCLK_DIVIDE = 6;
    mmcm_cfg.p_CLKIN1_PERIOD = 5.0;
    mmcm_cfg.p_CLKIN2_PERIOD = 10.0;
    mmcm_cfg.p_IS_RST_INVERTED = 1;
    mmcm_cfg.p_CLKOUT1_DIVIDE = 15;

    MMCME4_ADV_ifc dut <- mkMMCM4E_ADV(
        mmcm_cfg,
        clk_200,
        clk_100,
        clk_200,
        clk_200,
        clocked_by clk_200,
        reset_by mmcm_rst
    );

    BUFG_bit_ifc bufg <- mkBUFGBit(clocked_by dut.clkfbout);

    let rst <- exposeCurrentReset();
    let rst0 <- mkAsyncReset(2, rst, dut.clkout0);
    let m0 <- mkDummy(clocked_by dut.clkout0, reset_by rst0);

    rule r_default;
        dut.cddcreq(0);
        dut.clkinsel(1);
        dut.d_i(0);
        dut.daddr(0);
        dut.den(0);
        dut.dwe(0);
        dut.psen(0);
        dut.psincdec(0);
        dut.pwrdwn(0);
    endrule

    rule fb;
        dut.clkfbin(bufg.out);
    endrule

    Stmt s = seq
        $display("yo");
        delay(1000);
    endseq;

    let fsm <- mkFSM(s);

    method go = fsm.start;
    method done = fsm.done;

endmodule

endpackage