class ahb_write_sequence extends uvm_sequence #(ahb_transaction);
  `uvm_object_utils(ahb_write_sequence)

  function new(string name = "ahb_write_sequence");
    super.new(name);
  endfunction

  task body();
    send_transfer(1'b1, 32'h0000_0000, 32'h1010_0001, 1'b0, 1'b0);
    send_transfer(1'b0, 32'h0000_0000, 32'h0000_0000, 1'b0, 1'b0);
    send_transfer(1'b1, 32'h0000_0008, 32'h1010_0008, 1'b0, 1'b0);
    send_transfer(1'b0, 32'h0000_0008, 32'h0000_0000, 1'b0, 1'b0);
    send_transfer(1'b1, 32'h0000_000c, 32'h1010_000c, 1'b0, 1'b0);
    send_transfer(1'b0, 32'h0000_000c, 32'h0000_0000, 1'b0, 1'b0);

    send_transfer(1'b1, 32'h0001_0000, 32'h2020_0001, 1'b0, 1'b0);
    send_transfer(1'b0, 32'h0001_0000, 32'h0000_0000, 1'b0, 1'b0);
    send_transfer(1'b1, 32'h0001_0008, 32'h2020_0008, 1'b0, 1'b0);
    send_transfer(1'b0, 32'h0001_0008, 32'h0000_0000, 1'b0, 1'b0);
    send_transfer(1'b1, 32'h0001_000c, 32'h2020_000c, 1'b0, 1'b0);
    send_transfer(1'b0, 32'h0001_000c, 32'h0000_0000, 1'b0, 1'b0);

    // STATUS writes complete with OKAY but must not change either register.
    send_transfer(1'b1, 32'h0000_0004, 32'hffff_ffff, 1'b0, 1'b1);
    send_transfer(1'b0, 32'h0000_0004, 32'h0000_0000, 1'b0, 1'b0);
    send_transfer(1'b1, 32'h0001_0004, 32'hffff_ffff, 1'b0, 1'b1);
    send_transfer(1'b0, 32'h0001_0004, 32'h0000_0000, 1'b0, 1'b0);

    send_transfer(1'b1, 32'h0000_0010, 32'hdead_beef, 1'b1, 1'b0);
    send_transfer(1'b1, 32'h0001_0010, 32'hcafe_f00d, 1'b1, 1'b0);
  endtask

  task send_transfer(bit is_write,
                     bit [31:0] address,
                     bit [31:0] write_data,
                     bit allow_invalid,
                     bit allow_status_write);
    ahb_transaction item;
    item = ahb_transaction::type_id::create("item");
    if (allow_invalid)
      item.legal_address_c.constraint_mode(0);
    if (allow_status_write)
      item.normal_write_c.constraint_mode(0);

    start_item(item);
    if (!item.randomize() with {
      item.write == is_write;
      item.addr  == address;
      item.wdata == write_data;
      item.size  == 3'b010;
    })
      `uvm_fatal("AHB_RANDOMIZE", "Directed write transaction randomization failed")
    finish_item(item);
  endtask
endclass
