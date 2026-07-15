`timescale 1ns/1ps
`default_nettype none

module apb_reg_bank #(
  parameter int unsigned WAIT_STATES = 1
) (
  input  wire logic        PCLK,
  input  wire logic        PRESETn,
  input  wire logic [31:0] PADDR,
  input  wire logic        PSEL,
  input  wire logic        PENABLE,
  input  wire logic        PWRITE,
  input  wire logic [31:0] PWDATA,
  output logic [31:0] PRDATA,
  output logic        PREADY,
  output logic        PSLVERR
);

  localparam logic [31:0] CTRL_ADDR   = 32'h0000_0000;
  localparam logic [31:0] STATUS_ADDR = 32'h0000_0004;
  localparam logic [31:0] DATA_ADDR   = 32'h0000_0008;
  localparam logic [31:0] CONFIG_ADDR = 32'h0000_000c;
  localparam int unsigned WAIT_COUNT_WIDTH =
    (WAIT_STATES == 0) ? 1 : $clog2(WAIT_STATES + 1);

  logic [31:0] ctrl_reg;
  logic [31:0] status_reg;
  logic [31:0] data_reg;
  logic [31:0] config_reg;
  logic [WAIT_COUNT_WIDTH-1:0] wait_count;
  logic address_valid;
  logic transfer_complete;

  always_comb begin
    address_valid = 1'b1;
    unique case (PADDR)
      CTRL_ADDR,
      STATUS_ADDR,
      DATA_ADDR,
      CONFIG_ADDR: ;
      default: address_valid = 1'b0;
    endcase

    PRDATA = 32'h0000_0000;
    unique case (PADDR)
      CTRL_ADDR:   PRDATA = ctrl_reg;
      STATUS_ADDR: PRDATA = status_reg;
      DATA_ADDR:   PRDATA = data_reg;
      CONFIG_ADDR: PRDATA = config_reg;
      default:     PRDATA = 32'h0000_0000;
    endcase

    PREADY = PRESETn && PSEL && PENABLE && (wait_count == '0);
    transfer_complete = PSEL && PENABLE && PREADY;
    PSLVERR = transfer_complete && !address_valid;
  end

  always_ff @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
      ctrl_reg   <= 32'h0000_0000;
      status_reg <= 32'h0000_0001;
      data_reg   <= 32'h0000_0000;
      config_reg <= 32'h0000_0000;
      wait_count <= '0;
    end else begin
      if (PSEL && !PENABLE)
        wait_count <= WAIT_STATES;
      else if (PSEL && PENABLE && (wait_count != '0))
        wait_count <= wait_count - 1'b1;
      else if (!PSEL)
        wait_count <= '0;

      if (transfer_complete && PWRITE && address_valid) begin
        unique case (PADDR)
          CTRL_ADDR:   ctrl_reg   <= PWDATA;
          DATA_ADDR:   data_reg   <= PWDATA;
          CONFIG_ADDR: config_reg <= PWDATA;
          default: ; // STATUS is read-only.
        endcase
      end
    end
  end

endmodule

`default_nettype wire
