`timescale 1ns/1ps
`default_nettype none

module ahb_interconnect (
  input  wire logic        HCLK,
  input  wire logic        HRESETn,
  input  wire logic [31:0] HADDR,
  input  wire logic [1:0]  HTRANS,
  output logic             HSEL0,
  output logic             HSEL1,
  input  wire logic [31:0] HRDATA0,
  input  wire logic        HREADYOUT0,
  input  wire logic        HRESP0,
  input  wire logic [31:0] HRDATA1,
  input  wire logic        HREADYOUT1,
  input  wire logic        HRESP1,
  output logic [31:0]      HRDATA,
  output logic             HREADY,
  output logic             HRESP
);

  localparam logic [1:0] SELECT_NONE    = 2'b00;
  localparam logic [1:0] SELECT_BANK0   = 2'b01;
  localparam logic [1:0] SELECT_BANK1   = 2'b10;
  localparam logic [1:0] SELECT_DEFAULT = 2'b11;

  logic [1:0] address_select;
  logic [1:0] data_select_q;
  logic       default_error_second_q;

  always_comb begin
    if ((HADDR & 32'hffff_f000) == 32'h0000_0000)
      address_select = SELECT_BANK0;
    else if ((HADDR & 32'hffff_f000) == 32'h0001_0000)
      address_select = SELECT_BANK1;
    else
      address_select = SELECT_DEFAULT;

    HSEL0 = (address_select == SELECT_BANK0);
    HSEL1 = (address_select == SELECT_BANK1);
  end

  // Response routing uses the accepted address-phase selection, never the
  // current live HADDR, which may already describe the next transfer.
  always_comb begin
    HRDATA = 32'h0000_0000;
    HREADY = 1'b1;
    HRESP  = 1'b0;

    unique case (data_select_q)
      SELECT_BANK0: begin
        HRDATA = HRDATA0;
        HREADY = HREADYOUT0;
        HRESP  = HRESP0;
      end
      SELECT_BANK1: begin
        HRDATA = HRDATA1;
        HREADY = HREADYOUT1;
        HRESP  = HRESP1;
      end
      SELECT_DEFAULT: begin
        HREADY = default_error_second_q;
        HRESP  = 1'b1;
      end
      default: ;
    endcase
  end

  always_ff @(posedge HCLK or negedge HRESETn) begin
    if (!HRESETn) begin
      data_select_q          <= SELECT_NONE;
      default_error_second_q <= 1'b0;
    end else if (HREADY) begin
      if (HTRANS[1])
        data_select_q <= address_select;
      else
        data_select_q <= SELECT_NONE;
      default_error_second_q <= 1'b0;
    end else if ((data_select_q == SELECT_DEFAULT) &&
                 !default_error_second_q) begin
      default_error_second_q <= 1'b1;
    end
  end

endmodule

`default_nettype wire
