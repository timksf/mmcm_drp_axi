package ClockTester;

import Clocks :: *;
import BUtils :: *;

interface ClockTester_ifc;
    method Real f_slow();
endinterface

interface VClockTester_ifc;
    method Bit#(16) ht;
    method Bit#(16) lt;
endinterface

import "BDPI" function Bit#(64) c_int_to_double(Bit#(32) x);
import "BDPI" function Bit#(64) c_freq_from_ht_lt(Bit#(64) f_fast, Bit#(32) ht, Bit#(32) lt);

import "BDPI" function Action test(Bit#(64) x);

function Real freq_from_ht_lt(Real f_fast, Bit#(sz) ht, Bit#(sz) lt) provisos(Max#(32, sz, 32));
    return $bitstoreal(c_freq_from_ht_lt($realtobits(f_fast), cExtend(ht), cExtend(lt)));
endfunction

function Real int_to_double(Bit#(32) x);
    Bit#(64) v = c_int_to_double(x);
    return 1;
endfunction

import "BVI" ClockTester =
module vMkClockTester#(Clock clk_slow)(VClockTester_ifc);

    default_clock clk_fast (clk_fst, (*unused*) _gate);
    default_reset rst (reset_n);

    input_clock (clk_slw, (*unused*) _gate) = clk_slow;

    method (* reg *) ht_out ht() clocked_by(clk_fast) reset_by(rst);
    method (* reg *) lt_out lt() clocked_by(clk_fast) reset_by(rst);

    schedule ht CF lt;
    schedule ht CF ht;
    schedule lt CF lt;

endmodule

module mkClockTester#(Integer fast_period, Clock clk_slow)(ClockTester_ifc);

    // Real f_fast = 1 / int_to_double(fromInteger(fast_period));

    Clock clk_fast <- mkAbsoluteClock(0, fast_period);
    Reset rst_fast <- mkSyncResetFromCR(1, clk_fast);

    (* hide *)
    VClockTester_ifc _int <- vMkClockTester(clk_slow, clocked_by clk_fast, reset_by rst_fast);

    //sync counters from fast clock module clock
    Reg#(Bit#(16)) sync_ht <- mkSyncRegToCC(0, clk_fast, rst_fast);
    Reg#(Bit#(16)) sync_lt <- mkSyncRegToCC(0, clk_fast, rst_fast);

    rule rreadout;
        sync_ht <= _int.ht;
        sync_lt <= _int.lt;
    endrule

    //could also calculate duty cycle
    method f_slow = 0; //freq_from_ht_lt(1000000000, sync_ht, sync_lt);

endmodule

endpackage

