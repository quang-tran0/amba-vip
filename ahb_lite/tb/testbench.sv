`timescale 1ns/1ps
`default_nettype none

module testbench;
  import uvm_pkg::*;
  import ahb_pkg::*;
  import test_pkg::*;

  logic HCLK = 1'b0;
  always #5ns HCLK = ~HCLK;

  ahb_if ahb_vif(HCLK);

  ahb_subsystem dut (
    .HCLK    (HCLK),
    .HRESETn (ahb_vif.HRESETn),
    .HADDR   (ahb_vif.HADDR),
    .HTRANS  (ahb_vif.HTRANS),
    .HWRITE  (ahb_vif.HWRITE),
    .HSIZE   (ahb_vif.HSIZE),
    .HBURST  (ahb_vif.HBURST),
    .HWDATA  (ahb_vif.HWDATA),
    .HRDATA  (ahb_vif.HRDATA),
    .HREADY  (ahb_vif.HREADY),
    .HRESP   (ahb_vif.HRESP)
  );

  initial begin
    ahb_vif.HRESETn = 1'b0;
    repeat (5) @(posedge HCLK);
    @(negedge HCLK);
    ahb_vif.HRESETn = 1'b1;
  end

  initial begin
    uvm_config_db #(virtual ahb_if)::set(
      uvm_root::get(), "uvm_test_top", "vif", ahb_vif
    );
    run_test();
  end
endmodule

`default_nettype wire
