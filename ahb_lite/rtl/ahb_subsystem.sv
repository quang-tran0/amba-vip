`timescale 1ns/1ps
`default_nettype none

module ahb_subsystem (
  input  wire logic        HCLK,
  input  wire logic        HRESETn,
  input  wire logic [31:0] HADDR,
  input  wire logic [1:0]  HTRANS,
  input  wire logic        HWRITE,
  input  wire logic [2:0]  HSIZE,
  input  wire logic [2:0]  HBURST,
  input  wire logic [31:0] HWDATA,
  output logic [31:0]      HRDATA,
  output logic             HREADY,
  output logic             HRESP
);

  logic        HSEL0;
  logic        HSEL1;
  logic [31:0] HRDATA0;
  logic        HREADYOUT0;
  logic        HRESP0;
  logic [31:0] HRDATA1;
  logic        HREADYOUT1;
  logic        HRESP1;

  ahb_interconnect u_interconnect (
    .HCLK       (HCLK),
    .HRESETn    (HRESETn),
    .HADDR      (HADDR),
    .HTRANS     (HTRANS),
    .HSEL0      (HSEL0),
    .HSEL1      (HSEL1),
    .HRDATA0    (HRDATA0),
    .HREADYOUT0 (HREADYOUT0),
    .HRESP0     (HRESP0),
    .HRDATA1    (HRDATA1),
    .HREADYOUT1 (HREADYOUT1),
    .HRESP1     (HRESP1),
    .HRDATA     (HRDATA),
    .HREADY     (HREADY),
    .HRESP      (HRESP)
  );

  ahb_reg_bank #(
    .BASE_ADDR    (32'h0000_0000),
    .STATUS_RESET (32'h0000_0001),
    .WAIT_STATES  (0)
  ) bank0 (
    .HCLK      (HCLK),
    .HRESETn   (HRESETn),
    .HSEL      (HSEL0),
    .HADDR     (HADDR),
    .HTRANS    (HTRANS),
    .HWRITE    (HWRITE),
    .HSIZE     (HSIZE),
    .HREADY    (HREADY),
    .HWDATA    (HWDATA),
    .HRDATA    (HRDATA0),
    .HREADYOUT (HREADYOUT0),
    .HRESP     (HRESP0)
  );

  ahb_reg_bank #(
    .BASE_ADDR    (32'h0001_0000),
    .STATUS_RESET (32'h0000_0002),
    .WAIT_STATES  (1)
  ) bank1 (
    .HCLK      (HCLK),
    .HRESETn   (HRESETn),
    .HSEL      (HSEL1),
    .HADDR     (HADDR),
    .HTRANS    (HTRANS),
    .HWRITE    (HWRITE),
    .HSIZE     (HSIZE),
    .HREADY    (HREADY),
    .HWDATA    (HWDATA),
    .HRDATA    (HRDATA1),
    .HREADYOUT (HREADYOUT1),
    .HRESP     (HRESP1)
  );

endmodule

`default_nettype wire
