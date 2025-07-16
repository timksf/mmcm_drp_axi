package Testbench;

import StmtFSM :: *;
import Connectable :: *;
import GetPut :: *;

import BlueLib :: *;
import TestHelper :: *;
import MMCM_DRP_AXI :: *;
import MMCM_DRP_FSM :: *;
import TestImport :: *;
import TestMain :: *;
import TestFSM :: *;
import TestAXI :: *;
import TestMRE :: *;

(* synthesize *)
module [Module] mkTestbench();

    let test <- `TESTNAME ();

    mkAutoFSM(seq
        test.go();
        await(test.done());
    endseq);

endmodule

endpackage
