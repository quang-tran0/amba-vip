class apb_write_test extends apb_base_test;
  `uvm_component_utils(apb_write_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    apb_write_sequence seq;

    phase.raise_objection(this);
    seq = apb_write_sequence::type_id::create("seq");
    seq.start(env.agent.sequencer);
    wait_for_scoreboard();
    phase.drop_objection(this);
  endtask
endclass

