package TestFSM;

import StmtFSM :: *;
import Connectable :: *;
import GetPut :: *;

import BlueLib :: *;
import TestHelper :: *;
import MMCM_DRP_AXI :: *;
import MMCM_DRP_FSM :: *;

typedef 7 DRP_ADDR_WIDTH;
typedef 16 DRP_DATA_WIDTH;

(* synthesize *)
module [Module] mkTestFSM(TestHandler);

    let print_fmt = print_mod_pre_color_t_f;
    let print_s = print_mod_pre_color_t_s;

    Integer cLckDly = 40;

    MMCM_DRP_FSM_ifc#(DRP_ADDR_WIDTH, DRP_DATA_WIDTH) dut <- mkMMCM4E_DRP_FSM();

    Wire#(Bit#(1)) bwDWE <- mkBypassWire;
    Wire#(Bit#(1)) bwDEN <- mkBypassWire;
    Wire#(Bit#(DRP_ADDR_WIDTH)) bwDAddr <- mkBypassWire;
    Wire#(Bit#(DRP_DATA_WIDTH)) bwDI <- mkBypassWire;
    
    Wire#(Bit#(DRP_DATA_WIDTH)) dwDO <- mkDWire(0);
    Wire#(Bit#(1)) dwDRDY <- mkDWire(0);
    Wire#(Bit#(1)) dwLocked <- mkDWire(0);
    
    Reg#(Bit#(32)) rLckDly <- mkRegU;
    
    //DUT -> MMCM
    mkConnection(toGet(dut.mmcm_fab.dwe),   toPut(asReg(bwDWE)));
    mkConnection(toGet(dut.mmcm_fab.den),   toPut(asReg(bwDEN)));
    mkConnection(toGet(dut.mmcm_fab.daddr), toPut(asReg(bwDAddr)));
    mkConnection(toGet(dut.mmcm_fab.d_i),   toPut(asReg(bwDI)));
    //MMCM -> DUT
    mkConnection(toGet(asReg(dwDRDY)),      toPut(dut.mmcm_fab.drdy));
    mkConnection(toGet(asReg(dwDO)),        toPut(dut.mmcm_fab.d_o));
    mkConnection(toGet(asReg(dwLocked)),    toPut(dut.mmcm_fab.locked));

    //simple mmcm model to test DRP fsm
    Stmt mmcm = {
        seq
            delay(fromInteger(cLckDly));
            dwLocked <= 1;
            action
                await(bwDEN == 1);
                print_fmt($format("DRP access initiated: addr=0x%0X", bwDAddr), YELLOW);
            endaction
            if(bwDWE == 1) action
                $fatal(1, "DWE set for first DRP access, should be read");
            endaction
            delay(5);
            action
                //assert DRDY and DO in the same cycle
                dwDRDY <= 1;
                dwDO <= 'h0303;
            endaction
            action
                //wait for subsequent write access to DRP register
                await(bwDEN == 1 && bwDWE == 1);
                print_fmt($format("DRP write: addr=0x%0x data:0x%0x", bwDAddr, bwDI), YELLOW);
            endaction
            delay(5);
            dwDRDY <= 1;
            delay(fromInteger(cLckDly));
            dwLocked <= 1;
        endseq
    };

    FSM mmcm_fsm <- mkFSM(mmcm, clocked_by dut.mmcm_fab.dclk);

    Stmt s = {
        seq
            mmcm_fsm.start();
            print_s("Started test..", BLUE);
            action
                let req = DRP_Request { addr: 'h0A, data: 'h9090, mask: 'h7F7F };
                dut.set_drp_register(req);
            endaction
            await(dut.done());
            print_s("Done", BLUE);
        endseq
    };

    FSM main <- mkFSM(s);

    method go = main.start;
    method done = main.done;

endmodule

endpackage
