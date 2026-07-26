`ifndef GUARD_APB_TEST_PKG__SV
`define GUARD_APB_TEST_PKG__SV

package test_pkg;
  import uvm_pkg::*;
  import apb_pkg::*;
  import env_pkg::*;
  import seq_pkg::*;
  `include "uvm_macros.svh"

  `include "apb_base_test.sv"
  `include "apb_smoke_test.sv"
  `include "apb_write_test.sv"
  `include "apb_read_test.sv"
  `include "apb_random_test.sv"
endpackage : test_pkg

`endif
