class ahb_monitor extends uvm_monitor;
  `uvm_component_utils(ahb_monitor)

  ahb_configuration cfg;
  virtual ahb_if vif;
  uvm_analysis_port #(ahb_transaction) analysis_port;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    analysis_port = new("analysis_port", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(ahb_configuration)::get(this, "", "cfg", cfg))
      `uvm_fatal("AHB_CFG", "Monitor configuration was not supplied")
    if ((cfg == null) || !cfg.is_valid())
      `uvm_fatal("AHB_VIF", "Monitor configuration has a null virtual interface")
    vif = cfg.vif;
  endfunction

  task run_phase(uvm_phase phase);
    ahb_transaction pending;

    pending = null;
    forever begin
      @(vif.monitor_cb);

      if (vif.monitor_cb.HRESETn !== 1'b1) begin
        pending = null;
        continue;
      end

      // HREADY completes the pending data phase and simultaneously qualifies
      // acceptance of the current address phase.
      if (pending != null) begin
        if (vif.monitor_cb.HREADY === 1'b1) begin
          pending.resp = vif.monitor_cb.HRESP;
          if (pending.write)
            pending.wdata = vif.monitor_cb.HWDATA;
          else
            pending.rdata = vif.monitor_cb.HRDATA;

          `uvm_info("AHB_MONITOR", pending.convert2string(), UVM_HIGH)
          analysis_port.write(pending);
          pending = null;
        end else begin
          pending.wait_cycles++;
        end
      end

      if ((vif.monitor_cb.HREADY === 1'b1) &&
          (vif.monitor_cb.HTRANS[1] === 1'b1)) begin
        pending = ahb_transaction::type_id::create("observed_item");
        pending.write        = vif.monitor_cb.HWRITE;
        pending.addr         = vif.monitor_cb.HADDR;
        pending.size         = vif.monitor_cb.HSIZE;
        pending.wdata        = 32'h0000_0000;
        pending.rdata        = 32'h0000_0000;
        pending.resp         = 1'b0;
        pending.wait_cycles  = 0;
      end
    end
  endtask
endclass
