# Building the 3 MW Grid-Connected Solar PV System in MATLAB/Simulink
### A from-zero build guide (Python background assumed)

---

## Before you start: orientation (Day 1, ~2-3 hours)

You don't need to read a manual cover to cover. Do these two free official courses — they're short and hands-on:

1. **MATLAB Onramp** (~2 hrs) — matlabacademy.mathworks.com. Covers scripts, matrices, plotting. If you know NumPy/matplotlib, this will feel very familiar and go fast.
2. **Simulink Onramp** (~2 hrs) — same site. This is the actually-new part: Simulink is a **block-diagram** simulator, not text code. You drag blocks onto a canvas and wire them together. Each block is a chunk of math or hardware behavior; wires carry signals between them.

**Key mental model shift from Python:** in Python you write `y = f(x)` line by line, top to bottom. In Simulink, you place a block that *represents* `f`, draw a wire from `x` into it, and a wire from its output to wherever `y` goes. The simulation then runs all of this in a synchronized time-loop automatically — you don't write the loop yourself.

3. **Install the toolbox you actually need**: Open MATLAB → Home tab → Add-Ons → Get Add-Ons → search **"Simscape Electrical"** → install it. This is the library with PV arrays, converters, inverters, and power-grid blocks. Without it, none of the blocks in this guide will exist in your library browser.

---

## The build plan — 4 phases, each one testable on its own

Don't try to build the whole 3 MW model in one sitting. Build it in verifiable stages. Each phase ends with something you can simulate and see a sensible result from — that's your checkpoint before moving on.

| Phase | What you build | How you know it worked |
|---|---|---|
| 1 | PV array → scope (just look at the panel) | I-V and P-V curves appear, matching datasheet shape |
| 2 | PV array → boost converter → P&O MPPT | Output power settles near the panel's rated max power |
| 3 | Add DC-link + 3-phase inverter → resistive load | Clean 3-phase AC waveform appears on scope |
| 4 | Connect to grid via PLL, scale up to full array | Power flows into grid; test at 1000 W/m² and 500 W/m² |

---

## Phase 1 — Just the PV array

**Goal:** get one block working and understand its inputs/outputs before touching anything else.

1. Open Simulink → **Blank Model**.
2. Open the Library Browser (bookshelf icon). Navigate to **Simscape → Electrical → Specialized Power Systems → Sources**.
3. Drag in the **PV Array** block.
4. Double-click it. You'll see a dialog with a dropdown of preset panel models (e.g. manufacturer/model), or you can enter custom specs. Pick any preset for now — don't worry about matching 3 MW yet.
5. From the library, also grab:
   - **Two "Ramp" or "Constant" blocks** (or a signal generator) — these feed the array its **irradiance (W/m²)** and **temperature (°C)** inputs.
   - A **Scope** block, connected to the array's voltage and current outputs.
6. Wire it up: Irradiance signal → array's `Ir` input. Temperature signal → array's `T` input. Array output → Scope.
7. Set irradiance to a constant 1000, temperature to 25 (standard test conditions).
8. Press **Run** (the play button). Double-click the scope to view results.

**What you're looking for:** a voltage/current/power trace that settles to a steady value. If you sweep irradiance from 200→1000 W/m² over the simulation, you should see power rise proportionally — this is your first confirmation that "more sun = more power," visually, in your own model.

---

## Phase 2 — Add the boost converter and P&O MPPT

**Goal:** stop just *reading* the panel's power and start *controlling* it to extract the maximum.

1. From **Specialized Power Systems → Power Electronics**, add:
   - **IGBT** (or "Universal Bridge" configured as one switch) — this is your boost converter's switch.
   - An **Inductor**, **Diode**, and **Capacitor** (from Elements) — wire them into the classic boost topology: PV+ → inductor → diode → capacitor(+bus) → back to PV−, with the IGBT switching node between inductor and diode to ground.
   - *(This matches the circuit diagram in Report 1 — Figure 2 — if you want a visual reference while wiring.)*

2. Build the **P&O MPPT controller**:
   - Simulink has a built-in example you can literally open: type `power_PVarray_grid_connected` in the MATLAB command window and hit Enter. This opens a real, working reference model from MathWorks with the exact P&O structure you need — inspect it, don't just copy it blindly. Trace through its MPPT subsystem block by block.
   - Alternatively, build it yourself with MATLAB Function block, pasting in the P&O code from the appendix of Report 1 (the `perturb_and_observe.m` function) — a MATLAB Function block lets you write actual `.m` code inside a Simulink block, which is probably the fastest path for you given your Python/code background.
   - The MPPT block's output is a duty cycle `D` (0 to 1) → feeds a **PWM Generator** block → drives the IGBT gate.

