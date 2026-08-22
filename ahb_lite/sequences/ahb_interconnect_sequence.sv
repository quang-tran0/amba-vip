class ahb_interconnect_sequence extends uvm_sequence #(ahb_transaction);
  `uvm_object_utils(ahb_interconnect_sequence)

  function new(string name = "ahb_interconnect_sequence");
    super.new(name);
  endfunction

  task body();
    send_transfer(1'b1, 32'h0000_0000, 32'h1111_1111, 1'b0);
    send_transfer(1'b1, 32'h0001_0000, 32'h2222_2222, 1'b0);
    send_transfer(1'b1, 32'h0000_0008, 32'h3333_3333, 1'b0);
    send_transfer(1'b1, 32'h0001_0008, 32'h4444_4444, 1'b0);

    send_transfer(1'b0, 32'h0000_0000, 32'h0000_0000, 1'b0);
    send_transfer(1'b0, 32'h0001_0000, 32'h0000_0000, 1'b0);
    send_transfer(1'b0, 32'h0000_0008, 32'h0000_0000, 1'b0);
    send_transfer(1'b0, 32'h0001_0008, 32'h0000_0000, 1'b0);
    send_transfer(1'b0, 32'h0000_0004, 32'h0000_0000, 1'b0);
    send_transfer(1'b0, 32'h0001_0004, 32'h0000_0000, 1'b0);

    send_transfer(1'b0, 32'hffff_0000, 32'h0000_0000, 1'b1);
    send_transfer(1'b0, 32'h0000_0000, 32'h0000_0000, 1'b0);
    send_transfer(1'b0, 32'h0001_0000, 32'h0000_0000, 1'b0);
  endtask

  task send_transfer(bit is_write,
                     bit [31:0] address,
                     bit [31:0] write_data,
                     bit allow_invalid);
    ahb_transaction item;
    item = ahb_transaction::type_id::create("item");
    if (allow_invalid)
      item.legal_address_c.constraint_mode(0);

    start_item(item);
    if (!item.randomize() with {
      item.write == is_write;
      item.addr  == address;
      item.wdata == write_data;
      item.size  == 3'b010;
    })
      `uvm_fatal("AHB_RANDOMIZE", "Interconnect transaction randomization failed")
    finish_item(item);
  endtask
endclass
