package TestMain;

import StmtFSM :: *;
import Connectable :: *;
import GetPut :: *;
import Clocks :: *;

import BlueLib :: *;
import TestHelper :: *;
// import MMCM_DRP_AXI :: *;
import MMCM_DRP_FSM :: *;
import ClockTester :: *;

import GLBL :: *;
import BUFG :: *;
import MMCME4_ADV :: *;

typedef 7 DRP_ADDR_WIDTH;
typedef 16 DRP_DATA_WIDTH;

(* synthesize *)
module [Module] mkTestMain(TestHandler);

    let print_fmt = print_mod_pre_color_t_f;
    let print_s = print_mod_pre_color_t_s;

    //required for simulation of Xilinx IP
    let glbl <- vMkGLBL;

    //time units are picoseconds
    Clock clk_200 <- mkAbsoluteClock(0, 5000);
    Clock clk_100 <- mkAbsoluteClock(0, 10000);
    Reset rst_200 <- mkAsyncResetFromCR(1, clk_200);
    
    ClockTester_ifc clk_test <- mkClockTester(1000, clk_200);

    let mmcm_cfg = defaultValue;
    mmcm_cfg.p_CLKFBOUT_MULT_F = 48;
    mmcm_cfg.p_DIVCLK_DIVIDE = 6;
    mmcm_cfg.p_CLKIN1_PERIOD = 5.0;
    mmcm_cfg.p_CLKIN2_PERIOD = 10.0;
    mmcm_cfg.p_IS_RST_INVERTED = 1;
    mmcm_cfg.p_CLKOUT0_DIVIDE_F = 2.0;
    
    MMCM_DRP_FSM_ifc#(DRP_ADDR_WIDTH, DRP_DATA_WIDTH) drp_fsm <- mkMMCM4E_DRP_FSM(clocked_by clk_200, reset_by rst_200);
    
    MMCME4_ADV_ifc mmcm <- mkMMCM4E_ADV(
        mmcm_cfg,
        clk_200,
        clk_100,
        clk_200,
        clk_200,
        clocked_by clk_200,
        reset_by drp_fsm.mmcm_fab.rst
    );

    BUFG_ifc bufg <- mkBUFG(clocked_by mmcm.clkfbout);

    SyncPulseIfc pStart <- mkSyncPulseFromCC(clk_200);
    SyncPulseIfc pStopped <- mkSyncPulseToCC(clk_200, rst_200);

    SyncBitIfc#(Bool) syncStarted <- mkSyncBitToCC(clk_200, rst_200);
        
    //DUT -> MMCM
    mkConnection(toGet(drp_fsm.mmcm_fab.dwe),   toPut(mmcm.dwe));
    mkConnection(toGet(drp_fsm.mmcm_fab.den),   toPut(mmcm.den));
    mkConnection(toGet(drp_fsm.mmcm_fab.daddr), toPut(mmcm.daddr));
    mkConnection(toGet(drp_fsm.mmcm_fab.d_i),   toPut(mmcm.d_i));
    //MMCM -> DUT
    mkConnection(toGet(mmcm.drdy),              toPut(drp_fsm.mmcm_fab.drdy));
    mkConnection(toGet(mmcm.d_o),               toPut(drp_fsm.mmcm_fab.d_o));
    mkConnection(toGet(mmcm.locked),            toPut(drp_fsm.mmcm_fab.locked));

    Stmt s = {
        seq 
            delay(10);
            action
                test($realtobits(2.44));
            endaction
            // print_s("Yo: " + realToString(clk_test.f_slow()), RED);
            syncStarted.send(True);
            print_s("Starting DRP simulation", YELLOW);
            action
            drp_fsm.set_drp_register(DRP_Request { 
                addr: 'h0B,                 //ClkReg2 for clkout1
                data:  0,                   //enable counter
                mask: 'hFB00                //retain counter enable bit
            });
            print_s("Setting 0xB", YELLOW);
            endaction
            action
            drp_fsm.set_drp_register(DRP_Request { 
                addr: 'h0A,                 //ClkReg1 for clkout1
                data: ('h20 << 6) | 'h20,   //set divider to 32+32=64
                mask: 'h1000                //retain counter enable bit
            });
            print_s("Setting 0xA", YELLOW);
            endaction
            await(drp_fsm.running());
            print_s("Waiting for MMCM lock...", YELLOW);
            await(drp_fsm.done());
            action
                await(unpack(mmcm.locked));
                print_s("MMCM locked", GREEN);
            endaction
            delay(5);
        endseq
    };

    FSM main <- mkFSM(s, clocked_by clk_200, reset_by rst_200);

    //tieoff unused signals
    rule tieoff;
        mmcm.cddcreq(0);
        mmcm.clkinsel(1);
        mmcm.psen(0);
        mmcm.psincdec(0);
        mmcm.pwrdwn(0);
    endrule

    //connect clk feedback through BUFG
    rule fb;
        mmcm.clkfbin(bufg.out);
    endrule
    
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
