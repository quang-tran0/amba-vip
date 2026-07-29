# APB UVM VIP

A compact APB master VIP and self-checking UVM 1.2 environment for learning
AMBA design verification with QuestaSim.

## Supported APB subset

The VIP supports one 32-bit APB slave with:

- Read and write transfers
- Setup and access phases
- `PREADY` wait states
- `PSLVERR` responses
- Back-to-back transfers
- ACTIVE and PASSIVE agent modes

The interface contains focused protocol assertions for `PSEL`/`PENABLE`
sequencing and request stability during wait states. The project scoreboard
collects functional coverage for direction, register address, errors, wait
states, back-to-back transfers, and address-by-direction.

## Demo DUT

`rtl/apb_reg_bank.sv` is a small synthesizable target used to validate the
VIP. Its `WAIT_STATES` parameter defaults to one.

| Address | Register | Access | Reset value |
|---|---|---|---|
| `0x00` | CTRL | RW | `0x00000000` |
| `0x04` | STATUS | RO | `0x00000001` |
| `0x08` | DATA | RW | `0x00000000` |
| `0x0C` | CONFIG | RW | `0x00000000` |

Writes to STATUS complete without an error and do not change its value.
Unsupported and misaligned addresses complete with `PSLVERR=1`.

## Directory layout

```text
apb/
├── rtl/          # Demo APB slave register bank
├── apb_vip/      # Reusable interface, transaction, agent, driver, monitor
├── sequences/    # Smoke, directed, and random traffic
├── tb/           # Project environment, scoreboard, coverage, HDL top
├── testcases/    # Base and derived UVM tests
└── sim/           # Questa file lists, Makefile, regression flow
```

The compile order is `RTL → interface/VIP → environment/sequences → tests →
testbench`. Each UVM class is included only by its layer package.

## Prerequisites

- QuestaSim with `vlog`, `vlib`, `vmap`, `vsim`, and `vcover` on `PATH`
- The Questa bundled UVM 1.2 library
- GNU Make, Perl, and the GNU coreutils `timeout` command for regression
- A valid simulator license

`sim/project_env.bash` discovers the Questa and UVM locations from `vlog`.
Source it for interactive work when desired:

```bash
cd apb/sim
source ./project_env.bash
```

## Build and run

Commands may be run from the repository root:

```bash
make -C apb/sim clean
make -C apb/sim build
make -C apb/sim run \
  TESTNAME=apb_smoke_test \
  SEED=1 \
  VERBOSITY=UVM_HIGH
```

`make all` performs build then run sequentially:

```bash
make -C apb/sim all TESTNAME=apb_smoke_test SEED=1
```

Available tests are `apb_smoke_test`, `apb_write_test`, `apb_read_test`, and
`apb_random_test`. Configure random traffic with `NUM_ITEMS`:

```bash
make -C apb/sim run \
  TESTNAME=apb_random_test \
  SEED=42 \
  RUNARG=+NUM_ITEMS=100
```

The latest transcript is linked as `sim/run.log`. A passing test contains one
`TEST PASSED` marker and no UVM errors or fatals.

## Regression and coverage

Run the configured regression from `apb/sim`:

```bash
cd apb/sim
./regress.pl
./regress.pl -r
```

The first command builds once and runs smoke, directed, and random tests. The
second rebuilds `regress.rpt` from archived logs without rerunning simulation.

Coverage must be enabled for both build and run:

```bash
make clean
make build COV=ON
make run COV=ON TESTNAME=apb_smoke_test SEED=1
make cov_gui COV=ON TESTNAME=apb_smoke_test SEED=1
```

Merge several coverage databases with `make cov_merge`.

## Waveforms

Each run archives a test-and-seed-specific WLF under `sim/log/`. Open the most
recent waveform with:

```bash
make -C apb/sim wave
```

## Known limitations

This first version has one master, one slave, fixed 32-bit address/data widths,
and single non-pipelined APB transfers. It does not implement APB4/APB5
strobes, protection, wake-up, bridges, multiple slaves, callbacks, or UVM RAL.
Reset is supported before stimulus; asserting reset during active traffic and
scoreboard model resynchronization after a mid-test reset are not supported in
this version.
