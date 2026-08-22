class ahb_read_test extends ahb_base_test;
  `uvm_component_utils(ahb_read_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    ahb_read_sequence seq;

    phase.raise_objection(this);
    seq = ahb_read_sequence::type_id::create("seq");
    seq.start(env.agent.sequencer);
    wait_for_scoreboard();
    phase.drop_objection(this);
  endtask
endclass
