`ifndef GUARD_APB_ENV_PKG__SV
`define GUARD_APB_ENV_PKG__SV

package env_pkg;
  import uvm_pkg::*;
  import apb_pkg::*;
  `include "uvm_macros.svh"

  `include "apb_scoreboard.sv"
  `include "apb_environment.sv"
endpackage : env_pkg

`endif

