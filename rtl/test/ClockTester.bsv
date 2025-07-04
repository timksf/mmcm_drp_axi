package ClockTester;

import Clocks :: *;
import BUtils :: *;
import FloatingPoint :: *;


interface ClockTester_ifc;
    method Double f_slow();
    method Action restart();
endinterface

interface VClockTester_ifc;
    method Bit#(16) ht;
    method Bit#(16) lt;
    method Action restart;
endinterface

import "BDPI" function Action   c_print_freq(Bit#(64) d);
import "BDPI" function Action   c_print_double(Bit#(64) d, Int#(32) digits);
import "BDPI" function Bit#(64) c_double_literal(String d);
import "BDPI" function Bit#(64) c_int_to_double(Bit#(32) x);
import "BDPI" function Bit#(64) c_freq_from_ht_lt(Bit#(64) f_fast, Bit#(32) ht, Bit#(32) lt);

import "BDPI" function Action test(Bit#(64) x);

function Double double_literal(String d)    = unpack(c_double_literal(d));
function Action print_double(Double d)      = c_print_double(pack(d), 2);
function Action print_freq(Double d)        = c_print_freq(pack(d));

function Double freq_from_ht_lt(Double f_fast, Bit#(sz) ht, Bit#(sz) lt) provisos(Max#(32, sz, 32));
    return unpack(c_freq_from_ht_lt(pack(f_fast), cExtend(ht), cExtend(lt)));
endfunction

function Double int_to_double(Bit#(32) x);
    return unpack(c_int_to_double(x));
endfunction

import "BVI" ClockTester =
module vMkClockTester#(Clock clk_slow)(VClockTester_ifc);

    default_clock clk_fast (clk_fst, (*unused*) _gate);
    default_reset rst (reset_n);

    input_clock (clk_slw, (*unused*) _gate) = clk_slow;

    //output methods
    method (* reg *) ht_out ht() clocked_by(clk_fast) reset_by(rst);
    method (* reg *) lt_out lt() clocked_by(clk_fast) reset_by(rst);

    //inputs methods
    method restart() enable(restart) clocked_by(clk_fast) reset_by(rst);

    schedule ht CF lt;
    schedule ht CF ht;
    schedule lt CF lt;

endmodule

module mkClockTester#(Integer fast_period, Clock clk_slow)(ClockTester_ifc);

    Double f_fast = 1 / int_to_double(fromInteger(fast_period));

    Clock clk_fast <- mkAbsoluteClock(0, fast_period);
    Reset rst_fast <- mkSyncResetFromCR(1, clk_fast);

    (* hide *)
    VClockTester_ifc _int <- vMkClockTester(clk_slow, clocked_by clk_fast, reset_by rst_fast);

    //sync counters from fast clock module clock
    Reg#(Bit#(16)) sync_ht <- mkSyncRegToCC(0, clk_fast, rst_fast);
    Reg#(Bit#(16)) sync_lt <- mkSyncRegToCC(0, clk_fast, rst_fast);

    SyncPulseIfc sync_restart <- mkSyncPulseFromCC(clk_fast);

    rule rreadout;
        sync_ht <= _int.ht;
        sync_lt <= _int.lt;
    endrule

    rule rrestart_sync if(sync_restart.pulse());
        _int.restart();
    endrule

    //could also calculate duty cycle
    method f_slow = freq_from_ht_lt(1000000000, sync_ht, sync_lt);
    method restart = sync_restart.send;

endmodule

endpackage

