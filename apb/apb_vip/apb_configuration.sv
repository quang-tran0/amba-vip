class apb_configuration extends uvm_object;
  virtual apb_if vif;
  uvm_active_passive_enum is_active = UVM_ACTIVE;

  `uvm_object_utils_begin(apb_configuration)
    `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "apb_configuration");
    super.new(name);
  endfunction

  function bit is_valid();
    return vif != null;
  endfunction
endclass

