`ifndef GUARD_AHB_ENV_PKG__SV
`define GUARD_AHB_ENV_PKG__SV

package env_pkg;
  import uvm_pkg::*;
  import ahb_pkg::*;
  `include "uvm_macros.svh"

  `include "ahb_scoreboard.sv"
  `include "ahb_environment.sv"
endpackage : env_pkg

`endif
