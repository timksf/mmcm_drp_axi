#!/usr/bin/env bluetcl

lappend auto_path /home/tim/Documents/HardwareDescription/bdw/src/util/

package require Bluetcl
package require Bluesim
package require Virtual
package require Waves

namespace import Bluetcl::*

proc packages {} {
    # returns the list of presently loaded packages
    set res {}
    foreach i [package names] {
        if {[string length [package provide $i]]} {
            lappend res $i
        }
    }
    set res
};

#loading top will also load all dependencies
set top TestMain 
set dir build
#$env(TOP)

Bluetcl::flags set -p "+:$dir"
bpackage load $top

foreach pkg [bpackage list] {
    # puts [defs type $pkg]
}

set mod [defs module MMCM_DRP_FSM]
puts $mod
Bluetcl::flags set -verilog
puts [module load mkMMCM4E_DRP_FSM]

puts [Virtual::inst top]