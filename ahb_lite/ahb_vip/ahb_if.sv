`timescale 1ns/1ps
`default_nettype none

interface ahb_if(input wire logic HCLK);
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  logic        HRESETn;
  logic [31:0] HADDR;
  logic [1:0]  HTRANS;
  logic        HWRITE;
  logic [2:0]  HSIZE;
  logic [2:0]  HBURST;
  logic [31:0] HWDATA;
  logic [31:0] HRDATA;
  logic        HREADY;
  logic        HRESP;

  logic data_valid_q;
  logic data_write_q;

  clocking driver_cb @(posedge HCLK);
    default input #1step output #0;
    input  HRESETn;
    output HADDR, HTRANS, HWRITE, HSIZE, HBURST, HWDATA;
    input  HRDATA, HREADY, HRESP;
  endclocking

  clocking monitor_cb @(posedge HCLK);
    default input #1step;
    input HRESETn, HADDR, HTRANS, HWRITE, HSIZE, HBURST;
    input HWDATA, HRDATA, HREADY, HRESP;
  endclocking

  always_ff @(posedge HCLK or negedge HRESETn) begin
    if (!HRESETn) begin
      data_valid_q <= 1'b0;
      data_write_q <= 1'b0;
    end else if (HREADY) begin
      data_valid_q <= HTRANS[1];
      data_write_q <= HWRITE;
    end
  end

  property p_limited_htrans;
    @(posedge HCLK) disable iff (!HRESETn)
      HTRANS inside {2'b00, 2'b10};
  endproperty

  property p_word_single_transfer;
    @(posedge HCLK) disable iff (!HRESETn)
      HTRANS[1] |-> ((HSIZE == 3'b010) && (HBURST == 3'b000));
  endproperty

  property p_address_control_stable_while_stalled;
    @(posedge HCLK) disable iff (!HRESETn)
      !HREADY |=> $stable({HADDR, HTRANS, HWRITE, HSIZE, HBURST});
  endproperty

  property p_write_data_stable_while_stalled;
    @(posedge HCLK) disable iff (!HRESETn)
      (data_valid_q && data_write_q && !HREADY) |=> $stable(HWDATA);
  endproperty

  property p_error_first_cycle_followed_by_final;
    @(posedge HCLK) disable iff (!HRESETn)
      (HRESP && !HREADY) |=> (HRESP && HREADY);
  endproperty

  property p_final_error_has_first_cycle;
    @(posedge HCLK) disable iff (!HRESETn)
      (HRESP && HREADY) |-> $past(HRESP && !HREADY);
  endproperty

  ahb_limited_htrans:
    assert property (p_limited_htrans)
    else `uvm_error("AHB_ASSERT", "Only IDLE and NONSEQ HTRANS are supported")
  ahb_word_single_transfer:
    assert property (p_word_single_transfer)
    else `uvm_error("AHB_ASSERT", "Active transfer was not WORD/SINGLE")
  ahb_address_control_stable_while_stalled:
    assert property (p_address_control_stable_while_stalled)
    else `uvm_error("AHB_ASSERT", "Address/control changed while HREADY was low")
  ahb_write_data_stable_while_stalled:
    assert property (p_write_data_stable_while_stalled)
    else `uvm_error("AHB_ASSERT", "HWDATA changed during a stalled write")
  ahb_error_first_cycle_followed_by_final:
    assert property (p_error_first_cycle_followed_by_final)
    else `uvm_error("AHB_ASSERT", "ERROR did not complete with its second cycle")
  ahb_final_error_has_first_cycle:
    assert property (p_final_error_has_first_cycle)
    else `uvm_error("AHB_ASSERT", "Final ERROR cycle lacked the required first cycle")

endinterface

`default_nettype wire
