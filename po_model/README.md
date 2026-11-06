# Model 1 — Grid-Connected PV System (250-kW) — Asset Package

This folder contains everything gathered while building and running Model 1 in
MATLAB/Simulink, for use when writing the thesis chapter on this model.

## Screenshots (in the order we worked through them)

| File | What it shows |
|---|---|
| 01_resistor_block_options.png | Library Browser search — comparing Resistor block variants (RF Blockset, Thermal, Simscape) during Phase 1 wiring |
| 02_phase1_canvas_wiring.png | Phase 1 test canvas — PV array wired to Constant blocks, Voltage/Current Measurement, Resistor load, Scope |
| 03_phase1_scope_result.png | Phase 1 result — PV array voltage & current settling to steady values at 1000 W/m², 25°C |
| 04_matlab_examples_search_results.png | MATLAB Help/Examples search results for "grid-connected PV array" — led to the 250-kW reference model |
| 05_250kW_full_model_diagram.png | Full top-level diagram of the 250-kW Grid-Connected PV Array reference model (PV array → 3-level IGBT bridge → transformer → grid) |
| 06_irradiance_profile_parameters.png | Irradiance input block settings — stepped profile: 1000 → 200 → 1000 W/m², at t = [0, 0.4, 1.0]s; temperature fixed at 45°C |
| 07_PV_scope_result_irradiance_step_test.png | **Key result** — PV scope showing Irradiance, DC-link voltage (Vdc mean), and DC power (Pdc mean) across the full step-down/recovery test |
| 08_inverter_control_parameters_1.png | Inverter Control block parameter mask — nominal values, MPPT controller settings, DC voltage regulator, current regulator, PWM modulator |
| 09_inverter_control_parameters_2.png | Continuation of the above — DC voltage regulator, current regulator, PWM modulator, and sample time settings |
| 10_MPPT_control_architecture_diagram.png | Inside "Inverter Control" (under mask) — full control architecture: PLL & Measurements, P&O MPPT Controller, VDC Regulator, Current Regulator, Uabc_ref Generation |

## Code / data files

- **PandO.m** — the actual Stateflow/MATLAB function implementing the Perturb & Observe MPPT algorithm, pulled directly from inside the model's MPPT Controller block. Output `D` is the DC-link voltage reference (Vdc_ref), not a converter duty cycle directly — it feeds into the VDC Regulator → Current Regulator → PWM chain shown in image 10.
- **model_parameters.m** — the full parameter script from the model (`Double-click to open parameters .m file` block), covering power stage parameters, transformer, filter, IGBT bridge, and all control-loop gains, plus a note on the irradiance test profile used for the results in image 07.

## Key numbers for quick reference (also in model_parameters.m)

- Nominal power: **250 kW**
- Grid frequency: **60 Hz**
- DC-link voltage: **480 V**
- MPPT: Perturb & Observe, increment 0.01, Vdc_ref limits [357, 583] V
- VDC regulator: Kp = 2, Ki = 400
- Current regulator: Kp = 0.3, Ki = 20
- PWM carrier frequency: 1980 Hz
- Test profile: irradiance 1000 → 200 → 1000 W/m² (ramped, t = 0 to 1.0s), temperature constant at 45°C

## Headline result

At full irradiance (1000 W/m²), the model delivers its rated ~250 kW with the DC-link
held stable at ~480 V. When irradiance drops to 200 W/m², power falls to roughly
65-70 kW. When irradiance returns to 1000 W/m², power recovers back to ~250 kW —
demonstrating both proportional tracking and successful re-acquisition of the MPP
after a large, sudden disturbance.
