package MMCME4_ADV;

import Clocks :: *;
import DefaultValue :: *;

typedef struct {
    String   p_BANDWIDTH;                // Jitter programming
    Real     p_CLKFBOUT_MULT_F;          // Multiply value for all CLKOUT
    Real     p_CLKFBOUT_PHASE;           // Phase offset in degrees of CLKFB
    String   p_CLKFBOUT_USE_FINE_PS;     // Fine phase shift enable (TRUE/FALSE)
    Real     p_CLKIN1_PERIOD;            // Input clock period in ns to ps resolution (i.e., 33.333 is 30 MHz).
    Real     p_CLKIN2_PERIOD;            // Input clock period in ns to ps resolution (i.e., 33.333 is 30 MHz).
    Real     p_CLKOUT0_DIVIDE_F;         // Divide amount for CLKOUT0
    Real     p_CLKOUT0_DUTY_CYCLE;       // Duty cycle for CLKOUT0
    Real     p_CLKOUT0_PHASE;            // Phase offset for CLKOUT0
    String   p_CLKOUT0_USE_FINE_PS;      // Fine phase shift enable (TRUE/FALSE)
    Integer  p_CLKOUT1_DIVIDE;           // Divide amount for CLKOUT (1-128)
    Real     p_CLKOUT1_DUTY_CYCLE;       // Duty cycle for CLKOUT outputs (0.001-0.999).
    Real     p_CLKOUT1_PHASE;            // Phase offset for CLKOUT outputs (-360.000-360.000).
    String   p_CLKOUT1_USE_FINE_PS;      // Fine phase shift enable (TRUE/FALSE)
    Integer  p_CLKOUT2_DIVIDE;           // Divide amount for CLKOUT (1-128)
    Real     p_CLKOUT2_DUTY_CYCLE;       // Duty cycle for CLKOUT outputs (0.001-0.999).
    Real     p_CLKOUT2_PHASE;            // Phase offset for CLKOUT outputs (-360.000-360.000).
    String   p_CLKOUT2_USE_FINE_PS;      // Fine phase shift enable (TRUE/FALSE)
    Integer  p_CLKOUT3_DIVIDE;           // Divide amount for CLKOUT (1-128)
    Real     p_CLKOUT3_DUTY_CYCLE;       // Duty cycle for CLKOUT outputs (0.001-0.999).
    Real     p_CLKOUT3_PHASE;            // Phase offset for CLKOUT outputs (-360.000-360.000).
    String   p_CLKOUT3_USE_FINE_PS;      // Fine phase shift enable (TRUE/FALSE)
    String   p_CLKOUT4_CASCADE;          // Divide amount for CLKOUT (1-128)
    Integer  p_CLKOUT4_DIVIDE;           // Divide amount for CLKOUT (1-128)
    Real     p_CLKOUT4_DUTY_CYCLE;       // Duty cycle for CLKOUT outputs (0.001-0.999).
    Real     p_CLKOUT4_PHASE;            // Phase offset for CLKOUT outputs (-360.000-360.000).
    String   p_CLKOUT4_USE_FINE_PS;      // Fine phase shift enable (TRUE/FALSE)
    Integer  p_CLKOUT5_DIVIDE;           // Divide amount for CLKOUT (1-128)
    Real     p_CLKOUT5_DUTY_CYCLE;       // Duty cycle for CLKOUT outputs (0.001-0.999).
    Real     p_CLKOUT5_PHASE;            // Phase offset for CLKOUT outputs (-360.000-360.000).
    String   p_CLKOUT5_USE_FINE_PS;      // Fine phase shift enable (TRUE/FALSE)
    Integer  p_CLKOUT6_DIVIDE;           // Divide amount for CLKOUT (1-128)
    Real     p_CLKOUT6_DUTY_CYCLE;       // Duty cycle for CLKOUT outputs (0.001-0.999).
    Real     p_CLKOUT6_PHASE;            // Phase offset for CLKOUT outputs (-360.000-360.000).
    String   p_CLKOUT6_USE_FINE_PS;      // Fine phase shift enable (TRUE/FALSE)
    String   p_COMPENSATION;             // Clock input compensation
    Integer  p_DIVCLK_DIVIDE;            // Master division value
    Bit#(1)  p_IS_CLKFBIN_INVERTED;      // Optional inversion for CLKFBIN
    Bit#(1)  p_IS_CLKIN1_INVERTED;       // Optional inversion for CLKIN1
    Bit#(1)  p_IS_CLKIN2_INVERTED;       // Optional inversion for CLKIN2
    Bit#(1)  p_IS_CLKINSEL_INVERTED;     // Optional inversion for CLKINSEL
    Bit#(1)  p_IS_PSEN_INVERTED;         // Optional inversion for PSEN
    Bit#(1)  p_IS_PSINCDEC_INVERTED;     // Optional inversion for PSINCDEC
    Bit#(1)  p_IS_PWRDWN_INVERTED;       // Optional inversion for PWRDWN
    Bit#(1)  p_IS_RST_INVERTED;          // Optional inversion for RST
    Real     p_REF_JITTER1;              // Reference input jitter in UI (0.000-0.999).
    Real     p_REF_JITTER2;              // Reference input jitter in UI (0.000-0.999).
    String   p_SS_EN;                    // Enables spread spectrum
    String   p_SS_MODE;                  // Spread spectrum frequency deviation and the spread type
    Integer  p_SS_MOD_PERIOD;            // Spread spectrum modulation period (ns)
    String   p_STARTUP_WAIT;             // Delays DONE until MMCM is locked
} MMCME4_ADV_Config;


