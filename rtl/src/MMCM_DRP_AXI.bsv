package MMCM_DRP_AXI;

import Vector :: *;
import Clocks :: *;
import GetPut :: *;
import Connectable :: *;
import DefaultValue :: *;

import BlueAXI :: *;
import BUFGCE :: *;
import BUFG :: *;
import MMCME4_ADV :: *;
import MMCM_DRP_FSM :: *;
import SyncBitExt :: *;

typedef 7 NUM_CLOCKS;
typedef 7 DRP_ADDR_WIDTH;
typedef 16 DRP_DATA_WIDTH;

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
//command&ctrl register
Integer cfg_srst_bit_offs       = 0;
Integer cfg_apply_bit_offs      = 1; //apply settings to mmcm over DRP
Integer cfg_cddc_en_bit_offs    = 2;

//status register
Integer cfg_done_bit_offs = 0;

//internal interface to the configuration registers
interface MMCM_DRP_AXI_Cfg_ifc;

    method Action finish();

    interface ReadOnly#(Bit#(3)) clksel;
    interface ReadOnly#(Bit#(8)) clkdiv;

    interface ReadOnly#(Bool) srst;
    interface ReadOnly#(Bool) apply;
    interface ReadOnly#(Bool) cddc_en;

endinterface

interface MMCM_DRP_AXI_ifc#(numeric type aw, numeric type dw);

    //config interface 
    (* prefix="S_AXI_cfg" *)
    interface AXI4_Lite_Slave_Rd_Fab#(12, 32) fab_config_rd;
    (* prefix="S_AXI_cfg" *)
    interface AXI4_Lite_Slave_Wr_Fab#(12, 32) fab_config_wr;

    //output clocks
    interface Vector#(NUM_CLOCKS, ReadOnly#(Bool)) clks_rdy;
    interface Vector#(NUM_CLOCKS, Clock) clks;

endinterface

