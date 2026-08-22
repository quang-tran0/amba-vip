class ahb_read_sequence extends uvm_sequence #(ahb_transaction);
  `uvm_object_utils(ahb_read_sequence)

  function new(string name = "ahb_read_sequence");
    super.new(name);
  endfunction

  task body();
    send_read(32'h0000_0000, 1'b0);
    send_read(32'h0000_0004, 1'b0);
    send_read(32'h0000_0008, 1'b0);
    send_read(32'h0000_000c, 1'b0);
    send_read(32'h0001_0000, 1'b0);
    send_read(32'h0001_0004, 1'b0);
    send_read(32'h0001_0008, 1'b0);
    send_read(32'h0001_000c, 1'b0);
    send_read(32'h0000_0002, 1'b1);
    send_read(32'h0000_0010, 1'b1);
    send_read(32'h0001_0010, 1'b1);
    send_read(32'h2000_0000, 1'b1);
  endtask

  task send_read(bit [31:0] address, bit allow_invalid);
    ahb_transaction item;
    item = ahb_transaction::type_id::create("item");
    if (allow_invalid)
      item.legal_address_c.constraint_mode(0);

    start_item(item);
    if (!item.randomize() with {
      item.write == 1'b0;
      item.addr  == address;
      item.wdata == 32'h0000_0000;
      item.size  == 3'b010;
    })
      `uvm_fatal("AHB_RANDOMIZE", "Directed read transaction randomization failed")
    finish_item(item);
  endtask
endclass
