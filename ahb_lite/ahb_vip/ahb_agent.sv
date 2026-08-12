class ahb_agent extends uvm_agent;
  `uvm_component_utils(ahb_agent)

  ahb_configuration cfg;
  ahb_sequencer sequencer;
  ahb_driver driver;
  ahb_monitor monitor;
  uvm_analysis_port #(ahb_transaction) monitor_ap;
  uvm_analysis_port #(ahb_transaction) request_ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    monitor_ap = new("monitor_ap", this);
    request_ap = new("request_ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(ahb_configuration)::get(this, "", "cfg", cfg))
      `uvm_fatal("AHB_CFG", "Agent configuration was not supplied")
    if ((cfg == null) || !cfg.is_valid())
      `uvm_fatal("AHB_VIF", "Agent configuration has a null virtual interface")

    uvm_config_db #(ahb_configuration)::set(this, "monitor", "cfg", cfg);
    monitor = ahb_monitor::type_id::create("monitor", this);

    if (cfg.is_active == UVM_ACTIVE) begin
      uvm_config_db #(ahb_configuration)::set(this, "driver", "cfg", cfg);
      sequencer = ahb_sequencer::type_id::create("sequencer", this);
      driver = ahb_driver::type_id::create("driver", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    monitor.analysis_port.connect(monitor_ap);
    if (cfg.is_active == UVM_ACTIVE) begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
      driver.request_ap.connect(request_ap);
    end
  endfunction
endclass
