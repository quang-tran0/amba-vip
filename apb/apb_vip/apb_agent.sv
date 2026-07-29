class apb_agent extends uvm_agent;
  `uvm_component_utils(apb_agent)

  apb_configuration cfg;
  apb_sequencer sequencer;
  apb_driver driver;
  apb_monitor monitor;
  uvm_analysis_port #(apb_transaction) monitor_ap;
  uvm_analysis_port #(apb_transaction) request_ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    monitor_ap = new("monitor_ap", this);
    request_ap = new("request_ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(apb_configuration)::get(this, "", "cfg", cfg))
      `uvm_fatal("APB_CFG", "Agent configuration was not supplied")
    if ((cfg == null) || !cfg.is_valid())
      `uvm_fatal("APB_VIF", "Agent configuration has a null virtual interface")

    uvm_config_db #(apb_configuration)::set(this, "monitor", "cfg", cfg);
    monitor = apb_monitor::type_id::create("monitor", this);

    if (cfg.is_active == UVM_ACTIVE) begin
      uvm_config_db #(apb_configuration)::set(this, "driver", "cfg", cfg);
      sequencer = apb_sequencer::type_id::create("sequencer", this);
      driver = apb_driver::type_id::create("driver", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    monitor.analysis_port.connect(monitor_ap);
    if (cfg.is_active == UVM_ACTIVE)
      driver.seq_item_port.connect(sequencer.seq_item_export);
    if (cfg.is_active == UVM_ACTIVE)
      driver.request_ap.connect(request_ap);
  endfunction
endclass
