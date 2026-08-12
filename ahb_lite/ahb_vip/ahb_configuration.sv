class ahb_configuration extends uvm_object;
  virtual ahb_if vif;
  uvm_active_passive_enum is_active = UVM_ACTIVE;

  `uvm_object_utils_begin(ahb_configuration)
    `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "ahb_configuration");
    super.new(name);
  endfunction

  function bit is_valid();
    return vif != null;
  endfunction
endclass
