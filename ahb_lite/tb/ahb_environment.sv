class ahb_environment extends uvm_env;
  `uvm_component_utils(ahb_environment)

  ahb_agent agent;
  ahb_scoreboard scoreboard;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = ahb_agent::type_id::create("agent", this);
    scoreboard = ahb_scoreboard::type_id::create("scoreboard", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.monitor_ap.connect(scoreboard.actual_imp);
    scoreboard.check_active_stimulus = (agent.cfg.is_active == UVM_ACTIVE);
    if (scoreboard.check_active_stimulus)
      agent.request_ap.connect(scoreboard.expected_imp);
  endfunction
endclass
