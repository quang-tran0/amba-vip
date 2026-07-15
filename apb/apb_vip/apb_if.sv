`timescale 1ns/1ps
`default_nettype none

interface apb_if(input wire logic PCLK);
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
      (PSEL && PENABLE && !PREADY) |=> PSEL;
  endproperty

  apb_penable_requires_psel:
    assert property (p_penable_requires_psel);
  apb_address_stable_while_waiting:
    assert property (p_address_stable_while_waiting);
  apb_write_stable_while_waiting:
    assert property (p_write_stable_while_waiting);
  apb_wdata_stable_while_waiting:
    assert property (p_wdata_stable_while_waiting);
  apb_psel_held_while_waiting:
    assert property (p_psel_held_while_waiting);

endinterface

`default_nettype wire
