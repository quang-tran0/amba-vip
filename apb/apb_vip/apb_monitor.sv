class apb_monitor extends uvm_monitor;
  `uvm_component_utils(apb_monitor)

  apb_configuration cfg;
  virtual apb_if vif;
  uvm_analysis_port #(apb_transaction) analysis_port;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    analysis_port = new("analysis_port", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(apb_configuration)::get(this, "", "cfg", cfg))
      `uvm_fatal("APB_CFG", "Monitor configuration was not supplied")
    if ((cfg == null) || !cfg.is_valid())
      `uvm_fatal("APB_VIF", "Monitor configuration has a null virtual interface")
    vif = cfg.vif;
  endfunction

  task run_phase(uvm_phase phase);
    int unsigned wait_cycles;
    bit in_transfer;
    bit previous_completed;
    bit current_back_to_back;
    bit completed;

    wait_cycles = 0;
    in_transfer = 1'b0;
    previous_completed = 1'b0;
    current_back_to_back = 1'b0;

    forever begin
      @(vif.monitor_cb);

      if (vif.monitor_cb.PRESETn !== 1'b1) begin
        wait_cycles = 0;
        in_transfer = 1'b0;
        previous_completed = 1'b0;
        current_back_to_back = 1'b0;
        continue;
      end

      completed = vif.monitor_cb.PSEL && vif.monitor_cb.PENABLE &&
                  vif.monitor_cb.PREADY;

      if (vif.monitor_cb.PSEL && !vif.monitor_cb.PENABLE) begin
        wait_cycles = 0;
        in_transfer = 1'b1;
        current_back_to_back = previous_completed;
      end else if (in_transfer && vif.monitor_cb.PSEL &&
                   vif.monitor_cb.PENABLE && !vif.monitor_cb.PREADY) begin
        wait_cycles++;
      end

      if (completed) begin
        apb_transaction item;
        item = apb_transaction::type_id::create("observed_item");
        item.write        = vif.monitor_cb.PWRITE;
        item.addr         = vif.monitor_cb.PADDR;
        item.wdata        = vif.monitor_cb.PWDATA;
        item.rdata        = vif.monitor_cb.PRDATA;
        item.slverr       = vif.monitor_cb.PSLVERR;
        item.wait_cycles  = wait_cycles;
        item.back_to_back = current_back_to_back;

        `uvm_info("APB_MONITOR", item.convert2string(), UVM_HIGH)
        analysis_port.write(item);
        in_transfer = 1'b0;
      end

      previous_completed = completed;
    end
  endtask
endclass

