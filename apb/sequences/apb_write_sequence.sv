class apb_write_sequence extends uvm_sequence #(apb_transaction);
  `uvm_object_utils(apb_write_sequence)

  function new(string name = "apb_write_sequence");
    super.new(name);
  endfunction

  task body();
    send_transfer(1'b1, 32'h0000_0000, 32'h1111_1111, 1'b0);
    send_transfer(1'b0, 32'h0000_0000, 32'h0000_0000, 1'b0);
    send_transfer(1'b1, 32'h0000_0008, 32'h2222_2222, 1'b0);
    send_transfer(1'b0, 32'h0000_0008, 32'h0000_0000, 1'b0);
    send_transfer(1'b1, 32'h0000_000c, 32'h3333_3333, 1'b0);
    send_transfer(1'b0, 32'h0000_000c, 32'h0000_0000, 1'b0);

    // STATUS accepts the APB write but its read-only value must not change.
    send_transfer(1'b1, 32'h0000_0004, 32'hffff_ffff, 1'b0);
    send_transfer(1'b0, 32'h0000_0004, 32'h0000_0000, 1'b0);

    // Error injection is explicit; normal transaction randomization is legal.
    send_transfer(1'b1, 32'h0000_0010, 32'hdead_beef, 1'b1);
  endtask

  task send_transfer(bit is_write,
                     bit [31:0] address,
                     bit [31:0] write_data,
                     bit allow_invalid);
    apb_transaction item;
    item = apb_transaction::type_id::create("item");
    if (allow_invalid)
      item.legal_address_c.constraint_mode(0);
    if (is_write && (address == 32'h0000_0004))
      item.normal_write_c.constraint_mode(0);

    start_item(item);
    if (!item.randomize() with {
      item.write == is_write;
      item.addr  == address;
      item.wdata == write_data;
    })
      `uvm_fatal("APB_RANDOMIZE", "Directed write transaction randomization failed")
    finish_item(item);
  endtask
endclass

