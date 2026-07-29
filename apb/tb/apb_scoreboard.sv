`uvm_analysis_imp_decl(_expected)
`uvm_analysis_imp_decl(_actual)

class apb_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(apb_scoreboard)

  uvm_analysis_imp_expected #(apb_transaction, apb_scoreboard) expected_imp;
  uvm_analysis_imp_actual #(apb_transaction, apb_scoreboard) actual_imp;
  apb_transaction expected_items[$];
  apb_transaction actual_items[$];

  bit [31:0] ctrl_expected;
  bit [31:0] status_expected;
  bit [31:0] data_expected;
  bit [31:0] config_expected;

  int unsigned observed_count;
  int unsigned checked_count;
  int unsigned compared_count;
  int unsigned mismatch_count;
  int unsigned back_to_back_count;
  bit          check_active_stimulus;

  bit          sampled_write;
  bit [31:0]   sampled_addr;
  bit          sampled_slverr;
  int unsigned sampled_wait_cycles;
  bit          sampled_back_to_back;

  covergroup apb_access_cg;
    option.per_instance = 1;

    direction_cp: coverpoint sampled_write {
      bins read  = {0};
      bins write = {1};
    }
    address_cp: coverpoint sampled_addr {
      bins ctrl       = {32'h0000_0000};
      bins status     = {32'h0000_0004};
      bins data_reg   = {32'h0000_0008};
      bins config_reg = {32'h0000_000c};
      bins invalid    = default;
    }
    error_cp: coverpoint sampled_slverr {
      bins okay  = {0};
      bins error = {1};
    }
    wait_cp: coverpoint sampled_wait_cycles {
      bins zero = {0};
      bins one  = {1};
      bins many = {[2:$]};
    }
    back_to_back_cp: coverpoint sampled_back_to_back {
      bins isolated = {0};
      bins adjacent = {1};
    }
    address_direction_cross: cross address_cp, direction_cp;
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    expected_imp = new("expected_imp", this);
    actual_imp = new("actual_imp", this);
    apb_access_cg = new();
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
    back_to_back_count = 0;
    check_active_stimulus = 1'b0;
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

  function void write_expected(apb_transaction item);
    apb_transaction copy;
    if (!$cast(copy, item.clone()))
      `uvm_fatal("APB_CLONE", "Could not clone expected APB transaction")
    expected_items.push_back(copy);
  endfunction

  function void write_actual(apb_transaction item);
    apb_transaction copy;
    bit expected_error;
    bit [31:0] expected_data;

    if (!$cast(copy, item.clone()))
      `uvm_fatal("APB_CLONE", "Could not clone observed APB transaction")
    actual_items.push_back(copy);

    observed_count++;
    checked_count++;
    if (item.back_to_back)
      back_to_back_count++;
    sampled_write        = item.write;
    sampled_addr         = item.addr;
    sampled_slverr       = item.slverr;
    sampled_wait_cycles  = item.wait_cycles;
    sampled_back_to_back = item.back_to_back;
    apb_access_cg.sample();
    expected_error = !address_is_valid(item.addr);

    if (item.wait_cycles != 1) begin
      mismatch_count++;
      `uvm_error("APB_WAIT_COUNT", $sformatf(
        "Address 0x%08h expected one wait cycle, observed %0d",
        item.addr, item.wait_cycles))
    end

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

  function void check_phase(uvm_phase phase);
    int unsigned common_count;

    super.check_phase(phase);
    if (check_active_stimulus) begin
      if (expected_items.size() != actual_items.size()) begin
        mismatch_count++;
        `uvm_error("APB_STREAM_COUNT", $sformatf(
          "Driver completed %0d requests, monitor observed %0d transfers",
          expected_items.size(), actual_items.size()))
      end

      common_count = (expected_items.size() < actual_items.size()) ?
                     expected_items.size() : actual_items.size();
      for (int unsigned index = 0; index < common_count; index++) begin
        if ((expected_items[index].write != actual_items[index].write) ||
            (expected_items[index].addr  != actual_items[index].addr)  ||
            (expected_items[index].wdata != actual_items[index].wdata)) begin
          mismatch_count++;
          `uvm_error("APB_STREAM_MISMATCH", $sformatf(
            "Transfer %0d request={%s} observed={%s}", index,
            expected_items[index].convert2string(),
            actual_items[index].convert2string()))
        end
      end

      if ((observed_count > 1) && (back_to_back_count == 0)) begin
        mismatch_count++;
        `uvm_error("APB_NO_BACK_TO_BACK",
          "No back-to-back transfer was observed in active test traffic")
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
      "observed=%0d checked=%0d reads_compared=%0d b2b=%0d mismatches=%0d coverage=%0.1f%%",
      observed_count, checked_count, compared_count, back_to_back_count,
      mismatch_count, apb_access_cg.get_inst_coverage()), UVM_NONE)
  endfunction
endclass
