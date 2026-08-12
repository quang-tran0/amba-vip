class ahb_driver extends uvm_driver #(ahb_transaction);
  `uvm_component_utils(ahb_driver)

  ahb_configuration cfg;
  virtual ahb_if vif;
  uvm_analysis_port #(ahb_transaction) request_ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    request_ap = new("request_ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(ahb_configuration)::get(this, "", "cfg", cfg))
      `uvm_fatal("AHB_CFG", "Driver configuration was not supplied")
    if ((cfg == null) || !cfg.is_valid())
      `uvm_fatal("AHB_VIF", "Driver configuration has a null virtual interface")
    vif = cfg.vif;
  endfunction

  task run_phase(uvm_phase phase);
    drive_idle();
    wait_for_reset_release();

    forever begin
      seq_item_port.get_next_item(req);
      if (vif.driver_cb.HRESETn !== 1'b1)
        wait_for_reset_release();
      drive_transfer(req);
      seq_item_port.item_done();
    end
  endtask

  task drive_idle();
    vif.driver_cb.HADDR  <= 32'h0000_0000;
    vif.driver_cb.HTRANS <= 2'b00;
    vif.driver_cb.HWRITE <= 1'b0;
    vif.driver_cb.HSIZE  <= 3'b010;
    vif.driver_cb.HBURST <= 3'b000;
    vif.driver_cb.HWDATA <= 32'h0000_0000;
  endtask

  task wait_for_reset_release();
    do begin
      @(vif.driver_cb);
      drive_idle();
    end while (vif.driver_cb.HRESETn !== 1'b1);
  endtask

  task drive_transfer(ahb_transaction item);
    item.rdata       = 32'h0000_0000;
    item.resp        = 1'b0;
    item.wait_cycles = 0;

    // Address phase. Control remains asserted until HREADY accepts it.
    vif.driver_cb.HADDR  <= item.addr;
    vif.driver_cb.HTRANS <= 2'b10;
    vif.driver_cb.HWRITE <= item.write;
    vif.driver_cb.HSIZE  <= item.size;
    vif.driver_cb.HBURST <= 3'b000;
    vif.driver_cb.HWDATA <= 32'h0000_0000;

    do begin
      @(vif.driver_cb);
      if (vif.driver_cb.HRESETn !== 1'b1)
        `uvm_fatal("AHB_RESET", "Reset asserted during an AHB transfer")
    end while (vif.driver_cb.HREADY !== 1'b1);

    // Data phase. There is deliberately no next outstanding transfer yet.
    vif.driver_cb.HADDR  <= 32'h0000_0000;
    vif.driver_cb.HTRANS <= 2'b00;
    vif.driver_cb.HWRITE <= 1'b0;
    vif.driver_cb.HSIZE  <= 3'b010;
    vif.driver_cb.HBURST <= 3'b000;
    vif.driver_cb.HWDATA <= item.write ? item.wdata : 32'h0000_0000;

    do begin
      @(vif.driver_cb);
      if (vif.driver_cb.HRESETn !== 1'b1)
        `uvm_fatal("AHB_RESET", "Reset asserted during an AHB transfer")
      if (vif.driver_cb.HREADY !== 1'b1)
        item.wait_cycles++;
    end while (vif.driver_cb.HREADY !== 1'b1);

    item.resp = vif.driver_cb.HRESP;
    if (!item.write)
      item.rdata = vif.driver_cb.HRDATA;

    request_ap.write(item);
    `uvm_info("AHB_DRIVER", item.convert2string(), UVM_HIGH)
    drive_idle();
  endtask
endclass
