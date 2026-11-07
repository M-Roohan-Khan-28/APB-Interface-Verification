# Verification notes

The supplied testbench is [tb_apb](../tb/tb_top.sv). Start with its existing stimulus and checks, then review reset, normal operations, boundaries, and invalid inputs against the actual RTL interface.

Packaging has preserved the original testbench. There is no measured code-coverage report or new standalone assertion suite. Record failures as well as passes in the simulation log; inspect whether each check is automatic or requires waveform review before expanding the test plan.

## Executed contract matrix

The new [bounded specification](SPECIFICATION.md) and [results](RESULTS.md)
are for the separately compiled plain-SystemVerilog environment.

| Requirement | Independent check | Executed evidence |
| --- | --- | --- |
| 64-word decode and reset | Reference array updates on accepted writes and clears on reset; all words filled/read and reset checked | `APB64_CONTRACT_PASS`, 2,697 comparisons |
| Low-bit alias | Read each implemented word through byte-address aliases | 80 alias probes |
| Zero wait and no error | Compare `PREADY`, `PSLVERR` and `PRDATA` at each selected observation | Contract comparison log |
| Pre-edge exactly-once acceptance | Count issued and accepted transfers separately and update the reference on observed ACCESS edges | 673 issued, 673 accepted |
| Back-to-back and no-write guards | Hold `PSEL` through new SETUP; vary read/write order; reject unselected and setup-only writes | 5 back-to-back cases; disposable RTL mutant detected |
| Master sequence | Pre-edge monitor checks setup before access and stable control/data; three reset-isolated negatives and legal control | 3 expected detections, 1 legal control; three monitor mutants detected |

An external 120-second timeout applies to each simulator command, and the
benches have finite simulation watchdogs. These are scenario/check counts,
not measured coverage percentages. Advanced original randomization and
covergroups remain NOT RUN with this licence.

