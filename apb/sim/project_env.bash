#!/usr/bin/env bash

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export APB_VERIF_ROOT="$(cd -- "$script_dir/.." && pwd)"
export APB_VIP_ROOT="$APB_VERIF_ROOT/apb_vip"

if command -v vlog >/dev/null 2>&1; then
  questa_bin_dir="$(cd -- "$(dirname -- "$(command -v vlog)")" && pwd)"
  export QUESTA_HOME="${QUESTA_HOME:-$(cd -- "$questa_bin_dir/.." && pwd)}"
  export UVM_HOME="${UVM_HOME:-$QUESTA_HOME/verilog_src/uvm-1.2}"
  unset questa_bin_dir
fi

unset script_dir

