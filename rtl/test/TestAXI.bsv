package TestAXI;

import StmtFSM :: *;
import Connectable :: *;
import GetPut :: *;
import Clocks :: *;

import BlueLib :: *;
import BlueAXI :: *;
import TestHelper :: *;
import MMCM_DRP_AXI :: *;
import MMCM_DRP_FSM :: *;
import ClockTester :: *;

import GLBL :: *;
import BUFG :: *;
import MMCME4_ADV :: *;

typedef 7 DRP_ADDR_WIDTH;
typedef 16 DRP_DATA_WIDTH;

(* synthesize *)
module [Module] mkTestAXI(TestHandler);

    let print_fmt = print_mod_pre_color_t_f;
    let print_s = print_mod_pre_color_t_s;

    //required for simulation of Xilinx IP
    let glbl <- vMkGLBL;

    //time units are picoseconds
    Clock clk_1GHz      <- mkAbsoluteClock(0, 1000);
    Clock clk_200MHz    <- mkAbsoluteClock(0, 5000);
    Clock clk_100       <- mkAbsoluteClock(0, 10000);
    Reset rst_200       <- mkAsyncResetFromCR(1, clk_200MHz);

    let mmcm_cfg = defaultValue;
    mmcm_cfg.p_CLKFBOUT_MULT_F  = 30;
    mmcm_cfg.p_DIVCLK_DIVIDE    = 6;
    mmcm_cfg.p_CLKIN1_PERIOD    = 5.0;
    mmcm_cfg.p_CLKIN2_PERIOD    = 10.0;
    mmcm_cfg.p_IS_RST_INVERTED  = 1;
    mmcm_cfg.p_CLKOUT0_DIVIDE_F = 2.0;
    mmcm_cfg.p_CLKOUT1_DIVIDE   = 15;
    mmcm_cfg.p_CLKOUT2_DIVIDE   = 15;
    mmcm_cfg.p_CLKOUT3_DIVIDE   = 15;
    mmcm_cfg.p_CLKOUT4_DIVIDE   = 15;
    mmcm_cfg.p_CLKOUT5_DIVIDE   = 15;
    mmcm_cfg.p_CLKOUT6_DIVIDE   = 15;

    AXI4_Lite_Master_Rd#(12, 32) m_rd <- mkAXI4_Lite_Master_Rd(1, clocked_by clk_200MHz, reset_by rst_200);
    AXI4_Lite_Master_Wr#(12, 32) m_wr <- mkAXI4_Lite_Master_Wr(1, clocked_by clk_200MHz, reset_by rst_200);
    
    //synchronization of FSM start and stop
    SyncPulseIfc        pStart          <- mkSyncPulseFromCC(clk_200MHz);
    SyncPulseIfc        pStopped        <- mkSyncPulseToCC(clk_200MHz, rst_200);
    SyncBitIfc#(Bool)   syncStarted     <- mkSyncBitToCC(clk_200MHz, rst_200);

    Reg#(Bool)                  rDone   <- mkReg(False, clocked_by clk_200MHz, reset_by rst_200);
    MMCM_DRP_AXI_ifc#(12, 32)   dut     <- mkMMCM4E_DRP_AXI(mmcm_cfg, clocked_by clk_200MHz, reset_by rst_200);

    ClockTester_ifc clk_test <- mkClockTester(1000, dut.clks[1], clocked_by clk_200MHz, reset_by rst_200);
    
    mkConnection(dut.fab_config_rd, m_rd.fab, clocked_by clk_200MHz, reset_by rst_200);
    mkConnection(dut.fab_config_wr, m_wr.fab, clocked_by clk_200MHz, reset_by rst_200);

    function Action axi4l_expect_okay(AXI4_Lite_Master_Wr#(aw, dw) m);
        action
            let rsp <- axi4_lite_write_response(m);
            if(rsp != OKAY)
                $display("Got bad response from AXI4L write master");
        endaction
    endfunction

    function Stmt axi4l_write_reg(AXI4_Lite_Master_Wr#(aw, dw) m, Bit#(aw) a, Bit#(dw) d);
        Stmt s = seq 
            axi4_lite_write(m, a, d);
            axi4l_expect_okay(m);
        endseq;
        return s;
    endfunction

    Stmt s = {
        seq 
            delay(10);
            syncStarted.send(True);
            print_s("Starting DRP AXI simulation", YELLOW);
            axi4l_write_reg(m_wr, fromInteger(cfg_clksel_offs), 1);
            axi4l_write_reg(m_wr, fromInteger(cfg_clkdiv_offs), 32);
            axi4l_write_reg(m_wr, fromInteger(cfg_ctrl_offs), 1 << cfg_apply_bit_offs | 0 << cfg_cddc_en_bit_offs);
            while(!rDone) seq
                axi4_lite_read(m_rd, fromInteger(cfg_stat_offs));
                action
                    let rsp <- axi4_lite_read_response(m_rd);
                    if(unpack(rsp[cfg_done_bit_offs])) begin
                        rDone <= True;
                    end
                endaction
            endseq
            action
                await(dut.clks_rdy[1]);
                print_s("CLK1 ready again", GREEN);
            endaction
            clk_test.restart();
            delay(30); //have to wait for at least a cycle of the slow clock
            $write("Freq: "); print_freq(clk_test.f_slow()); $display();
        endseq
    };

    FSM main <- mkFSM(s, clocked_by clk_200MHz, reset_by rst_200);

    rule start if(pStart.pulse());
        main.start();
    endrule

    rule stopped if(main.done());
        pStopped.send();
    endrule

    method go = pStart.send;
    method done = pStopped.pulse && syncStarted.read;

endmodule

endpackage
