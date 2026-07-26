class apb_read_sequence extends uvm_sequence #(apb_transaction);
  `uvm_object_utils(apb_read_sequence)

  function new(string name = "apb_read_sequence");
    super.new(name);
  endfunction

  task body();
    send_read(32'h0000_0000, 1'b0);
    send_read(32'h0000_0004, 1'b0);
    send_read(32'h0000_0008, 1'b0);
    send_read(32'h0000_000c, 1'b0);
    send_read(32'h0000_0002, 1'b1);
    send_read(32'h0000_0010, 1'b1);
  endtask

  task send_read(bit [31:0] address, bit allow_invalid);
    apb_transaction item;
    item = apb_transaction::type_id::create("item");
    if (allow_invalid)
      item.legal_address_c.constraint_mode(0);

    start_item(item);
    if (!item.randomize() with {
      item.write == 1'b0;
      item.addr  == address;
      item.wdata == 32'h0000_0000;
    })
      `uvm_fatal("APB_RANDOMIZE", "Directed read transaction randomization failed")
    finish_item(item);
  endtask
endclass

