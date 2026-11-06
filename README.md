# P&O vs Neural-Network MPPT for a 250 kW Grid-Connected PV System

MATLAB/Simulink (R2024b) code for a Master's thesis (AESE programme, Université de Bourgogne): a comparison of Perturb & Observe and a feedforward neural-network MPPT on the MathWorks 250 kW grid-connected PV reference model.

| Folder | Contents |
|---|---|
| `po_model/` | P&O MPPT (`PandO.m`), model parameters, result screenshots |
| `nn_model/` | NN training (`train_nn_mppt.m`, `fitnet`) and controller (`nn_mppt_controller.m`), result screenshots |
| `comparison/` | `compare_PO_vs_NN.m`: overlay, zoomed transitions, settling time and ripple |
| `docs/` | Step-by-step build guide |

**Requirements:** MATLAB R2024b, Simulink, Simscape Electrical, Deep Learning Toolbox.

**Run order:** apply `po_model/model_parameters.m` to the reference model, run P&O and export results; train the net with `nn_model/train_nn_mppt.m`, export via `genFunction(net,'nn_mppt_generated','MatrixOnly','yes')`, use `nn_mppt_controller.m` in a MATLAB Function block; then run `comparison/compare_PO_vs_NN.m`.

**Limitations:** the NN is trained on only 5 irradiance points at one temperature; the transient/settling-time comparison script has not yet been run on exported data.

Reference models by MathWorks. Academic use.