(* always_enabled *)
interface MMCME4_ADV_ifc;

    interface Clock clkout0;
    interface Clock clkout0b;
    interface Clock clkout1;
    interface Clock clkout1b;
    interface Clock clkout2;
    interface Clock clkout2b;
    interface Clock clkout3;
    interface Clock clkout3b;
    interface Clock clkout4;
    interface Clock clkout5;
    interface Clock clkout6;
    interface Clock clkfbout;
    interface Clock clkfboutb;

    method Action cddcreq(Bit#(1) i);
    method Action clkinsel(Bit#(1) i);
    method Action daddr(Bit#(7) i);
    method Action den(Bit#(1) i);
    method Action d_i(Bit#(16) i);
    method Action dwe(Bit#(1) i);
    method Action psen(Bit#(1) i);
    method Action psincdec(Bit#(1) i);
    method Action pwrdwn(Bit#(1) i);
    method Action clkfbin(Bit#(1) i);

    method Bit#(1)  cddcdone();
    method Bit#(16) d_o();
    method Bit#(1)  drdy();
    method Bit#(1)  locked();
    method Bit#(1)  psdone();
    method Bit#(1)  clkfbstopped();
    method Bit#(1)  clkinstopped();

endinterface

import "BVI" MMCME4_ADV = 
module vMkMMCME4_ADV#(
    MMCME4_ADV_Config cfg,
    Clock clkin1,
    Clock clkin2,
    Clock dclk,
    Clock psclk
)(MMCME4_ADV_ifc);

    parameter BANDWIDTH                = cfg.p_BANDWIDTH;
    parameter CLKFBOUT_MULT_F          = cfg.p_CLKFBOUT_MULT_F;
    parameter CLKFBOUT_PHASE           = cfg.p_CLKFBOUT_PHASE;
    parameter CLKFBOUT_USE_FINE_PS     = cfg.p_CLKFBOUT_USE_FINE_PS;
    parameter CLKIN1_PERIOD            = cfg.p_CLKIN1_PERIOD;
    parameter CLKIN2_PERIOD            = cfg.p_CLKIN2_PERIOD;
    parameter CLKOUT0_DIVIDE_F         = cfg.p_CLKOUT0_DIVIDE_F;
    parameter CLKOUT0_DUTY_CYCLE       = cfg.p_CLKOUT0_DUTY_CYCLE;
    parameter CLKOUT0_PHASE            = cfg.p_CLKOUT0_PHASE;
    parameter CLKOUT0_USE_FINE_PS      = cfg.p_CLKOUT0_USE_FINE_PS;
    parameter CLKOUT1_DIVIDE           = cfg.p_CLKOUT1_DIVIDE;
    parameter CLKOUT1_DUTY_CYCLE       = cfg.p_CLKOUT1_DUTY_CYCLE;
    parameter CLKOUT1_PHASE            = cfg.p_CLKOUT1_PHASE;
    parameter CLKOUT1_USE_FINE_PS      = cfg.p_CLKOUT1_USE_FINE_PS;
    parameter CLKOUT2_DIVIDE           = cfg.p_CLKOUT2_DIVIDE;
    parameter CLKOUT2_DUTY_CYCLE       = cfg.p_CLKOUT2_DUTY_CYCLE;
    parameter CLKOUT2_PHASE            = cfg.p_CLKOUT2_PHASE;
    parameter CLKOUT2_USE_FINE_PS      = cfg.p_CLKOUT2_USE_FINE_PS;
    parameter CLKOUT3_DIVIDE           = cfg.p_CLKOUT3_DIVIDE;
    parameter CLKOUT3_DUTY_CYCLE       = cfg.p_CLKOUT3_DUTY_CYCLE;
    parameter CLKOUT3_PHASE            = cfg.p_CLKOUT3_PHASE;
    parameter CLKOUT3_USE_FINE_PS      = cfg.p_CLKOUT3_USE_FINE_PS;
    parameter CLKOUT4_CASCADE          = cfg.p_CLKOUT4_CASCADE;
    parameter CLKOUT4_DIVIDE           = cfg.p_CLKOUT4_DIVIDE;
    parameter CLKOUT4_DUTY_CYCLE       = cfg.p_CLKOUT4_DUTY_CYCLE;
    parameter CLKOUT4_PHASE            = cfg.p_CLKOUT4_PHASE;
    parameter CLKOUT4_USE_FINE_PS      = cfg.p_CLKOUT4_USE_FINE_PS;
    parameter CLKOUT5_DIVIDE           = cfg.p_CLKOUT5_DIVIDE;
    parameter CLKOUT5_DUTY_CYCLE       = cfg.p_CLKOUT5_DUTY_CYCLE;
    parameter CLKOUT5_PHASE            = cfg.p_CLKOUT5_PHASE;
    parameter CLKOUT5_USE_FINE_PS      = cfg.p_CLKOUT5_USE_FINE_PS;
    parameter CLKOUT6_DIVIDE           = cfg.p_CLKOUT6_DIVIDE;
    parameter CLKOUT6_DUTY_CYCLE       = cfg.p_CLKOUT6_DUTY_CYCLE;
    parameter CLKOUT6_PHASE            = cfg.p_CLKOUT6_PHASE;
    parameter CLKOUT6_USE_FINE_PS      = cfg.p_CLKOUT6_USE_FINE_PS;
    parameter COMPENSATION             = cfg.p_COMPENSATION;
    parameter DIVCLK_DIVIDE            = cfg.p_DIVCLK_DIVIDE;
    parameter IS_CLKFBIN_INVERTED      = cfg.p_IS_CLKFBIN_INVERTED;
    parameter IS_CLKIN1_INVERTED       = cfg.p_IS_CLKIN1_INVERTED;
    parameter IS_CLKIN2_INVERTED       = cfg.p_IS_CLKIN2_INVERTED;
    parameter IS_CLKINSEL_INVERTED     = cfg.p_IS_CLKINSEL_INVERTED;
    parameter IS_PSEN_INVERTED         = cfg.p_IS_PSEN_INVERTED;
    parameter IS_PSINCDEC_INVERTED     = cfg.p_IS_PSINCDEC_INVERTED;
    parameter IS_PWRDWN_INVERTED       = cfg.p_IS_PWRDWN_INVERTED;
    parameter IS_RST_INVERTED          = cfg.p_IS_RST_INVERTED;
    parameter REF_JITTER1              = cfg.p_REF_JITTER1;
    parameter REF_JITTER2              = cfg.p_REF_JITTER2;
    parameter SS_EN                    = cfg.p_SS_EN;
    parameter SS_MODE                  = cfg.p_SS_MODE;
    parameter SS_MOD_PERIOD            = cfg.p_SS_MOD_PERIOD;
    parameter STARTUP_WAIT             = cfg.p_STARTUP_WAIT;

    //the default clock is only needed for the bluespec compiler?
    default_clock dclk  (DCLK);
    default_reset rst   (RST);
    
    input_clock (CLKIN1, (*unused*) _gate) = clkin1;
    input_clock (CLKIN2, (*unused*) _gate) = clkin2;
    
    // input_clock (DCLK,  (*unused*) _gate) = dclk;
    input_clock (PSCLK, (*unused*) _gate) = psclk;

    output_clock clkout0    (CLKOUT0);
    output_clock clkout0b   (CLKOUT0B);
    output_clock clkout1    (CLKOUT1);
    output_clock clkout1b   (CLKOUT1B);
    output_clock clkout2    (CLKOUT2);
    output_clock clkout2b   (CLKOUT2B);
    output_clock clkout3    (CLKOUT3);
    output_clock clkout3b   (CLKOUT3B);
    output_clock clkout4    (CLKOUT4);
    output_clock clkout5    (CLKOUT5);
    output_clock clkout6    (CLKOUT6);
    output_clock clkfbout   (CLKFBOUT);
    output_clock clkfboutb  (CLKFBOUTB);

    same_family(clkin1, clkout0);
    same_family(clkin1, clkout0b);
    same_family(clkin1, clkout1);
    same_family(clkin1, clkout1b);
    same_family(clkin1, clkout2);
    same_family(clkin1, clkout2b);
    same_family(clkin1, clkout3);
    same_family(clkin1, clkout3b);
    same_family(clkin1, clkout4);
    same_family(clkin1, clkout5);
    same_family(clkin1, clkout6);
    same_family(clkin1, clkfbout);
    same_family(clkin1, clkfboutb);

    same_family(clkin2, clkout0);
    same_family(clkin2, clkout0b);
    same_family(clkin2, clkout1);
    same_family(clkin2, clkout1b);
    same_family(clkin2, clkout2);
    same_family(clkin2, clkout2b);
    same_family(clkin2, clkout3);
    same_family(clkin2, clkout3b);
    same_family(clkin2, clkout4);
    same_family(clkin2, clkout5);
    same_family(clkin2, clkout6);
    same_family(clkin2, clkfbout);
    same_family(clkin2, clkfboutb);

    //input ports
    method clkfbin  (CLKFBIN)   enable((*inhigh*) EN1) clocked_by(clkfbout);
    method cddcreq  (CDDCREQ)   enable((*inhigh*) EN0);
    method clkinsel (CLKINSEL)  enable((*inhigh*) EN2);
    method psen     (PSEN)      enable((*inhigh*) EN3);
    method psincdec (PSINCDEC)  enable((*inhigh*) EN4);
    method pwrdwn   (PWRDWN)    enable((*inhigh*) EN5);
    // DRP
    method daddr    (DADDR)     enable((*inhigh*) EN6) clocked_by(dclk);
    method den      (DEN)       enable((*inhigh*) EN7) clocked_by(dclk);
    method d_i      (DI)        enable((*inhigh*) EN8) clocked_by(dclk);
    method dwe      (DWE)       enable((*inhigh*) EN9) clocked_by(dclk);
    
    //output ports
    method (* reg *) CDDCDONE     cddcdone();
    method (* reg *) DO           d_o() clocked_by(dclk);
    method (* reg *) DRDY         drdy() clocked_by(dclk);
    method (* reg *) LOCKED       locked() clocked_by(no_clock) reset_by(no_reset);
    method (* reg *) PSDONE       psdone();
    method (* reg *) CLKFBSTOPPED clkfbstopped();
    method (* reg *) CLKINSTOPPED clkinstopped();

    //do not allow multiple clocks driving FB
    schedule clkfbin C clkfbin;
    
    //ignore scheduling for remaining methods
    schedule(
        cddcreq,
        clkinsel,
        daddr,
        den,
        d_i,
        dwe,
        psen,
        psincdec,
        pwrdwn,
        cddcdone,
        d_o,
        drdy,
        locked,
        psdone,
        clkfbstopped,
        clkinstopped
    ) CF (
        cddcreq,
        clkinsel,
        daddr,
        den,
        d_i,
        dwe,
        psen,
        psincdec,
        pwrdwn,
        cddcdone,
        d_o,
        drdy,
        locked,
        psdone,
        clkfbstopped,
        clkinstopped
    );

endmodule

module mkMMCM4E_ADV#(
    MMCME4_ADV_Config cfg,
    Clock clkin1,
    Clock clkin2,
    Clock dclk,
    Clock psclk
)(MMCME4_ADV_ifc);
    (* hide *)
    let _int <- vMkMMCME4_ADV(cfg, clkin1, clkin2, dclk, psclk);
    return _int;
endmodule


instance DefaultValue#(MMCME4_ADV_Config);
    defaultValue = MMCME4_ADV_Config {
        p_BANDWIDTH:               "OPTIMIZED",
        p_CLKFBOUT_MULT_F:         5.0,
        p_CLKFBOUT_PHASE:          0.0,
        p_CLKFBOUT_USE_FINE_PS:    "FALSE",
        p_CLKIN1_PERIOD:           0.0,
        p_CLKIN2_PERIOD:           0.0,
        p_CLKOUT0_DIVIDE_F:        1.0,
        p_CLKOUT0_DUTY_CYCLE:      0.5,
        p_CLKOUT0_PHASE:           0.0,
        p_CLKOUT0_USE_FINE_PS:     "FALSE",
        p_CLKOUT1_DIVIDE:          1,
        p_CLKOUT1_DUTY_CYCLE:      0.5,
        p_CLKOUT1_PHASE:           0.0,
        p_CLKOUT1_USE_FINE_PS:     "FALSE",
        p_CLKOUT2_DIVIDE:          1,
        p_CLKOUT2_DUTY_CYCLE:      0.5,
        p_CLKOUT2_PHASE:           0.0,
        p_CLKOUT2_USE_FINE_PS:     "FALSE",
        p_CLKOUT3_DIVIDE:          1,
        p_CLKOUT3_DUTY_CYCLE:      0.5,
        p_CLKOUT3_PHASE:           0.0,
        p_CLKOUT3_USE_FINE_PS:     "FALSE",
        p_CLKOUT4_CASCADE:         "FALSE",
        p_CLKOUT4_DIVIDE:          1,
        p_CLKOUT4_DUTY_CYCLE:      0.5,
        p_CLKOUT4_PHASE:           0.0,
        p_CLKOUT4_USE_FINE_PS:     "FALSE",
        p_CLKOUT5_DIVIDE:          1,
        p_CLKOUT5_DUTY_CYCLE:      0.5,
        p_CLKOUT5_PHASE:           0.0,
        p_CLKOUT5_USE_FINE_PS:     "FALSE",
        p_CLKOUT6_DIVIDE:          1,
        p_CLKOUT6_DUTY_CYCLE:      0.5,
        p_CLKOUT6_PHASE:           0.0,
        p_CLKOUT6_USE_FINE_PS:     "FALSE",
        p_COMPENSATION:            "AUTO",
        p_DIVCLK_DIVIDE:           1,
        p_IS_CLKFBIN_INVERTED:     0,
        p_IS_CLKIN1_INVERTED:      0,
        p_IS_CLKIN2_INVERTED:      0,
        p_IS_CLKINSEL_INVERTED:    0,
        p_IS_PSEN_INVERTED:        0,
        p_IS_PSINCDEC_INVERTED:    0,
        p_IS_PWRDWN_INVERTED:      0,
        p_IS_RST_INVERTED:         0,
        p_REF_JITTER1:             0.0,
        p_REF_JITTER2:             0.0,
        p_SS_EN:                   "FALSE",
        p_SS_MODE:                 "CENTER_HIGH",
        p_SS_MOD_PERIOD:           10000,
        p_STARTUP_WAIT:            "FALSE"
    };
endinstance

endpackage
