class ahb_pipeline_test extends ahb_base_test;
  `uvm_component_utils(ahb_pipeline_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void configure();
    cfg.is_active = UVM_PASSIVE;
  endfunction

  task drive_idle();
    cfg.vif.driver_cb.HADDR  <= 32'h0000_0000;
    cfg.vif.driver_cb.HTRANS <= 2'b00;
    cfg.vif.driver_cb.HWRITE <= 1'b0;
    cfg.vif.driver_cb.HSIZE  <= 3'b010;
    cfg.vif.driver_cb.HBURST <= 3'b000;
    cfg.vif.driver_cb.HWDATA <= 32'h0000_0000;
  endtask

  task wait_for_reset_release();
    drive_idle();
    do @(cfg.vif.driver_cb);
    while (cfg.vif.driver_cb.HRESETn !== 1'b1);
  endtask

  task drive_address(bit write, bit [31:0] addr);
    cfg.vif.driver_cb.HADDR  <= addr;
    cfg.vif.driver_cb.HTRANS <= 2'b10;
    cfg.vif.driver_cb.HWRITE <= write;
    cfg.vif.driver_cb.HSIZE  <= 3'b010;
    cfg.vif.driver_cb.HBURST <= 3'b000;
  endtask

  task drive_pair(bit write_a,
                  bit [31:0] addr_a,
                  bit [31:0] data_a,
                  bit write_b,
                  bit [31:0] addr_b,
                  bit [31:0] data_b);
    drive_address(write_a, addr_a);
    do @(cfg.vif.driver_cb);
    while (cfg.vif.driver_cb.HREADY !== 1'b1);

    // B's address phase overlaps A's data phase. HWDATA still belongs to A.
    drive_address(write_b, addr_b);
    cfg.vif.driver_cb.HWDATA <= write_a ? data_a : 32'h0000_0000;
    do @(cfg.vif.driver_cb);
    while (cfg.vif.driver_cb.HREADY !== 1'b1);

    // B is now in its data phase; no third address is outstanding.
    cfg.vif.driver_cb.HADDR  <= 32'h0000_0000;
    cfg.vif.driver_cb.HTRANS <= 2'b00;
    cfg.vif.driver_cb.HWRITE <= 1'b0;
    cfg.vif.driver_cb.HSIZE  <= 3'b010;
    cfg.vif.driver_cb.HBURST <= 3'b000;
    cfg.vif.driver_cb.HWDATA <= write_b ? data_b : 32'h0000_0000;
    do @(cfg.vif.driver_cb);
    while (cfg.vif.driver_cb.HREADY !== 1'b1);

    drive_idle();
  endtask

  task drive_error_and_cancel();
    drive_address(1'b0, 32'hffff_0000);
    do @(cfg.vif.driver_cb);
    while (cfg.vif.driver_cb.HREADY !== 1'b1);

    // This speculative next address must be cancelled during ERROR cycle one.
    drive_address(1'b0, 32'h0001_0004);
    @(cfg.vif.driver_cb);
    if ((cfg.vif.driver_cb.HRESP !== 1'b1) ||
        (cfg.vif.driver_cb.HREADY !== 1'b0))
      `uvm_error("AHB_ERROR_TIMING",
        "First ERROR cycle was not HRESP=1/HREADY=0")
    drive_idle();

    @(cfg.vif.driver_cb);
    if ((cfg.vif.driver_cb.HRESP !== 1'b1) ||
        (cfg.vif.driver_cb.HREADY !== 1'b1))
      `uvm_error("AHB_ERROR_TIMING",
        "Final ERROR cycle was not HRESP=1/HREADY=1")
    drive_idle();
  endtask

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    wait_for_reset_release();

    // Cross-bank A->B, including a wait-state data phase in Bank1.
    drive_pair(1'b0, 32'h0000_0004, 32'h0000_0000,
               1'b0, 32'h0001_0004, 32'h0000_0000);

    // Cross-bank B->A: Bank0 address/control must hold while Bank1 stalls.
    drive_pair(1'b0, 32'h0001_0004, 32'h0000_0000,
               1'b0, 32'h0000_0004, 32'h0000_0000);

    // Same-bank write/read overlap checks data-phase HWDATA association.
    drive_pair(1'b1, 32'h0000_0000, 32'h5151_5151,
               1'b0, 32'h0000_0000, 32'h0000_0000);
    drive_pair(1'b1, 32'h0001_0008, 32'ha5a5_5a5a,
               1'b0, 32'h0001_0008, 32'h0000_0000);

    drive_error_and_cancel();

    // No cancelled address may appear as a ghost transaction.
    drive_pair(1'b0, 32'h0000_0000, 32'h0000_0000,
               1'b0, 32'h0001_0008, 32'h0000_0000);

    wait_for_scoreboard();
    if (env.scoreboard.observed_count != 11)
      `uvm_error("AHB_PIPELINE_COUNT", $sformatf(
        "Expected 11 completed transfers, monitor published %0d",
        env.scoreboard.observed_count))
    if (env.scoreboard.compared_count != 8)
      `uvm_error("AHB_PIPELINE_COUNT", $sformatf(
        "Expected 8 successful read comparisons, scoreboard performed %0d",
        env.scoreboard.compared_count))
    phase.drop_objection(this);
  endtask
endclass
