package MMCM_DRP_AXI;

import BlueAXI :: *;
import MMCM_DRP_FSM :: *;

typedef enum {
    IDLE,
    REG0,
    REG1,
    WAIT_DONE
} FSM_State deriving(Eq, Bits);

Integer cfg_ctrl_offs   = 'h00;
Integer cfg_stat_offs   = 'h04;
Integer cfg_clksel_offs = 'h08;
Integer cfg_clkdiv_offs = 'h0C;

//bit offsets
//command register
Integer cfg_srst_bit_offs = 0;
Integer cfg_apply_bit_offs = 1; //apply settings to mmcm over DRP

//status register
Integer cfg_done_bit_offs = 0;

//internal interface to the configuration registers
interface MMCM_DRP_AXI_Cfg_ifc;

    method Action finish();

    interface ReadOnly#(Bit#(3)) clksel;
    interface ReadOnly#(Bit#(8)) clkdiv;

    interface ReadOnly#(Bool) srst;
    interface ReadOnly#(Bool) apply;

endinterface

interface MMCM_DRP_AXI_ifc#(numeric type aw, numeric type dw);

    interface MMCM_DRP_Fab_ifc#(aw, dw) mmcm_fab;

    //config interface 
    (* prefix="S_AXI_cfg" *)
    interface AXI4_Lite_Slave_Rd_Fab#(32, 32) fab_config_rd;
    (* prefix="S_AXI_cfg" *)
    interface AXI4_Lite_Slave_Wr_Fab#(32, 32) fab_config_wr;

endinterface

module [ConfigCtx#(32, 32)] mmcm_drp_axi_cfg(MMCM_DRP_AXI_Cfg_ifc);

    Reg#(Bit#(32)) rCmd <- mkReg(0);
    Reg#(Bit#(32)) rStatus <- mkReg(0);

    Reg#(Bit#(3)) rClkSel <- mkRegU;
    Reg#(Bit#(8)) rClkDiv <- mkRegU;

    //add registers to AXI interface
    addRegWO(cfg_ctrl_offs, rStatus);
    addRegRO(cfg_stat_offs, rStatus);
    addRegWO(cfg_clksel_offs, rClkSel);
    addRegWO(cfg_clkdiv_offs, rClkDiv);

    method finish = action
        let stat = rStatus;
        stat[cfg_done_bit_offs] = 1;
        rStatus <= stat;
        let cmd = rCmd;
        cmd[cfg_apply_bit_offs] = 0;
        rCmd <= cmd;
    endaction;

    interface clksel = regToReadOnly(rClkSel);
    interface clkdiv = regToReadOnly(rClkDiv);

    interface ReadOnly srst;
        method _read = unpack(rCmd[cfg_srst_bit_offs]);
    endinterface

    interface ReadOnly apply;
        method _read = unpack(rCmd[cfg_apply_bit_offs]);
    endinterface


endmodule

module [Module] mkMMCM_DRP_AXI(MMCM_DRP_AXI_ifc#(aw, dw)) 
    provisos(
        Add#(b__, 1, dw), //dw > 1
        Add#(a__, 6, dw) //dw > 6
    );

    Integer clk_addr_lut[7] = {
        'h08, 'h0A, 'h0C, 'h0E, 'h10, 'h06, 'h12
    };

    Reg#(FSM_State) rState <- mkReg(IDLE);
    Reg#(Bit#(3)) rClkSel <- mkRegU;
    Reg#(Bit#(8)) rClkDiv <- mkRegU;
    Reg#(Bit#(aw)) rAddr <- mkRegU;
    
    IntExtConfig_ifc#(32, 32, MMCM_DRP_AXI_Cfg_ifc) config_ <- axi4LiteConfigFromContext(mmcm_drp_axi_cfg);
    MMCM_DRP_FSM_ifc#(aw, dw) drp_fsm <- mkMMCM_DRP_FSM();

    rule r_srst (config_.device_ifc.srst);
        rState <= IDLE;
    endrule

    rule r_apply (config_.device_ifc.apply && rState == IDLE);
        let clksel = config_.device_ifc.clksel;
        rClkSel <= clksel;
        rClkDiv <= config_.device_ifc.clkdiv;
        rAddr <= fromInteger(clk_addr_lut[clksel]);
        rState <= REG0;
    endrule

    rule r_reg0 (rState == REG0);
        Bit#(6) htime = truncate(rClkDiv >> 1);
        Bit#(6) ltime = truncate(rClkDiv >> 1) + zeroExtend(rClkDiv[0]);
        //TODO adaptive mask from lut
        DRP_Request#(aw, dw) req = DRP_Request { addr: rAddr, data: zeroExtend(htime) << 6 | zeroExtend(ltime), mask: 'h0000 };
        drp_fsm.set_drp_register(req); //this will only fire when the DRP is ready
        rAddr <= rAddr + 1;
        rState <= REG1;
    endrule

    rule r_reg1 (rState == REG1);
        Bit#(1) edge_ = rClkDiv[0];
        Bit#(1) no_count = pack(rClkDiv == 1);
        DRP_Request#(aw, dw) req = DRP_Request { addr: rAddr, data: zeroExtend(edge_) << 7 | zeroExtend(no_count) << 6, mask: 'hFB00 };
        drp_fsm.set_drp_register(req);
        rState <= WAIT_DONE;
    endrule

    rule r_wait (rState == WAIT_DONE);
        if(drp_fsm.done()) begin
            rState <= IDLE;
            config_.device_ifc.finish();
        end
    endrule

    //config
    interface fab_config_rd = config_.bus_ifc.s_rd;
    interface fab_config_wr = config_.bus_ifc.s_wr;

endmodule

endpackage
