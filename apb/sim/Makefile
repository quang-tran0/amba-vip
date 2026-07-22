TB_NAME   ?= testbench
TESTNAME  ?= apb_smoke_test
VERBOSITY ?= UVM_HIGH
RUNARG    ?=
SEED      ?= 1
COV       ?= OFF

PROJECT_ROOT     := $(abspath ..)
APB_VERIF_ROOT  ?= $(PROJECT_ROOT)
APB_VIP_ROOT    ?= $(APB_VERIF_ROOT)/apb_vip
QUESTA_HOME     ?= $(abspath $(dir $(shell command -v vlog))/..)
UVM_HOME        ?= $(QUESTA_HOME)/verilog_src/uvm-1.2
DPI_GCC         := $(shell command -v gcc 2>/dev/null)
DPI_GCC_OPT     := $(if $(DPI_GCC),-dpicpppath $(DPI_GCC))

export APB_VERIF_ROOT APB_VIP_ROOT UVM_HOME

ifeq ($(COV),ON)
  CMP_COV_OPT  = -coveropt 3 +cover=bcestf
  SIM_COV_OPT  = -coverage -coveranalysis
  SAVE_COV_CMD = coverage save -codeAll -cvg -onexit $(TESTNAME)_$(SEED).ucdb;
endif

ifeq ($(strip $(SEED)),random)
  SEED = $(shell /bin/date +%s)
endif

VLOG = vlog -sv $(CMP_COV_OPT) \
       -timescale "1ns/1ps" \
       -mfcu \
       -suppress 2181 \
       +acc=rb \
       -L $(QUESTA_HOME)/uvm-1.2 \
       +incdir+$(UVM_HOME)/src

VSIM = vsim \
       -sv_seed $(SEED) $(SIM_COV_OPT) \
       -L $(QUESTA_HOME)/uvm-1.2 \
       $(DPI_GCC_OPT) \
       -voptargs=+acc \
       -assertdebug \
       -c $(TB_NAME) \
       -do "$(SAVE_COV_CMD) log -r /*; run -all; quit -f;" \
       -l $(TESTNAME)_$(SEED).log

.PHONY: all build run vlib wave cov_gui cov_merge clean help

all: build
	$(MAKE) run TESTNAME=$(TESTNAME) VERBOSITY=$(VERBOSITY) \
	  RUNARG="$(RUNARG)" SEED=$(SEED) COV=$(COV)

build: vlib
	$(VLOG) -f compile.f \
	  +define+UVM_OBJECT_MUST_HAVE_CONSTRUCTOR

run:
	$(VSIM) +UVM_TESTNAME=$(TESTNAME) \
	  +UVM_VERBOSITY=$(VERBOSITY) \
	  $(RUNARG)
	mv $(TESTNAME)_$(SEED).log ./log
	cp -f vsim.wlf log/$(TESTNAME)_$(SEED).wlf
	ln -sfn ./log/$(TESTNAME)_$(SEED).log run.log
	grep -q "TEST PASSED" ./log/$(TESTNAME)_$(SEED).log

vlib:
	mkdir -p log
	vlib work
	vmap work work

wave:
	vsim -i -view vsim.wlf -do "add wave vsim:/$(TB_NAME)/*;" &

cov_gui:
	vsim -i -viewcov $(TESTNAME)_$(SEED).ucdb &

cov_merge:
	vcover merge APB_MERGE.ucdb apb_*.ucdb

clean:
	rm -rf work log
	rm -f modelsim.ini transcript run.log
	rm -f *.log *.trace *.wlf *.ucdb
	rm -rf vsim.dbg tmp_report

help:
	@echo "make build                              Compile RTL and testbench"
	@echo "make run TESTNAME=<class> SEED=1       Run one compiled test"
	@echo "make all TESTNAME=<class>              Compile and run safely"
	@echo "make wave                               Open the latest waveform"
	@echo "make cov_merge                          Merge coverage databases"
	@echo "make clean                              Remove generated output"
