class ahb_interconnect_test extends ahb_base_test;
  `uvm_component_utils(ahb_interconnect_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    ahb_interconnect_sequence seq;

    phase.raise_objection(this);
    seq = ahb_interconnect_sequence::type_id::create("seq");
    seq.start(env.agent.sequencer);
    wait_for_scoreboard();
    phase.drop_objection(this);
  endtask
endclass
