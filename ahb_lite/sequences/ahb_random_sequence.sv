class ahb_random_sequence extends uvm_sequence #(ahb_transaction);
  `uvm_object_utils(ahb_random_sequence)

  int unsigned num_items = 20;

  function new(string name = "ahb_random_sequence");
    super.new(name);
  endfunction

  task body();
    if (num_items == 0)
      `uvm_fatal("AHB_NUM_ITEMS", "NUM_ITEMS must be greater than zero")

    for (int unsigned index = 0; index < num_items; index++) begin
      ahb_transaction item;
      item = ahb_transaction::type_id::create($sformatf("item_%0d", index));
      start_item(item);
      if (index == 0) begin
        if (!item.randomize() with { item.write == 1'b0; })
          `uvm_fatal("AHB_RANDOMIZE", "Initial random read failed to randomize")
      end else if (!item.randomize()) begin
        `uvm_fatal("AHB_RANDOMIZE", "Random AHB transaction failed to randomize")
      end
      finish_item(item);
    end
  endtask
endclass
