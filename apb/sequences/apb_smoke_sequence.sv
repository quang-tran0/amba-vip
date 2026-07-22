class apb_smoke_sequence extends uvm_sequence #(apb_transaction);
  `uvm_object_utils(apb_smoke_sequence)

  function new(string name = "apb_smoke_sequence");
    super.new(name);
  endfunction

  task body();
    send_transfer(1'b1, 32'h0000_0000, 32'h1234_5678);
    send_transfer(1'b0, 32'h0000_0000, 32'h0000_0000);
    send_transfer(1'b1, 32'h0000_0008, 32'ha5a5_5a5a);
    send_transfer(1'b0, 32'h0000_0008, 32'h0000_0000);
    send_transfer(1'b0, 32'h0000_0004, 32'h0000_0000);
  endtask

  task send_transfer(bit is_write,
                     bit [31:0] address,
                     bit [31:0] write_data);
    apb_transaction item;
    item = apb_transaction::type_id::create("item");
    start_item(item);
    if (!item.randomize() with {
      item.write == is_write;
      item.addr  == address;
      item.wdata == write_data;
    })
      `uvm_fatal("APB_RANDOMIZE", "Smoke transaction randomization failed")
    finish_item(item);
  endtask
endclass
