`uvm_analysis_imp_decl(_expected)
`uvm_analysis_imp_decl(_actual)

class ahb_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(ahb_scoreboard)

  uvm_analysis_imp_expected #(ahb_transaction, ahb_scoreboard) expected_imp;
  uvm_analysis_imp_actual #(ahb_transaction, ahb_scoreboard) actual_imp;
  ahb_transaction expected_items[$];
  ahb_transaction actual_items[$];

  bit [31:0] ctrl_expected[2];
  bit [31:0] status_expected[2];
  bit [31:0] data_expected[2];
  bit [31:0] config_expected[2];

  int unsigned observed_count;
  int unsigned compared_count;
  int unsigned mismatch_count;
  bit          check_active_stimulus;

  bit          sampled_write;
  bit [31:0]   sampled_addr;
  int          sampled_bank;
  bit          sampled_mapped;
  bit          sampled_resp;
  int unsigned sampled_wait_cycles;

  covergroup ahb_access_cg;
    option.per_instance = 1;

    direction_cp: coverpoint sampled_write {
      bins read  = {0};
      bins write = {1};
    }
    bank_cp: coverpoint sampled_bank {
      bins bank0    = {0};
      bins bank1    = {1};
      bins unmapped = {-1};
    }
    offset_cp: coverpoint sampled_addr[11:0] {
      bins ctrl       = {12'h000};
      bins status     = {12'h004};
      bins data_reg   = {12'h008};
      bins config_reg = {12'h00c};
      bins other      = default;
    }
    mapped_cp: coverpoint sampled_mapped {
      bins mapped   = {1};
      bins unmapped = {0};
    }
    response_cp: coverpoint sampled_resp {
      bins okay  = {0};
      bins error = {1};
    }
    wait_cp: coverpoint sampled_wait_cycles {
      bins zero = {0};
      bins one  = {1};
      bins many = {[2:$]};
    }
    bank_direction_cross: cross bank_cp, direction_cp;
    bank_wait_cross: cross bank_cp, wait_cp;
    response_mapping_cross: cross response_cp, mapped_cp;
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    expected_imp = new("expected_imp", this);
    actual_imp = new("actual_imp", this);
    ahb_access_cg = new();
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ctrl_expected[0]   = 32'h0000_0000;
    ctrl_expected[1]   = 32'h0000_0000;
    status_expected[0] = 32'h0000_0001;
    status_expected[1] = 32'h0000_0002;
    data_expected[0]   = 32'h0000_0000;
    data_expected[1]   = 32'h0000_0000;
    config_expected[0] = 32'h0000_0000;
    config_expected[1] = 32'h0000_0000;
    observed_count = 0;
    compared_count = 0;
    mismatch_count = 0;
    check_active_stimulus = 1'b0;
  endfunction

  function int decode_bank(bit [31:0] addr);
    if ((addr & 32'hffff_f000) == 32'h0000_0000)
      return 0;
    if ((addr & 32'hffff_f000) == 32'h0001_0000)
      return 1;
    return -1;
  endfunction

  function bit valid_register_access(bit [31:0] addr, bit [2:0] size);
    int bank;
    bit valid_offset;

    bank = decode_bank(addr);
    valid_offset = addr[11:0] inside {
      12'h000, 12'h004, 12'h008, 12'h00c
    };
    return (bank >= 0) && (addr[1:0] == 2'b00) &&
           (size == 3'b010) && valid_offset;
  endfunction

  function int unsigned expected_wait_count(
    bit [31:0] addr,
    bit [2:0] size
  );
    int bank;
    bit error_expected;

    bank = decode_bank(addr);
    error_expected = !valid_register_access(addr, size);
    if (bank == 1)
      return error_expected ? 2 : 1;
    if (bank == 0)
      return error_expected ? 1 : 0;
    return 1;
  endfunction

  function bit [31:0] expected_read_data(int bank, bit [11:0] offset);
    case (offset)
      12'h000: return ctrl_expected[bank];
      12'h004: return status_expected[bank];
      12'h008: return data_expected[bank];
      12'h00c: return config_expected[bank];
      default: return 32'h0000_0000;
    endcase
  endfunction

  function void write_expected(ahb_transaction item);
    ahb_transaction copy;
    if (!$cast(copy, item.clone()))
      `uvm_fatal("AHB_CLONE", "Could not clone completed AHB request")
    expected_items.push_back(copy);
  endfunction

  function void write_actual(ahb_transaction item);
    ahb_transaction copy;
    int bank;
    bit error_expected;
    bit [31:0] expected_data;
    int unsigned expected_waits;

    if (!$cast(copy, item.clone()))
      `uvm_fatal("AHB_CLONE", "Could not clone observed AHB transaction")
    actual_items.push_back(copy);

    observed_count++;
    bank = decode_bank(item.addr);
    error_expected = !valid_register_access(item.addr, item.size);
    expected_waits = expected_wait_count(item.addr, item.size);

    sampled_write       = item.write;
    sampled_addr        = item.addr;
    sampled_bank        = bank;
    sampled_mapped      = (bank >= 0);
    sampled_resp        = item.resp;
    sampled_wait_cycles = item.wait_cycles;
    ahb_access_cg.sample();

    if (item.resp != error_expected) begin
      mismatch_count++;
      `uvm_error("AHB_RESP", $sformatf(
        "Address 0x%08h expected HRESP=%0b, observed %0b",
        item.addr, error_expected, item.resp))
    end

    if (item.wait_cycles != expected_waits) begin
      mismatch_count++;
      `uvm_error("AHB_WAIT_COUNT", $sformatf(
        "Address 0x%08h expected %0d stalled cycles, observed %0d",
        item.addr, expected_waits, item.wait_cycles))
    end

    if (error_expected)
      return;

    if (item.write) begin
      unique case (item.addr[11:0])
        12'h000: ctrl_expected[bank]   = item.wdata;
        12'h008: data_expected[bank]   = item.wdata;
        12'h00c: config_expected[bank] = item.wdata;
        default: ; // STATUS writes return OKAY and do not change state.
      endcase
    end else begin
      compared_count++;
      expected_data = expected_read_data(bank, item.addr[11:0]);
      if (item.rdata != expected_data) begin
        mismatch_count++;
        `uvm_error("AHB_READ_DATA", $sformatf(
          "Address 0x%08h expected 0x%08h, observed 0x%08h",
          item.addr, expected_data, item.rdata))
      end
    end
  endfunction

  function void check_phase(uvm_phase phase);
    int unsigned common_count;

    super.check_phase(phase);
    if (observed_count == 0)
      `uvm_error("AHB_ZERO_TRAFFIC", "Scoreboard observed no AHB transfers")
    if (compared_count == 0)
      `uvm_error("AHB_ZERO_COMPARE", "Scoreboard compared no successful reads")

    if (check_active_stimulus) begin
      if (expected_items.size() != actual_items.size()) begin
        mismatch_count++;
        `uvm_error("AHB_STREAM_COUNT", $sformatf(
          "Driver completed %0d requests, monitor observed %0d transfers",
          expected_items.size(), actual_items.size()))
      end

      common_count = (expected_items.size() < actual_items.size()) ?
                     expected_items.size() : actual_items.size();
      for (int unsigned index = 0; index < common_count; index++) begin
        if ((expected_items[index].write       != actual_items[index].write) ||
            (expected_items[index].addr        != actual_items[index].addr) ||
            (expected_items[index].size        != actual_items[index].size) ||
            (expected_items[index].write &&
             (expected_items[index].wdata != actual_items[index].wdata)) ||
            (expected_items[index].resp        != actual_items[index].resp) ||
            (expected_items[index].wait_cycles != actual_items[index].wait_cycles) ||
            (!expected_items[index].write &&
             (expected_items[index].rdata != actual_items[index].rdata))) begin
          mismatch_count++;
          `uvm_error("AHB_STREAM_MISMATCH", $sformatf(
            "Transfer %0d request={%s} observed={%s}", index,
            expected_items[index].convert2string(),
            actual_items[index].convert2string()))
        end
      end
    end
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("AHB_SCOREBOARD", $sformatf(
      "observed=%0d reads_compared=%0d mismatches=%0d coverage=%0.1f%%",
      observed_count, compared_count, mismatch_count,
      ahb_access_cg.get_inst_coverage()), UVM_NONE)
  endfunction
endclass
