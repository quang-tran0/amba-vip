`ifndef GUARD_AHB_TEST_PKG__SV
`define GUARD_AHB_TEST_PKG__SV

package test_pkg;
  import uvm_pkg::*;
  import ahb_pkg::*;
  import env_pkg::*;
  import seq_pkg::*;
  `include "uvm_macros.svh"

  `include "ahb_base_test.sv"
  `include "ahb_smoke_test.sv"
endpackage : test_pkg

`endif
