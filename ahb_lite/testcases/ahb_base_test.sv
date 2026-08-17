class ahb_base_test extends uvm_test;
  `uvm_component_utils(ahb_base_test)

  ahb_configuration cfg;
  ahb_environment env;
  int unsigned num_items = 20;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void configure();
    cfg.is_active = UVM_ACTIVE;
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    cfg = ahb_configuration::type_id::create("cfg");
    if (!uvm_config_db #(virtual ahb_if)::get(this, "", "vif", cfg.vif))
      `uvm_fatal("AHB_VIF", "Virtual AHB interface was not supplied by testbench")

    configure();
    void'($value$plusargs("NUM_ITEMS=%d", num_items));
    uvm_config_db #(ahb_configuration)::set(this, "env.agent", "cfg", cfg);
    env = ahb_environment::type_id::create("env", this);
  endfunction

  task wait_for_scoreboard();
    repeat (2) @(cfg.vif.monitor_cb);
  endtask

  function void report_phase(uvm_phase phase);
    uvm_report_server server;

    super.report_phase(phase);
    server = uvm_report_server::get_server();
    if ((server.get_severity_count(UVM_ERROR) == 0) &&
        (server.get_severity_count(UVM_FATAL) == 0) &&
        (env.scoreboard.observed_count > 0) &&
        (env.scoreboard.compared_count > 0) &&
        (env.scoreboard.mismatch_count == 0))
      `uvm_info("TEST_STATUS", "TEST PASSED", UVM_NONE)
    else
      `uvm_error("TEST_STATUS", "TEST FAILED")
  endfunction
endclass
