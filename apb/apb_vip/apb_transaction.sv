class apb_transaction extends uvm_sequence_item;
  rand bit        write;
  rand bit [31:0] addr;
  rand bit [31:0] wdata;

  bit [31:0] rdata;
  bit        slverr;
  int unsigned wait_cycles;
  bit          back_to_back;

  constraint legal_address_c {
    addr inside {32'h0000_0000, 32'h0000_0004,
                 32'h0000_0008, 32'h0000_000c};
  }

  constraint normal_write_c {
    write -> addr != 32'h0000_0004;
  }

  `uvm_object_utils_begin(apb_transaction)
    `uvm_field_int(write,        UVM_ALL_ON)
    `uvm_field_int(addr,         UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(wdata,        UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(rdata,        UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(slverr,       UVM_ALL_ON)
    `uvm_field_int(wait_cycles,  UVM_ALL_ON)
    `uvm_field_int(back_to_back, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "apb_transaction");
    super.new(name);
  endfunction

  function string convert2string();
    return $sformatf(
      "%s addr=0x%08h wdata=0x%08h rdata=0x%08h slverr=%0b wait=%0d b2b=%0b",
      write ? "WRITE" : "READ", addr, wdata, rdata, slverr,
      wait_cycles, back_to_back
    );
  endfunction
endclass

