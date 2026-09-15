# RTL.ai — Constraint Optimization through RTL Enhancement Using Generative AI

Nebula Hackathon 2026 (Digital track) · Team **RTL.ai** · BITS Pilani, Pilani Campus
Ritik Jindal · Tushar Bansal · Brind Akabari

An automated timing-closure loop: it synthesizes an RTL design, times it, works out
which module owns the critical path, asks a generative model to rewrite that module,
**proves the rewrite formally equivalent to the original**, reintegrates it, and
re-measures the whole design — then repeats on whatever bottleneck emerges next.

Nothing is accepted that has not been proven equivalent. An unverified candidate is
rejected regardless of how good its measured PPA is.

## Result on our benchmark

48,070 cells, five asynchronous clock domains, Nangate 45 nm.

| Metric | Baseline | Optimized | Change |
|---|---|---|---|
| Worst slack | −1.41 ns | −0.71 ns | **+0.70 ns** |
| Max frequency | 343.6 MHz | 463.0 MHz | **+34.7 %** |
| Total power | 181 mW | 167 mW | **−7.7 %** |
| Cell area | 61 803 µm² | 62 802 µm² | +1.6 % |
| Flip-flops | 1 952 | 2 214 | +13.4 % |

Two rounds accepted, both proven equivalent by SymbiYosys in unbounded mode at
depth 20, each adding one pipeline cycle. The design still violates timing at
−0.71 ns — we report that rather than claiming closure. Full analysis, including
why the run stopped at round 3, is in the report.

## Requirements

- Python 3.9+
- [OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build) — provides Yosys,
  OpenSTA, SymbiYosys, EQY and the SMT solvers
- A Nangate45 (or equivalent) Liberty file
- An Anthropic API key (only for `optimize.py`; the analysis and formal paths need none)

## Setup

```bash
git clone https://github.com/Ritikjindal/RTL.ai.git
cd RTL.ai
pip install -r requirements.txt
cp .env.example .env        # then edit .env
```

`.env`:

```
ANTHROPIC_API_KEY=sk-ant-...
OSS_CAD_SUITE=/path/to/oss-cad-suite
LIBERTY_FILE=/path/to/NangateOpenCellLibrary_typical.lib
```

Check the toolchain is visible:

```bash
which yosys sta sby eqy
```

## Usage

**Measure a design** (no API key needed):

```bash
python3 analyze.py --rtl designs/benchmark_top.v designs/*.v \
                   --sdc constraints/benchmark_top.sdc
```

**Compare two designs and prove equivalence** (no API key needed):

```bash
python3 analyze.py --rtl designs/benchmark_top.v \
                   --candidate path/to/optimized.v \
                   --sdc constraints/benchmark_top.sdc
```

**Run the full optimization loop:**

```bash
python3 optimize.py --rtl designs/benchmark_top.v designs/mac_unit.v \
                          designs/bm_fir6.v designs/bm_dot4.v \
                          designs/bm_mac8.v designs/bm_fsm_ctrl.v \
                          designs/clk_divider.v designs/cdc_sync.v \
                          designs/cdc_handshake.v designs/reset_sync.v \
                   --sdc constraints/benchmark_top.sdc \
                   --name my_run
```

**Web interface** — same pipeline, streamed live in the browser:

```bash
python3 webapp/app.py          # then open http://localhost:5000
```

Expect roughly 30–75 minutes for a five-domain run, dominated by formal verification.

## How it works

One round: synthesize (Yosys) → time and measure PPA (OpenSTA) → attribute the
critical path to a source module → planner proposes a transform and declares any
added latency → coder implements it N times → each candidate is proven equivalent →
the accept gate scores survivors against the baseline → the winner is reintegrated
and the whole design is re-measured. The next round targets whatever is now worst.

Three things worth knowing:

**Module attribution without the netlist.** After synthesis, ABC has renamed every
cell and flattening has erased the hierarchy, so the netlist cannot say which module
owns a path. The timing report does name the *clock*, and a module instance's clock
connection identifies its domain — so attribution is done on the source, not the
netlist. CDC and reset synchronizer structures are excluded by construction.

**Latency-offset sequential equivalence.** Pipelining changes *when* outputs appear,
so a naive miter rejects every correct pipelined candidate. The planner declares
`LATENCY_OFFSET: n`; the checker delays the baseline's outputs through an n-deep
shift register and suppresses comparison until it fills. A wrong offset still fails.

**Verification is module-scope, scoring is design-scope.** Proving a 48k-cell design
equivalent monolithically does not terminate; proving one module does, and
substitution is sound given an identical port list. Scoring then happens on the
re-synthesized whole design, so a local win that doesn't help the design isn't
counted.

## Layout

```
analyze.py              measure one design, or compare two and prove equivalence
optimize.py             the optimization loop
rtlai/
  synth.py  sta.py      Yosys and OpenSTA drivers
  parse_timing.py       per-path timing report parsing
  attribute.py          clock-based module attribution
  modules.py            module extraction and patching
  formal.py             SymbiYosys equivalence, latency offset, bounded fallback
  equiv_eqy.py          EQY backend
  compare.py            PPA comparison
  optimizer/
    planner.py coder.py LLM stages
    decide.py           the accept gate
    counterexample.py   extracts failing stimulus from a failed proof
designs/                benchmark and payload modules
constraints/            SDC files
webapp/                 Flask front end
runs/                   timestamped run artifacts (every reported number lives here)
```

## Run artifacts

Every run writes to `runs/<name>_<timestamp>/` and nothing is overwritten:

- `baseline/result.json` — the starting measurement
- `round_N/attempt_M/candidate_K/` — plan, generated RTL, formal logs, measurement
- `round_N/optimized/` — the accepted design after that round
- `summary.json` — rounds accepted, modules, latency offsets, scores
- `optimized/result.json` — the final design

Every figure in the report is read from these files.

## Known limitations

- **Power is a pre-placement estimate.** OpenSTA on an unplaced, unbuffered netlist.
  Relative comparisons between runs are valid; absolute figures are not silicon.
- **Six multipliers in one proof cone is past the wall.** Four prove in seconds; six
  time out in both bounded and unbounded modes. `bm_fir6` is the worked example.
- **Transforms resting on a reachability invariant are unverifiable here.** A one-hot
  FSM flattening is correct but neither k-induction nor EQY will assume the
  invariant, and BMC stalls. Documented rather than worked around.
- **CDC is not verified and is not optimized.** Both checkers use a synchronous model
  and represent neither metastability nor MTBF, so those structures are excluded by
  construction rather than trusted to the checker.

## License

MIT
