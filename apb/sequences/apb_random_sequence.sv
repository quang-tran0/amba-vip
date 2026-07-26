class apb_random_sequence extends uvm_sequence #(apb_transaction);
  `uvm_object_utils(apb_random_sequence)

  int unsigned num_items = 20;

  function new(string name = "apb_random_sequence");
    super.new(name);
  endfunction

  task body();
    if (num_items == 0)
      `uvm_fatal("APB_NUM_ITEMS", "NUM_ITEMS must be greater than zero")

    for (int unsigned index = 0; index < num_items; index++) begin
      apb_transaction item;
      item = apb_transaction::type_id::create($sformatf("item_%0d", index));
      start_item(item);
      if (index == 0) begin
        if (!item.randomize() with { item.write == 1'b0; })
          `uvm_fatal("APB_RANDOMIZE", "Initial random read failed to randomize")
      end else if (!item.randomize()) begin
        `uvm_fatal("APB_RANDOMIZE", "Random APB transaction failed to randomize")
      end
      finish_item(item);
    end
  endtask
endclass

