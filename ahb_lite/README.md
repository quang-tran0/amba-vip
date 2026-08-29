# AHB-Lite UVM VIP and Two-Bank Subsystem

This directory contains a reusable single-master AHB-Lite UVM VIP and a small
synthesizable subsystem used to verify it. The subsystem routes one master to
two independent register banks through a registered data-phase response mux.

## Supported subset

- 32-bit address and data buses
- `HTRANS=IDLE` and `HTRANS=NONSEQ`
- `HSIZE=WORD` and `HBURST=SINGLE`
- Reads, writes, deterministic wait states, OKAY, and two-cycle ERROR
- One master and two slaves
- ACTIVE and PASSIVE agent modes

The master driver intentionally allows one outstanding transfer at a time.
The RTL and monitor preserve address-phase context independently from the data
phase, but the supplied driver does not yet overlap consecutive NONSEQ address
phases.

## Topology and address map

```text
AHB-Lite master VIP
        |
        v
1-to-2 interconnect
   |            |
   v            v
Bank 0        Bank 1
```

| Address | Bank | Register | Access | Reset |
|---|---:|---|---|---:|
| `0x0000_0000` | 0 | CTRL | RW | `0x0000_0000` |
| `0x0000_0004` | 0 | STATUS | RO | `0x0000_0001` |
| `0x0000_0008` | 0 | DATA | RW | `0x0000_0000` |
| `0x0000_000C` | 0 | CONFIG | RW | `0x0000_0000` |
| `0x0001_0000` | 1 | CTRL | RW | `0x0000_0000` |
| `0x0001_0004` | 1 | STATUS | RO | `0x0000_0002` |
| `0x0001_0008` | 1 | DATA | RW | `0x0000_0000` |
| `0x0001_000C` | 1 | CONFIG | RW | `0x0000_0000` |

Bank 0 covers `0x0000_0000-0x0000_0FFF` with zero configured wait states.
Bank 1 covers `0x0001_0000-0x0001_0FFF` with one configured wait state.
Only the four listed word addresses are valid register accesses. STATUS writes
complete with OKAY and are ignored.

Invalid register offsets, misaligned accesses, unsupported sizes, and unmapped
addresses return the AHB-Lite two-cycle ERROR response. Any configured slave
wait states occur first with `HRESP=OKAY` and `HREADY=0`; ERROR then uses one
cycle with `HRESP=ERROR/HREADY=0` followed by the completing cycle with
`HRESP=ERROR/HREADY=1`.

## Project layout

```text
rtl/         synthesizable interconnect, register bank, and subsystem
ahb_vip/     reusable interface, transaction, agent, driver, and monitor
sequences/   deterministic, directed, interconnect, and random traffic
tb/          project scoreboard, environment, and HDL/UVM top
testcases/   base and derived UVM tests
sim/         Questa file lists, Makefile, and regression flow
```

The compile dependency is `RTL -> ahb_if -> ahb_pkg -> env_pkg/seq_pkg ->
test_pkg -> testbench`. Each UVM class is included only by its layer package.

## Prerequisites

- QuestaSim with `vlog`, `vlib`, `vmap`, `vsim`, and `vcover` on `PATH`
- The Questa bundled UVM 1.2 library
- GNU Make, Perl, and GNU coreutils `timeout`
- A valid simulator license

`sim/project_env.bash` discovers the local Questa and UVM paths from `vlog`.

## Build and run

Run from `ahb_lite/sim`:

```bash
make clean
make build
make run TESTNAME=ahb_smoke_test SEED=1 VERBOSITY=UVM_HIGH
```

The equivalent safe compile-and-run command is:

```bash
make all TESTNAME=ahb_smoke_test SEED=1
```

Available tests are:

```text
ahb_smoke_test
ahb_write_test
ahb_read_test
ahb_interconnect_test
ahb_pipeline_test
ahb_random_test
```

Set the random traffic count with `NUM_ITEMS`:

```bash
make run TESTNAME=ahb_random_test SEED=42 RUNARG=+NUM_ITEMS=100
```

## Regression, coverage, and waveforms

```bash
./regress.pl
./regress.pl -r

make clean
make build COV=ON
make run COV=ON TESTNAME=ahb_smoke_test SEED=1
make cov_gui COV=ON TESTNAME=ahb_smoke_test SEED=1

make wave
```

The regression builds once, runs directed tests and three random seeds, and
requires both the final UVM pass marker and Questa's zero-error summary.

## Known limitations

This is AHB-Lite, not full multi-master AHB. It does not implement arbitration,
bursts, BUSY/SEQ traffic, locked transfers, SPLIT, RETRY, security extensions,
UVM RAL, or multiple outstanding transfers. Reset is supported before
stimulus; mid-transfer reset and scoreboard resynchronization are not yet
supported.
