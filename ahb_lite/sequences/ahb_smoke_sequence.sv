class ahb_smoke_sequence extends uvm_sequence #(ahb_transaction);
  `uvm_object_utils(ahb_smoke_sequence)

  function new(string name = "ahb_smoke_sequence");
    super.new(name);
  endfunction

  task body();
    send_transfer(1'b0, 32'h0000_0004, 32'h0000_0000, 1'b0);
    send_transfer(1'b0, 32'h0001_0004, 32'h0000_0000, 1'b0);

    send_transfer(1'b1, 32'h0000_0000, 32'h1234_5678, 1'b0);
    send_transfer(1'b0, 32'h0000_0000, 32'h0000_0000, 1'b0);
    send_transfer(1'b1, 32'h0001_0000, 32'ha5a5_5a5a, 1'b0);
    send_transfer(1'b0, 32'h0001_0000, 32'h0000_0000, 1'b0);
    send_transfer(1'b0, 32'h0000_0000, 32'h0000_0000, 1'b0);

    send_transfer(1'b1, 32'h0000_0008, 32'h1111_1111, 1'b0);
    send_transfer(1'b0, 32'h0000_0008, 32'h0000_0000, 1'b0);
    send_transfer(1'b1, 32'h0001_0008, 32'h2222_2222, 1'b0);
    send_transfer(1'b0, 32'h0001_0008, 32'h0000_0000, 1'b0);

    send_transfer(1'b0, 32'h2000_0000, 32'h0000_0000, 1'b1);
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
      `uvm_fatal("AHB_RANDOMIZE", "Smoke transaction randomization failed")
    finish_item(item);
  endtask
endclass
