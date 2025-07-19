package MMCM_DRP_FSM;

import Clocks :: *;
import DReg :: *;
import FIFOF :: *;
import SpecialFIFOs :: *;

typedef struct {
    Bit#(aw) addr;
    Bit#(dw) data;  
    Bit#(dw) mask;
    Bool     cddc;
} DRP_Request#(numeric type aw, numeric type dw) deriving(FShow, Bits);

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
    (* always_ready *)      method Bit#(1)   cddcreq();
    
    (* always_enabled *)    method Action   cddcdone(Bit#(1) d);
    (* always_enabled *)    method Action   drdy(Bit#(1) d);
    (* always_enabled *)    method Action   d_o(Bit#(dw) d);
    (* always_enabled *)    method Action   locked(Bit#(1) l);
    
    interface Reset rst;
    interface Clock dclk;
endinterface

interface MMCM_DRP_FSM_ifc#(numeric type aw, numeric type dw);

    //outward facing
    (* prefix="s" *) method Action set_drp_register(DRP_Request#(aw, dw) req);
    method Bool running();
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
    Reg#(FSM_State)                 rState      <- mkReg(RESTART);
    FIFOF#(DRP_Request#(aw, dw))    fRequests   <- mkSizedBypassFIFOF(2);
    Reg#(DRP_Request#(aw, dw))      rDRPReq     <- mkRegU;
    Reg#(Bit#(dw))                  rDRPData    <- mkRegU;
    Reg#(Bool)                      rDone       <- mkDReg(False);

    //input wires   
    Wire#(Bit#(1))                  bwDRDY      <- mkBypassWire;
    Wire#(Bit#(dw))                 bwDO        <- mkBypassWire;
    Wire#(Bit#(1))                  bwCDDCDONE  <- mkBypassWire;
    Wire#(Bit#(1))                  bwLocked    <- mkBypassWire;

    //registered outputs    
    Reg#(Bit#(1))                   rDWE        <- mkRegU;
    Reg#(Bit#(1))                   rDEN        <- mkRegU;
    Reg#(Bit#(aw))                  rDAddr      <- mkRegU;
    Reg#(Bit#(dw))                  rDI         <- mkRegU;
    Reg#(Bit#(1))                   rCDDCREQ    <- mkRegU;

    rule r_rst_mmcm;
        /*
            this rule requires -aggressive-conditions so that it fires even when no requests are available.
            Do not reset when waiting for the lock signal as this is only asserted after reset is released.
            Do not reset when waiting for new requests and none is currently being enqueued.
            Do not reset when waiting for new requests and one with CDDC enabled is enqueued.
            Do not reset at all when CDDC is enabled in the current request.
        */
        case(rState)
            WAIT_LOCK: noAction;
            WAIT_SEN:
                if(fRequests.notEmpty()) begin
                    if(!fRequests.first.cddc) begin
                        rst_mmcm.assertReset();
                    end
                end
            default: 
                if(!rDRPReq.cddc)
                    rst_mmcm.assertReset();
        endcase

    endrule

    rule r_restart (rState == RESTART);
        rState <= WAIT_LOCK;
        rCDDCREQ <= 0;
    endrule

    rule r_wait_lock (rState == WAIT_LOCK);
        if(bwLocked == 1)
            rState <= WAIT_SEN;
    endrule

    rule r_wait_sen (rState == WAIT_SEN);
        //since we use a bypass fifo, this state is still single cycle with the request interface
        rDRPReq <= fRequests.first;
        rState <= READ;
    endrule

    rule r_read (rState == READ);
        fRequests.deq;
        rDEN <= 1;
        rCDDCREQ <= rDRPReq.cddc ? 1 : 0;
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
            //only done when requests empty
            rState <= fRequests.notEmpty ? WAIT_SEN : rDRPReq.cddc ? WAIT_WDRDY : WAIT_LOCK;
            rDone <= !fRequests.notEmpty && !rDRPReq.cddc;
            rCDDCREQ <= rDRPReq.cddc && fRequests.notEmpty ? 1 : 0;
        end else if(rDRPReq.cddc && bwCDDCDONE == 1) begin
            //cddcdone is asserted after drdy
            rCDDCREQ <= fRequests.notEmpty ? 1 : 0;
            rState <= fRequests.notEmpty ? WAIT_SEN : WAIT_LOCK;
            rDone <= !fRequests.notEmpty;
        end
    endrule

    method Action set_drp_register(DRP_Request#(aw, dw) r);
        fRequests.enq(r);
    endmethod

    method running = rState != WAIT_LOCK && rState != RESTART && (rState != WAIT_SEN || fRequests.notEmpty);

    method done = rDone;
    
    interface MMCM_DRP_Fab_ifc mmcm_fab;

        method dwe      = rDWE;
        method den      = rDEN;
        method daddr    = rDAddr;
        method d_i      = rDI;
        method cddcreq  = rCDDCREQ;
        
        method cddcdone = bwCDDCDONE._write;
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