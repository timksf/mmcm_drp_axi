package MMCM_DRP_FSM;

import Clocks :: *;
import DReg :: *;

typedef struct {
    Bit#(aw) addr;
    Bit#(dw) data;  
    Bit#(dw) mask;
} DRP_Request#(numeric type aw, numeric type dw) deriving(Bits);

typedef enum {
    RESTART,
    WAIT_LOCK,
    WAIT_SEN,
    READ,
    WAIT_RDRDY,
    BITMASK,
    BITSET,
    WRITE,
    WAIT_WDRDY
} FSM_State deriving(Eq, Bits);

interface MMCM_DRP_Fab_ifc#(numeric type aw, numeric type dw);
    
    (* always_ready *)      method Bit#(1)   dwe();
    (* always_ready *)      method Bit#(1)   den();
    (* always_ready *)      method Bit#(aw)  daddr();
    (* always_ready *)      method Bit#(dw)  d_i();
    
    (* always_enabled *)    method Action   drdy(Bit#(1) d);
    (* always_enabled *)    method Action   d_o(Bit#(dw) d);
    (* always_enabled *)    method Action   locked(Bit#(1) l);
    
    interface Reset rst;
    interface Clock dclk;
endinterface

interface MMCM_DRP_FSM_ifc#(numeric type aw, numeric type dw);

    //outward facing
    (* prefix="s" *) method Action set_drp_register(DRP_Request#(aw, dw) req);
    method Bool done();
    method Action reset_fsm();

    //MMCM facing
    interface MMCM_DRP_Fab_ifc#(aw, dw) mmcm_fab;

endinterface

module mkMMCM_DRP_FSM(MMCM_DRP_FSM_ifc#(aw, dw));

    Clock clk <- exposeCurrentClock;
    Reset rst <- exposeCurrentReset;
    MakeResetIfc rst_mmcm <- mkReset(0, True, clk);

    Reset rst_out <- mkResetEither(rst, rst_mmcm.new_rst);

    //internal registers
    Reg#(FSM_State)             rState      <- mkReg(RESTART);
    Reg#(DRP_Request#(aw, dw))  rDRPReq     <- mkRegU;
    Reg#(Bit#(dw))              rDRPData    <- mkRegU;
    Reg#(Bool)                  rDone       <- mkDReg(False);

    //input wires
    Wire#(Bit#(1))              bwDRDY      <- mkBypassWire;
    Wire#(Bit#(dw))             bwDO        <- mkBypassWire;
    Wire#(Bit#(1))              bwLocked    <- mkBypassWire;

    //registered outputs
    Reg#(Bit#(1))               rDWE        <- mkRegU;
    Reg#(Bit#(1))               rDEN        <- mkRegU;
    Reg#(Bit#(aw))              rDAddr      <- mkRegU;
    Reg#(Bit#(dw))              rDI         <- mkRegU;

    //always assert mmcm reset during DRP access
    rule r_rst_mmcm (rState != WAIT_SEN && rState != WAIT_LOCK);
        rst_mmcm.assertReset();
    endrule

    rule r_restart (rState == RESTART);
        rState <= WAIT_LOCK;
    endrule

    rule r_wait_lock (rState == WAIT_LOCK);
        if(bwLocked == 1)
            rState <= WAIT_SEN; //WAIT_SEN implemented in method below
    endrule

    rule r_read (rState == READ);
        rDEN <= 1;
        rDAddr <= rDRPReq.addr;
        rState <= WAIT_RDRDY;
    endrule

    rule r_wait_rdrdy (rState == WAIT_RDRDY);
        rDEN <= 0;
        //DRP enabled - wait for response
        if(bwDRDY == 1) begin
            rState <= BITMASK;
            rDRPData <= bwDO;
        end
    endrule

    rule r_bitmask (rState == BITMASK);
        rDRPData <= rDRPData & rDRPReq.mask;
        rState <= BITSET;
    endrule

    rule r_bitset (rState == BITSET);
        rDRPData <= rDRPData | (rDRPReq.data & ~rDRPReq.mask);
        rState <= WRITE;
    endrule

    rule r_write (rState == WRITE);
        rDEN <= 1;
        rDWE <= 1;
        rDI <= rDRPData;
        rState <= WAIT_WDRDY;
    endrule

    rule r_wait_wdrdy (rState == WAIT_WDRDY);
        rDEN <= 0;
        rDWE <= 0;
        if(bwDRDY == 1) begin
            rState <= WAIT_LOCK;
            rDone <= True;
        end
    endrule

    method Action set_drp_register(DRP_Request#(aw, dw) r) if(rState == WAIT_SEN);
        rState <= READ;
        rDRPReq <= r;
    endmethod

    method done = rDone;
    
    interface MMCM_DRP_Fab_ifc mmcm_fab;

        method dwe      = rDWE;
        method den      = rDEN;
        method daddr    = rDAddr;
        method d_i      = rDI;
        
        method drdy     = bwDRDY._write;
        method d_o      = bwDO._write;
        method locked   = bwLocked._write;
        
        interface rst   = rst_out;
        interface dclk  = clk;

    endinterface

endmodule

(* synthesize *)
module mkMMCM4E_DRP_FSM(MMCM_DRP_FSM_ifc#(7, 16));
    MMCM_DRP_FSM_ifc#(7, 16) ifc();
    mkMMCM_DRP_FSM _internal(ifc);
    return ifc;
endmodule

endpackage