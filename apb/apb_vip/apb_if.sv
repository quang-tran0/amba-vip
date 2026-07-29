`timescale 1ns/1ps
`default_nettype none

interface apb_if(input wire logic PCLK);
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  logic        PRESETn;
  logic [31:0] PADDR;
  logic        PSEL;
  logic        PENABLE;
  logic        PWRITE;
  logic [31:0] PWDATA;
  logic [31:0] PRDATA;
  logic        PREADY;
  logic        PSLVERR;

  clocking driver_cb @(posedge PCLK);
    default input #1step output #0;
    input  PRESETn;
    output PADDR, PSEL, PENABLE, PWRITE, PWDATA;
    input  PRDATA, PREADY, PSLVERR;
  endclocking

  clocking monitor_cb @(posedge PCLK);
    default input #1step;
    input PRESETn, PADDR, PSEL, PENABLE, PWRITE;
    input PWDATA, PRDATA, PREADY, PSLVERR;
  endclocking

  property p_penable_requires_psel;
    @(posedge PCLK) disable iff (!PRESETn)
      PENABLE |-> PSEL;
  endproperty

  property p_address_stable_while_waiting;
    @(posedge PCLK) disable iff (!PRESETn)
      (PSEL && PENABLE && !PREADY) |=> $stable(PADDR);
  endproperty

  property p_write_stable_while_waiting;
    @(posedge PCLK) disable iff (!PRESETn)
      (PSEL && PENABLE && !PREADY) |=> $stable(PWRITE);
  endproperty

  property p_wdata_stable_while_waiting;
    @(posedge PCLK) disable iff (!PRESETn)
      (PSEL && PENABLE && PWRITE && !PREADY) |=> $stable(PWDATA);
  endproperty

  property p_psel_held_while_waiting;
    @(posedge PCLK) disable iff (!PRESETn)
      (PSEL && PENABLE && !PREADY) |=> (PSEL && PENABLE);
  endproperty

  property p_setup_followed_by_access;
    @(posedge PCLK) disable iff (!PRESETn)
      (PSEL && !PENABLE) |=> (PSEL && PENABLE);
  endproperty

  property p_access_preceded_by_setup;
    @(posedge PCLK) disable iff (!PRESETn)
      $rose(PENABLE) |-> $past(PSEL && !PENABLE);
  endproperty

  property p_request_stable_from_setup;
    @(posedge PCLK) disable iff (!PRESETn)
      (PSEL && !PENABLE) |=>
        (PSEL && PENABLE && $stable(PADDR) && $stable(PWRITE) &&
         (!PWRITE || $stable(PWDATA)));
  endproperty

  property p_completion_returns_to_setup_or_idle;
    @(posedge PCLK) disable iff (!PRESETn)
      (PSEL && PENABLE && PREADY) |=> !PENABLE;
  endproperty

  apb_penable_requires_psel:
    assert property (p_penable_requires_psel)
    else `uvm_error("APB_ASSERT", "PENABLE asserted without PSEL")
  apb_address_stable_while_waiting:
    assert property (p_address_stable_while_waiting)
    else `uvm_error("APB_ASSERT", "PADDR changed while waiting for PREADY")
  apb_write_stable_while_waiting:
    assert property (p_write_stable_while_waiting)
    else `uvm_error("APB_ASSERT", "PWRITE changed while waiting for PREADY")
  apb_wdata_stable_while_waiting:
    assert property (p_wdata_stable_while_waiting)
    else `uvm_error("APB_ASSERT", "PWDATA changed while waiting for PREADY")
  apb_psel_held_while_waiting:
    assert property (p_psel_held_while_waiting)
    else `uvm_error("APB_ASSERT", "PSEL or PENABLE dropped before PREADY")
  apb_setup_followed_by_access:
    assert property (p_setup_followed_by_access)
    else `uvm_error("APB_ASSERT", "APB setup was not followed by access")
  apb_access_preceded_by_setup:
    assert property (p_access_preceded_by_setup)
    else `uvm_error("APB_ASSERT", "APB access did not follow a setup phase")
  apb_request_stable_from_setup:
    assert property (p_request_stable_from_setup)
    else `uvm_error("APB_ASSERT", "APB request changed between setup and access")
  apb_completion_returns_to_setup_or_idle:
    assert property (p_completion_returns_to_setup_or_idle)
    else `uvm_error("APB_ASSERT", "PENABLE remained high after completion")

endinterface

`default_nettype wire
