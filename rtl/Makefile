###
# DO NOT CHANGE
###
TOP_MODULE=mkMMCM_DRP_AXI
TESTBENCH_MODULE=mkTestbench
IGNORE_MODULES=mkTestbench
MAIN_MODULE=MMCM_DRP_AXI
TESTBENCH_FILE=test/Testbench.bsv
TEST_DIR=$(CURDIR)/test
# VERBOSE=1

# Initialize
-include .bsv_tools
ifndef BSV_TOOLS
$(error BSV_TOOLS is not set (Check .bsv_tools or specify it through the command line))
endif
VIVADO_ADD_PARAMS := ''
CONSTRAINT_FILES := ''
EXTRA_BSV_LIBS:=
EXTRA_LIBRARIES:=
RUN_FLAGS:=

PROJECT_NAME=MMCM_DRP_AXI

RUN_TEST?=TestImport

ifeq ($(RUN_TEST),)
RUN_TEST=TestsMainTest
endif

# Default flags
EXTRA_FLAGS=-D "TESTNAME=mk$(RUN_TEST)"
EXTRA_FLAGS+=-show-schedule -D "BSV_TIMESCALE=1ps/1ps" -keep-inlined-boundaries -aggressive-conditions
#-keep-fires 

###
# User configuration
###

# Comment the following line if -O3 should be used during compilation
# Keep uncommented for short running simulations
CXX_NO_OPT := 1

# Any additional files added during compilation
# For instance for BDPI or Verilog/VHDL files for simulation
C_FILES += ../bdpi/bdpi.c

# Custom defines added to compile steps
# EXTRA_FLAGS+=-D "BENCHMARK=1"

# Flags added to simulator execution
ifeq ($(SIM_TYPE), VERILOG)
RUN_FLAGS+=+bscvcd
else
RUN_FLAGS+=-V dump.vcd
endif

# Add additional parameters for IP-XACT generation. Passed directly to Vivado.
# Any valid TCL during packaging is allowed
# Typically used to fix automatic inference for e.g. clock assignments
# VIVADO_ADD_PARAMS += 'ipx::associate_bus_interfaces -busif M_AXI -clock sconfig_axi_aclk [ipx::current_core]'

# Add custom constraint files, Syntax: Filename,Load Order
# CONSTRAINT_FILES += "$(CURDIR)/constraints/custom.xdc,LATE"

VERILOG_SIM:=iverilog
VERILOG_INC:=$(CURDIR)/../lib/unisims:$(CURDIR)/../lib:$(CURDIR)/test/

# Do not change: Load libraries such as BlueAXI or BlueLib
ifneq ("$(wildcard $(CURDIR)/libraries/*/*.mk)", "")
include $(CURDIR)/libraries/*/*.mk
endif

# Do not change: Include base makefile
include $(BSV_TOOLS)/scripts/rules.mk


bdw: 
	~/Documents/HardwareDescription/bdw/inst/bin/bdw