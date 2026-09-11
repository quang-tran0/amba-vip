# AMBA UVM Practice

This repository is a learning and portfolio project for practicing AMBA bus
protocols and fundamental UVM verification techniques with SystemVerilog and
QuestaSim.

The implementations are intentionally small and explicit. Each protocol
project includes a reusable master VIP, a simple synthesizable DUT, directed
and random sequences, assertions, functional coverage, a self-checking
scoreboard, and a regression flow.

## Current projects

| Project | Status | Focus |
|---|---|---|
| [APB](apb/README.md) | Implemented | Setup/access phases, wait states, errors, and register accesses |
| [AHB-Lite](ahb_lite/README.md) | Implemented | Address/data pipelining, two-slave routing, wait states, and two-cycle errors |
| AXI | Planned | A future learning milestone |

## Repository layout

```text
amba-vip/
├── apb/        # APB master VIP and register-bank DUT
├── ahb_lite/   # AHB-Lite master VIP and two-bank subsystem
└── README.md
```

Each implemented protocol follows the same basic verification layering:

```text
RTL
 ↓
interface and reusable VIP
 ↓
sequences and environment
 ↓
tests
 ↓
testbench
```

See the protocol-specific README for the supported subset, memory map, tests,
coverage, regression commands, and known limitations.

## Tools and concepts

- SystemVerilog
- UVM 1.2
- QuestaSim
- Transactions, sequences, sequencers, drivers, monitors, and agents
- `uvm_config_db` and virtual interfaces
- Analysis ports and self-checking scoreboards
- Assertions, functional coverage, deterministic seeds, and regression

## Quick start

Run the APB smoke test:

```bash
make -C apb/sim clean
make -C apb/sim all TESTNAME=apb_smoke_test SEED=1
```

Run the AHB-Lite smoke test:

```bash
make -C ahb_lite/sim clean
make -C ahb_lite/sim all TESTNAME=ahb_smoke_test SEED=1
```

A successful run prints `TEST PASSED` with no UVM errors or fatals.

## Scope

This repository is designed for learning and interview preparation. It favors
clear, explainable implementations over production-level feature completeness.
Advanced protocol features are added only after the basic timing and UVM
architecture are verified.
