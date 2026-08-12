class ahb_transaction extends uvm_sequence_item;
  rand bit        write;
  rand bit [31:0] addr;
  rand bit [31:0] wdata;
  rand bit [2:0]  size;

  bit [31:0] rdata;
  bit        resp;
  int unsigned wait_cycles;

  constraint legal_address_c {
    addr inside {
      32'h0000_0000, 32'h0000_0004, 32'h0000_0008, 32'h0000_000c,
      32'h0001_0000, 32'h0001_0004, 32'h0001_0008, 32'h0001_000c
    };
  }

  constraint word_size_c { size == 3'b010; }

  constraint normal_write_c {
    write -> !(addr inside {32'h0000_0004, 32'h0001_0004});
  }

  `uvm_object_utils_begin(ahb_transaction)
    `uvm_field_int(write,       UVM_ALL_ON)
    `uvm_field_int(addr,        UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(wdata,       UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(size,        UVM_ALL_ON)
    `uvm_field_int(rdata,       UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(resp,        UVM_ALL_ON)
    `uvm_field_int(wait_cycles, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "ahb_transaction");
    super.new(name);
  endfunction

  function string convert2string();
    return $sformatf(
      "%s addr=0x%08h size=%0d wdata=0x%08h rdata=0x%08h resp=%0b wait=%0d",
      write ? "WRITE" : "READ", addr, size, wdata, rdata, resp, wait_cycles
    );
  endfunction
endclass
