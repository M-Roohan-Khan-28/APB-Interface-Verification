# Implemented APB RAM contract

The unchanged `rtl/design.sv` implements a 64-word, 32-bit RAM through
`apb_if`. `PADDR[7:2]` selects a word; the two low address bits alias that
word. `PREADY` is always high and `PSLVERR` is always low. Selected reads
are visible in both SETUP and ACCESS. A selected write is accepted on the
ACCESS rising edge; a SETUP-only write cannot update RAM. Active-low reset
clears every word. The contract supports a new SETUP cycle with `PSEL` held
after a completed ACCESS cycle. There are no wait states or error responses.

The new `tb/apb64_contract_test.sv` maintains a 64-word reference array from
observed pre-edge acceptances and compares externally visible pins without
reading DUT storage. `verification/apb64_monitor.sv` checks master sequence
and control stability at each rising edge. The monitor's `FATAL=0` setting is
used only in reset-isolated negative cases that demand exact detections.

This is a bounded implementation contract, not a claim of complete APB
compliance. Original class-based benches, historical logs, provenance and
licence notices are retained.
