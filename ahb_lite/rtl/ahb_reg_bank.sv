`timescale 1ns/1ps
`default_nettype none

module ahb_reg_bank #(
  parameter logic [31:0] BASE_ADDR    = 32'h0000_0000,
  parameter logic [31:0] STATUS_RESET = 32'h0000_0001,
  parameter int unsigned WAIT_STATES  = 0
) (
  input  wire logic        HCLK,
  input  wire logic        HRESETn,
  input  wire logic        HSEL,
  input  wire logic [31:0] HADDR,
  input  wire logic [1:0]  HTRANS,
  input  wire logic        HWRITE,
  input  wire logic [2:0]  HSIZE,
  input  wire logic        HREADY,
  input  wire logic [31:0] HWDATA,
  output logic [31:0] HRDATA,
  output logic        HREADYOUT,
  output logic        HRESP
);

  localparam int unsigned WAIT_COUNT_WIDTH =
    (WAIT_STATES == 0) ? 1 : $clog2(WAIT_STATES + 1);

  logic [31:0] ctrl_reg;
  logic [31:0] status_reg;
  logic [31:0] data_reg;
  logic [31:0] config_reg;

  logic        transfer_valid_q;
  logic [31:0] addr_q;
  logic        write_q;
  logic [2:0]  size_q;
  logic        transfer_error_q;
  logic [WAIT_COUNT_WIDTH-1:0] wait_count_q;
  logic        error_second_q;

  function automatic logic request_is_valid(
    input logic [31:0] address,
    input logic [2:0]  size
  );
    logic valid_offset;

    case (address[11:0])
      12'h000, 12'h004, 12'h008, 12'h00c: valid_offset = 1'b1;
      default:                             valid_offset = 1'b0;
    endcase

    return ((address & 32'hffff_f000) == BASE_ADDR) &&
           (address[1:0] == 2'b00) && (size == 3'b010) && valid_offset;
  endfunction

  always_comb begin
    HRDATA = 32'h0000_0000;
    if (transfer_valid_q && !transfer_error_q) begin
      unique case (addr_q[11:0])
        12'h000: HRDATA = ctrl_reg;
        12'h004: HRDATA = status_reg;
        12'h008: HRDATA = data_reg;
        12'h00c: HRDATA = config_reg;
        default: HRDATA = 32'h0000_0000;
      endcase
    end

    HREADYOUT = 1'b1;
    HRESP     = 1'b0;
    if (transfer_valid_q) begin
      if (wait_count_q != '0) begin
        HREADYOUT = 1'b0;
      end else if (transfer_error_q) begin
        HRESP     = 1'b1;
        HREADYOUT = error_second_q;
      end
    end
  end

  always_ff @(posedge HCLK or negedge HRESETn) begin
    if (!HRESETn) begin
      ctrl_reg          <= 32'h0000_0000;
      status_reg        <= STATUS_RESET;
      data_reg          <= 32'h0000_0000;
      config_reg        <= 32'h0000_0000;
      transfer_valid_q  <= 1'b0;
      addr_q            <= 32'h0000_0000;
      write_q           <= 1'b0;
      size_q            <= 3'b010;
      transfer_error_q  <= 1'b0;
      wait_count_q      <= '0;
      error_second_q    <= 1'b0;
    end else begin
      // Complete the registered data phase before accepting a new address.
      if (transfer_valid_q && HREADY && HREADYOUT &&
          write_q && !transfer_error_q) begin
        unique case (addr_q[11:0])
          12'h000: ctrl_reg   <= HWDATA;
          12'h008: data_reg   <= HWDATA;
          12'h00c: config_reg <= HWDATA;
          default: ; // STATUS writes complete with OKAY and are ignored.
        endcase
      end

      // HREADY qualifies acceptance of the current address phase.
      if (HREADY) begin
        transfer_valid_q <= HSEL && HTRANS[1];
        error_second_q   <= 1'b0;
        if (HSEL && HTRANS[1]) begin
          addr_q           <= HADDR;
          write_q          <= HWRITE;
          size_q           <= HSIZE;
          transfer_error_q <= !request_is_valid(HADDR, HSIZE);
          wait_count_q     <= WAIT_STATES;
        end else begin
          transfer_error_q <= 1'b0;
          wait_count_q     <= '0;
        end
      end else if (transfer_valid_q) begin
        if (wait_count_q != '0)
          wait_count_q <= wait_count_q - 1'b1;
        else if (transfer_error_q && !error_second_q)
          error_second_q <= 1'b1;
      end
    end
  end

endmodule

`default_nettype wire