3. Add a scope on: PV power, PV voltage, and duty cycle `D`.

4. Run it. **Expected result:** power should climb toward the panel's rated max power and hover there with small oscillation — that oscillation is P&O actually working (it's inherent to the algorithm, as your Report 3 comparison explains).

**This is your most important checkpoint.** If this phase works, you understand the core mechanism the entire 3 MW plant is built from — everything after this is scaling and adding AC-side complexity.

---

## Phase 3 — DC-link, inverter, and a simple load

**Goal:** get from DC to usable 3-phase AC.

1. Add a **Capacitor** across the boost converter's output — this is your DC-link (target: hold ~600 V, per Report 1's spec table).
2. From **Power Electronics**, add a **Universal Bridge** block configured with **3 arms / IGBT** — this is your 3-phase inverter.
3. For now, connect its 3-phase output to a **3-Phase Series RLC Load** (just a resistive load) instead of the real grid — this isolates whether your inverter stage works before you add grid synchronization complexity.
4. You'll need a PWM generator for the inverter too — Simulink's **"PWM Generator (3-phase)"** block, driven by a modulation index and phase reference.
5. Scope the 3-phase output voltage.

**Expected result:** a clean three-phase sine-like waveform (after filtering) on your scope, at roughly the frequency you configured.

---

## Phase 4 — Grid connection, PLL, and scaling to 3 MW

**Goal:** the real version — synchronized to the grid, at full scale, tested at two irradiance levels.

1. Replace your resistive load with a **Three-Phase Source** block configured as the grid (400 V, 50 Hz — per your spec table).
2. Add a **PLL (Phase-Locked Loop)** block (Simscape Electrical has one built in, or use the discrete PLL from the power_PVarray_grid_connected example) — feed it the grid voltage; its output `theta` is used to synchronize your inverter's switching to the grid's phase.
3. This stage involves **dq0 (Park) transforms** for current control — this is genuinely the hardest conceptual piece. Don't build this from scratch; open the MathWorks example model again (`power_PVarray_grid_connected`) and study its grid-side control subsystem specifically — it already has a working dq-axis PI control loop you can adapt.
4. **Scale to 3 MW:** change your PV array block's series/parallel configuration to 11 series × 1,300 parallel (per Report 1) — or start smaller (e.g. 11×100) to keep simulation fast while you're still debugging, then scale up once everything works.
5. Run two separate simulations:
   - Irradiance = 1000 W/m² constant → expect ~3 MW output, 600 V DC-link held stable.
   - Irradiance = 500 W/m² constant → expect ~1.5 MW output, DC-link still stable.
6. Scope and export: PV power, DC-link voltage, grid power, grid current THD (Simulink has a built-in **FFT/THD analysis tool** under Powergui → Tools → FFT Analysis).

---

## What to actually screenshot/export for your report

For each of the two test conditions, capture:
- PV array power vs. time (shows MPPT convergence)
- DC-link voltage vs. time (should be flat around 600 V)
- Grid-side 3-phase current waveform (should look like a clean sine wave)
- THD percentage from the FFT analysis tool

These four things, for both irradiance levels, are your core "results" section — exactly the kind of output the original video was demonstrating.

---

## When you get stuck

- **`power_PVarray_grid_connected`** (type it into the MATLAB command window) is your single best resource — it's a real, complete, working version of almost exactly this system, built by MathWorks. Use it as a reference to check your own wiring against, not to copy-paste wholesale — the point is to understand why each block is there.
- MATLAB Answers (MathWorks' own Q&A forum) is searchable and usually has your exact error message already answered.
- If a block won't simulate, the error message in the red popup almost always tells you which block and why (unlike some Python stack traces, these are usually genuinely specific).

---

## Suggested pace

| Day | Focus |
|---|---|
| 1 | Onramps + install Simscape Electrical |
| 2 | Phase 1 (PV array alone) |
| 3-4 | Phase 2 (boost + MPPT) — this is the one to not rush |
| 5 | Phase 3 (inverter + dummy load) |
| 6-7 | Phase 4 (grid + PLL + scale up) |
| 8 | Run both test conditions, capture screenshots/data for your report |

This mirrors the same 7-step structure already laid out in Report 1 — so as you complete each phase here, you're simultaneously building the evidence for that report's methodology section, in your own model instead of just describing someone else's.
