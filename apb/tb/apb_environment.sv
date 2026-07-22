class apb_environment extends uvm_env;
  `uvm_component_utils(apb_environment)

  apb_agent agent;
  apb_scoreboard scoreboard;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = apb_agent::type_id::create("agent", this);
    scoreboard = apb_scoreboard::type_id::create("scoreboard", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.monitor_ap.connect(scoreboard.actual_imp);
  endfunction
endclass

