class apb_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(apb_scoreboard)

  uvm_analysis_imp #(apb_transaction, apb_scoreboard) actual_imp;

  bit [31:0] ctrl_expected;
  bit [31:0] status_expected;
  bit [31:0] data_expected;
  bit [31:0] config_expected;

  int unsigned observed_count;
  int unsigned checked_count;
  int unsigned compared_count;
  int unsigned mismatch_count;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    actual_imp = new("actual_imp", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ctrl_expected   = 32'h0000_0000;
    status_expected = 32'h0000_0001;
    data_expected   = 32'h0000_0000;
    config_expected = 32'h0000_0000;
    observed_count  = 0;
    checked_count   = 0;
    compared_count  = 0;
    mismatch_count  = 0;
  endfunction

  function bit address_is_valid(bit [31:0] addr);
    return addr inside {32'h0000_0000, 32'h0000_0004,
                        32'h0000_0008, 32'h0000_000c};
  endfunction

  function bit [31:0] expected_read_data(bit [31:0] addr);
    case (addr)
      32'h0000_0000: return ctrl_expected;
      32'h0000_0004: return status_expected;
      32'h0000_0008: return data_expected;
      32'h0000_000c: return config_expected;
      default:       return 32'h0000_0000;
    endcase
  endfunction

  function void write(apb_transaction item);
    bit expected_error;
    bit [31:0] expected_data;

    observed_count++;
    checked_count++;
    expected_error = !address_is_valid(item.addr);

    if (item.slverr != expected_error) begin
      mismatch_count++;
      `uvm_error("APB_SLVERR", $sformatf(
        "Address 0x%08h expected PSLVERR=%0b, observed %0b",
        item.addr, expected_error, item.slverr))
    end

    if (expected_error)
      return;

    if (item.write) begin
      case (item.addr)
        32'h0000_0000: ctrl_expected   = item.wdata;
        32'h0000_0008: data_expected   = item.wdata;
        32'h0000_000c: config_expected = item.wdata;
        default: ; // STATUS is read-only.
      endcase
    end else begin
      compared_count++;
      expected_data = expected_read_data(item.addr);
      if (item.rdata != expected_data) begin
        mismatch_count++;
        `uvm_error("APB_READ_DATA", $sformatf(
          "Address 0x%08h expected 0x%08h, observed 0x%08h",
          item.addr, expected_data, item.rdata))
      end
    end
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    if (observed_count == 0)
      `uvm_error("APB_ZERO_TRAFFIC", "Scoreboard observed no APB transfers")
    if (compared_count == 0)
      `uvm_error("APB_ZERO_COMPARE", "Scoreboard compared no APB reads")

    `uvm_info("APB_SCOREBOARD", $sformatf(
      "observed=%0d checked=%0d reads_compared=%0d mismatches=%0d",
      observed_count, checked_count, compared_count, mismatch_count), UVM_NONE)
  endfunction
endclass

