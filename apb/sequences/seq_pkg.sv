`ifndef GUARD_APB_SEQ_PKG__SV
`define GUARD_APB_SEQ_PKG__SV

package seq_pkg;
  import uvm_pkg::*;
  import apb_pkg::*;
  `include "uvm_macros.svh"

  `include "apb_smoke_sequence.sv"
  `include "apb_write_sequence.sv"
  `include "apb_read_sequence.sv"
  `include "apb_random_sequence.sv"
endpackage : seq_pkg

`endif
