class apb_driver extends uvm_driver #(apb_transaction);
  `uvm_component_utils(apb_driver)

  apb_configuration cfg;
  virtual apb_if vif;
  uvm_analysis_port #(apb_transaction) request_ap;
  bit completed_previous_transfer;
  time previous_completion_time;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    request_ap = new("request_ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(apb_configuration)::get(this, "", "cfg", cfg))
      `uvm_fatal("APB_CFG", "Driver configuration was not supplied")
    if ((cfg == null) || !cfg.is_valid())
      `uvm_fatal("APB_VIF", "Driver configuration has a null virtual interface")
    vif = cfg.vif;
  endfunction

  task run_phase(uvm_phase phase);
    drive_idle();
    completed_previous_transfer = 1'b0;
    previous_completion_time = 0;
    wait_for_reset_release();

    forever begin
      seq_item_port.get_next_item(req);
      if (vif.driver_cb.PRESETn !== 1'b1) begin
        completed_previous_transfer = 1'b0;
        wait_for_reset_release();
      end
      drive_transfer(req);
      seq_item_port.item_done();
    end
  endtask

  task drive_idle();
    vif.driver_cb.PADDR   <= '0;
    vif.driver_cb.PSEL    <= 1'b0;
    vif.driver_cb.PENABLE <= 1'b0;
    vif.driver_cb.PWRITE  <= 1'b0;
    vif.driver_cb.PWDATA  <= '0;
  endtask

  task wait_for_reset_release();
    do begin
      @(vif.driver_cb);
      drive_idle();
    end while (vif.driver_cb.PRESETn !== 1'b1);
  endtask

  task drive_transfer(apb_transaction item);
    item.rdata       = '0;
    item.slverr      = 1'b0;
    item.wait_cycles = 0;
    item.back_to_back = completed_previous_transfer &&
                        ($time == previous_completion_time);

    // SETUP starts immediately. If another item follows a completed access,
    // the idle assignments are overwritten in the same time step.
    vif.driver_cb.PADDR   <= item.addr;
    vif.driver_cb.PSEL    <= 1'b1;
    vif.driver_cb.PENABLE <= 1'b0;
    vif.driver_cb.PWRITE  <= item.write;
    vif.driver_cb.PWDATA  <= item.wdata;

    @(vif.driver_cb);
    if (vif.driver_cb.PRESETn !== 1'b1)
      `uvm_fatal("APB_RESET", "Reset asserted during an APB transfer")

    // ACCESS: all request fields remain unchanged until PREADY completes it.
    vif.driver_cb.PENABLE <= 1'b1;
    do begin
      @(vif.driver_cb);
      if (vif.driver_cb.PRESETn !== 1'b1)
        `uvm_fatal("APB_RESET", "Reset asserted during an APB transfer")
      if (vif.driver_cb.PREADY !== 1'b1)
        item.wait_cycles++;
    end while (vif.driver_cb.PREADY !== 1'b1);

    item.slverr = vif.driver_cb.PSLVERR;
    if (!item.write)
      item.rdata = vif.driver_cb.PRDATA;

    completed_previous_transfer = 1'b1;
    previous_completion_time = $time;
    request_ap.write(item);

    `uvm_info("APB_DRIVER", item.convert2string(), UVM_HIGH)

    drive_idle();
  endtask
endclass