module [ConfigCtx#(12, 32)] mmcm_drp_axi_cfg(MMCM_DRP_AXI_Cfg_ifc);

    Reg#(Bit#(32))  rCmd    <- mkReg(0);
    Reg#(Bit#(32))  rStatus <- mkReg(0);
    Reg#(Bit#(3))   rClkSel <- mkRegU;
    Reg#(Bit#(8))   rClkDiv <- mkRegU;

    //add registers to AXI interface
    addRegWO(cfg_ctrl_offs, rCmd);
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

    interface ReadOnly cddc_en;
        method _read = unpack(rCmd[cfg_cddc_en_bit_offs]);
    endinterface


endmodule

module [Module] mkMMCM_DRP_AXI#(MMCME4_ADV_Config mmcm_cfg)(MMCM_DRP_AXI_ifc#(aw, dw)) 
    provisos(
        Add#(b__, 1, dw), //dw > 1
        Add#(a__, 6, dw) //dw > 6
    );

    //ToDo add two input clocks? -> sticking to one for now
    Clock clkin <- exposeCurrentClock;

    Integer clk_addr_lut[valueof(NUM_CLOCKS)] = {
        'h08, 'h0A, 'h0C, 'h0E, 'h10, 'h06, 'h12
    };

    //internal registers
    Reg#(FSM_State)                 rState      <- mkReg(IDLE);
    Reg#(Bit#(3))                   rClkSel     <- mkRegU;
    Reg#(Bit#(8))                   rClkDiv     <- mkRegU;
    Reg#(Bit#(DRP_ADDR_WIDTH))      rAddr       <- mkRegU;
    // Vector#(NUM_CLOCKS, Reg#(Bool)) vClockEn    <- replicateM(mkRegU);
    Vector#(NUM_CLOCKS, Reg#(Bool)) vClockEnS   = newVector;
    
    IntExtConfig_ifc#(12, 32, MMCM_DRP_AXI_Cfg_ifc)     config_ <- axi4LiteConfigFromContext(mmcm_drp_axi_cfg);
    MMCM_DRP_FSM_ifc#(DRP_ADDR_WIDTH, DRP_DATA_WIDTH)   drp_fsm <- mkMMCM4E_DRP_FSM();
    MMCME4_ADV_ifc                                      mmcm    <- mkMMCM4E_ADV(mmcm_cfg, clkin, clkin, clkin, clkin, reset_by drp_fsm.mmcm_fab.rst);
    BUFG_bit_ifc                                        bufg_fb <- mkBUFGBit(clocked_by mmcm.clkfbout);

    Vector#(NUM_CLOCKS, BUFGCE_ifc)  vBUFGCE        = newVector;
    Vector#(NUM_CLOCKS, Clock)       mmcm_clks      = newVector;
    Vector#(NUM_CLOCKS, Clock)       clks_out       = newVector;
    Vector#(NUM_CLOCKS, Wire#(Bool)) clks_out_rdy   = newVector;

    mmcm_clks[0] = mmcm.clkout0;
    mmcm_clks[1] = mmcm.clkout1;
    mmcm_clks[2] = mmcm.clkout2;
    mmcm_clks[3] = mmcm.clkout3;
    mmcm_clks[4] = mmcm.clkout4;
    mmcm_clks[5] = mmcm.clkout5;
    mmcm_clks[6] = mmcm.clkout6;

    //DRP FSM -> MMCM
    mkConnection(toGet(drp_fsm.mmcm_fab.dwe),       toPut(mmcm.dwe));
    mkConnection(toGet(drp_fsm.mmcm_fab.den),       toPut(mmcm.den));
    mkConnection(toGet(drp_fsm.mmcm_fab.daddr),     toPut(mmcm.daddr));
    mkConnection(toGet(drp_fsm.mmcm_fab.d_i),       toPut(mmcm.d_i));
    mkConnection(toGet(drp_fsm.mmcm_fab.cddcreq),   toPut(mmcm.cddcreq));
    //DRP FSM -> DUT
    mkConnection(toGet(mmcm.cddcdone),              toPut(drp_fsm.mmcm_fab.cddcdone));
    mkConnection(toGet(mmcm.drdy),                  toPut(drp_fsm.mmcm_fab.drdy));
    mkConnection(toGet(mmcm.d_o),                   toPut(drp_fsm.mmcm_fab.d_o));
    mkConnection(toGet(mmcm.locked),                toPut(drp_fsm.mmcm_fab.locked));

    for(Integer i = 0; i < valueof(NUM_CLOCKS); i = i + 1) begin
        vClockEnS[i] <- mkSyncBitWrapperFromCC(mmcm_clks[i]);
        vBUFGCE[i] <- mkBUFGCE(defaultValue, vClockEnS[i], clocked_by mmcm_clks[i]);
        clks_out[i] = vBUFGCE[i].clk_out;

        //ToDo adjust for CDDC 
        Bool clk_en = !drp_fsm.running || (config_.device_ifc.cddc_en && rClkSel != fromInteger(i));

        //ToDo... the ready signals should probably be in the respective output clock domains
        // clks_out_rdy <- mkNullCrossingWire(clks_out[i], );
        clks_out_rdy[i] <- mkBypassWire;

        rule rclk_en;
            vClockEnS[i] <= clk_en;
        endrule

        rule rclk_rdy;
            clks_out_rdy[i] <= clk_en && unpack(mmcm.locked);
        endrule
    end

    //tieoff unused mmcm signals
    rule tieoff;
        mmcm.clkinsel(1);
        mmcm.psen(0);
        mmcm.psincdec(0);
        mmcm.pwrdwn(0);
    endrule

    //connect clk feedback through BUFG
    rule fb;
        mmcm.clkfbin(bufg_fb.out);
    endrule

    // (*descending_urgency = "r_srst, ..." *)
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
        //ToDo adaptive mask from lut
        DRP_Request#(DRP_ADDR_WIDTH, DRP_DATA_WIDTH) req = DRP_Request { 
            addr: rAddr,
            data: zeroExtend(htime) << 6 | zeroExtend(ltime),
            mask: 'h1000,
            cddc: config_.device_ifc.cddc_en()
        };
        drp_fsm.set_drp_register(req); //this will only fire when the DRP FSM is ready
        rAddr <= rAddr + 1;
        rState <= REG1;
    endrule

    rule r_reg1 (rState == REG1);
        Bit#(1) edge_ = rClkDiv[0];
        Bit#(1) no_count = pack(rClkDiv == 1);
        DRP_Request#(DRP_ADDR_WIDTH, DRP_DATA_WIDTH) req = DRP_Request { 
            addr: rAddr,
            data: zeroExtend(edge_) << 7 | zeroExtend(no_count) << 6,
            mask: 'hFB00,
            //ToDo make sure cddc_en does not change between reg0 and reg1 accesses
            cddc: config_.device_ifc.cddc_en()
        };
        drp_fsm.set_drp_register(req);
        rState <= WAIT_DONE;
    endrule

    rule r_wait (rState == WAIT_DONE);
        //the done signal is a single pulse, it only signals DRP completion, not mmcm locking
        if(drp_fsm.done()) begin
            rState <= IDLE;
            config_.device_ifc.finish();
        end
    endrule

    //config
    interface fab_config_rd = config_.bus_ifc.s_rd;
    interface fab_config_wr = config_.bus_ifc.s_wr;

    interface clks = clks_out;
    interface clks_rdy = map(regToReadOnly, map(asReg, clks_out_rdy));

endmodule

module [Module] mkMMCM4E_DRP_AXI#(MMCME4_ADV_Config mmcm_cfg)(MMCM_DRP_AXI_ifc#(12, 32));
    let _int <- mkMMCM_DRP_AXI(mmcm_cfg);
    return _int;
endmodule

endpackage
