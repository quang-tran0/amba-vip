`timescale 1ns/1ps
`default_nettype none

module testbench;
  import uvm_pkg::*;
  import apb_pkg::*;
  import test_pkg::*;

  logic PCLK = 1'b0;
  always #5ns PCLK = ~PCLK;

  apb_if apb_vif(PCLK);

  apb_reg_bank #(
    .WAIT_STATES(1)
  ) dut (
    .PCLK    (PCLK),
    .PRESETn (apb_vif.PRESETn),
    .PADDR   (apb_vif.PADDR),
    .PSEL    (apb_vif.PSEL),
    .PENABLE (apb_vif.PENABLE),
    .PWRITE  (apb_vif.PWRITE),
    .PWDATA  (apb_vif.PWDATA),
    .PRDATA  (apb_vif.PRDATA),
    .PREADY  (apb_vif.PREADY),
    .PSLVERR (apb_vif.PSLVERR)
  );

  initial begin
    apb_vif.PRESETn = 1'b0;
    repeat (5) @(posedge PCLK);
    @(negedge PCLK);
    apb_vif.PRESETn = 1'b1;
  end

  initial begin
    uvm_config_db #(virtual apb_if)::set(
      uvm_root::get(), "uvm_test_top", "vif", apb_vif
    );
    run_test();
  end
endmodule

`default_nettype wire

