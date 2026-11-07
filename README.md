# APB RAM Interface and Verification

**SystemVerilog · 64-word RAM · Directed simulation**

A zero-wait-state APB memory interface built around 64 words of 32-bit storage. A SystemVerilog interface groups the bus signals, and a separate deterministic testbench checks the implemented memory and control behaviour.

The recorded portable regression passed **1,317 checks**, including reset, write/readback, setup/access observations, and write guards. The implemented slave keeps `PREADY` high and `PSLVERR` low; the tests describe this bounded implementation. See [portable validation](docs/portable_validation.md) for its exact scope.

The original class-based environment and historical evidence are retained separately. [Original source documentation](SOURCE_README.md) and the provenance section below identify the unchanged baseline.

## New bounded 64-word contract regression

At source revision `9ed002bbb9dc93b312acb22826335d83daf834e2`,
the [separate result-aware regression](docs/RESULTS.md) passed the preserved
1,317 checks, 2,697 independent memory comparisons, and three reset-isolated
malformed-master detections. It exercises all 64 words, aliases, reset,
SETUP/ACCESS sequencing and legal `PSEL`-held back-to-back transfers.
Four disposable faults produced nonzero wrapper exits. A short simulator VCD
and a [measured waveform](reports/technical-completion-2026-11-07/apb64-directed.svg)
are retained with raw logs. See the [implemented contract](docs/SPECIFICATION.md).
The original class environment remains licence-blocked and NOT RUN; no
equivalent coverage or complete APB protocol claim is made.

## Run

From the repository root, with the required ModelSim/Questa executables and appropriate licence available:

```bash
bash sim/run.sh
```

Existing Windows instructions, where supplied, are retained in `scripts/`. Do not assume the testbench will run in every edition of a simulator. Check [the retained validation report](source-docs/VALIDATION.md) and the original README.

### Portable deterministic regression

With `vlib`, `vlog`, and `vsim` on PATH, run from the repository root:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/run_portable.ps1
```

This compiles only the unchanged RTL and [plain testbench](tb/tb_portable.sv), writing fresh output to the ignored `portable-results/` directory. It checks all 64 RAM words after reset, deterministic write/readback, setup and access timing, constant response signals, write guards, low-address-bit aliasing, and reset during a pending write. See [portable validation](docs/portable_validation.md) and its [fresh logs](reports/portable-2026-11-05/). The original class-based environment, randomization and covergroup remain as they were; the portable checks are not equivalent coverage or complete APB protocol verification.

## Verification status

The original `reports/compile.log` and `reports/simulation.log` are historical evidence copied from the source repository. The extraction script performed no simulation. The separately recorded portable run passed its stated deterministic checks; the original class-based environment remains blocked by a verification-feature licence in the tested Starter editions. No functional coverage is claimed.

## Provenance and changes

Source commit: `df8d6f66898a08df75cd2071ddac7bbba9ba9b16`. Source path: `projects/apb-interface`.

[SOURCE_PROVENANCE.json](SOURCE_PROVENANCE.json) records checksums of every original file. `SOURCE_README.md` is the unchanged original README. No RTL or testbench functionality was changed during extraction. Source history remains available in the original repository; this is a snapshot, not a rewrite of its authorship.

## Next engineering work

Planned extensions include running the retained class-based environment in a compatible simulator and adding assertion and coverage evidence. Wait-state and error-response support would require a separate RTL extension.
