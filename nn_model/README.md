# Model 3 — Neural Network MPPT — Final Asset Package

Real, working model — trained on real data from Model 1, running live inside
Simulink as a drop-in replacement for the P&O controller.

## Screenshots (in the order we worked through them)

| File | What it shows |
|---|---|
| 01_irradiance_stair_generator_settings.png | Stair Generator block dialog — setting irradiance to fixed test values |
| 02_PV_scope_at_200Wm2.png | First data-collection run — PV scope at fixed 200 W/m², 45°C |
| 03_NN_training_fit_plot.png | **Training result** — real Model 1 data points (blue) vs. trained network prediction (red dashed) — near-perfect fit |
| 04_inverter_control_parameters_dialog.png | Inverter Control parameter mask (revisited while locating the MPPT subsystem) |
| 05_top_level_diagram_irradiance_VPV_IPV.png | Top-level model view showing where Irradiance, V_PV, and I_PV signals are available for wiring into the new NN block |
| 06_NN_block_output_test_481V.png | Standalone NN block test — output settles at 481V for 1000 W/m² input, matching real P&O data almost exactly |
| 07_FINAL_Model3_vs_Model1_comparison_result.png | **Headline result** — full irradiance step-test (1000→200→1000 W/m²) with the NN controller live in the loop. Cursor measurement confirms Pdc mean = 46.66 kW at the 200 W/m² point — matching Model 1's real P&O result at the same irradiance almost exactly |

## Code files

- **train_nn_mppt.m** — training script, pre-filled with your 5 real data points collected from Model 1 (see table below). Trains a 5-neuron feedforward network (`fitnet`) and saves it to `trained_nn_mppt.mat`.
- **nn_mppt_controller.m** — the MATLAB Function block code used inside Simulink, structured to match `PandO.m`'s input/output shape for a fair, direct swap.

## Your real training data (collected from Model 1, 45°C constant)

| Irradiance (W/m²) | Vdc (V) | Pdc (kW) |
|---|---|---|
| 200 | 464.4 | 46.66 |
| 400 | 474.6 | 95.37 |
| 600 | 478.8 | 144.3 |
| 800 | 480.6 | 193.1 |
| 1000 | 481.1 | 241.5 |

## Important technical note (for your methodology section)

`genFunction()` must be called with the `'MatrixOnly', 'yes'` option:
```matlab
genFunction(net, 'nn_mppt_generated', 'MatrixOnly', 'yes');
```
Without this option, the generated function uses cell-array inputs, which
Simulink's MATLAB Function block cannot accept for code generation — this
produces a "cell into double" type-mismatch error. Worth mentioning in your
report as a real implementation detail/lesson learned.

## Headline result & what it means

At 1000 W/m², the NN controller outputs ~481V, essentially identical to
Model 1's real P&O result at the same irradiance. At 200 W/m², both models
again converge to ~46.66 kW. This is expected, not circular: the network
was trained directly on P&O's own settled values, so at trained irradiance
levels the two methods should agree closely — this is validation that the
network learned correctly, not evidence the two controllers are
indistinguishable.

**The real comparison for your thesis lies in the transition behavior**
(around t≈0.4–0.5s and t≈1.0–1.2s in the scope traces) — this is where P&O's
iterative search shows visible oscillation/ripple while hunting for the new
MPP, whereas the NN computes its answer directly from the irradiance input
without searching. Worth a close side-by-side zoom of both models' Vdc mean
traces during these transition windows for the comparative analysis chapter.

## Limitation worth stating explicitly in the thesis

The network was trained on only 5 data points at one fixed temperature
(45°C). This is sufficient to demonstrate the concept and produce a
genuinely working comparison, but a more rigorous version would train on
a larger dataset spanning multiple irradiance *and* temperature
combinations to properly test generalization rather than close
interpolation between known points.
