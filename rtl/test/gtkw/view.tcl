gtkwave::loadFile "build/dump.vcd"

# set comments [list]
# lappend comments "Test"
# gtkwave::addCommentTracesFromList $comments

set nfacs [ gtkwave::getNumFacs ]

set modules [list "main.top.test.drp_fsm"]

foreach mod $modules {
    set module_prefix $mod
    set signals [list]
    set prefix_len [string length $module_prefix]
    for {set i 0} {$i < $nfacs} {incr i} {
        set fac [ gtkwave::getFacName $i ]
        if { [string match "${module_prefix}*" $fac] } {
            set remainder [string range $fac $prefix_len end]

            # Ensure it starts with one dot
            if {[string index $remainder 0] ne "."} {
                continue
            }

            # Remove the leading dot
            set subpath [string range $remainder 1 end]

            # Reject if another dot exists after the first one (do not recurse)
            if {[string first "." $subpath] != -1} {
                continue
            }

            # Reject if starts with backslash (bluespec generated signals)
            if {[string match "\\\\*" $subpath]} {
                continue
            }

            puts "Adding signal $fac"
            lappend signals $fac
        }
    }
    if { [llength $signals] > 0 } {
        gtkwave::addCommentTracesFromList [list $mod]
        gtkwave::addSignalsFromList $signals
    }

}

#unhighlight all traces
for {set i 0} {$i < [gtkwave::getTotalNumTraces]} {incr i} {
    gtkwave::setTraceHighlightFromIndex $i off
}

set script_file [file normalize [info script]]
set pwd [file dirname $script_file]

set enum_transl [ gtkwave::setCurrentTranslateFile "$pwd/DRP_FSM_State_t.txt" ]
gtkwave::setTraceHighlightFromNameMatch {rState[3:0]} on
gtkwave::installFileFilter $enum_transl
gtkwave::setTraceHighlightFromNameMatch {rState[3:0]} off

# zoom full
gtkwave::/Time/Zoom/Zoom_Best_Fit
gtkwave::setLeftJustifySigs on