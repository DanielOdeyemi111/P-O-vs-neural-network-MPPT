%% train_nn_mppt.m
% Trains a small feedforward neural network to predict the MPP voltage
% (Vdc_ref) from irradiance, using REAL data points collected from your
% own Model 1 Simulink runs (Vdc mean at steady state, for a range of
% fixed irradiance levels).

%% ---- STEP A: your real data (collected from Model 1 runs) ----
% Irradiance levels tested (W/m^2)
Irradiance_data = [200, 400, 600, 800, 1000];

% Real Vdc mean readings from Model 1, at each irradiance level above
Vdc_data = [464.4, 474.6, 478.8, 480.6, 481.1];

% Temperature was held constant at 45 C for all runs
Temperature_C = 45;

% Pdc mean (kW) at each irradiance level — recorded alongside Vdc for
% reference/reporting purposes (used in the results table, not training).
Pdc_data_kW = [46.66, 95.37, 144.3, 193.1, 241.5];

%% ---- STEP B: train the network ----
X = Irradiance_data;   % 1 x 5
T = Vdc_data;          % 1 x 5 (targets)

% Simple feedforward network, one hidden layer of 5 neurons — enough
% for a single-input, smooth, monotonic relationship like this.
net = fitnet(5);

% Only 5 data points, so skip automatic train/val/test splitting.
net.divideFcn = '';

[net, tr] = train(net, X, T);

%% ---- STEP C: check the fit ----
Vpred = net(X);
figure;
plot(Irradiance_data, Vdc_data, 'bo-', 'LineWidth', 1.5, 'DisplayName', 'Your simulated data');
hold on;
plot(Irradiance_data, Vpred, 'r*--', 'LineWidth', 1.5, 'DisplayName', 'NN prediction');
xlabel('Irradiance (W/m^2)');
ylabel('MPP Voltage V_{dc,ref} (V)');
title('Neural Network Fit to Your Model 1 MPP Data');
legend('Location', 'southeast');
grid on;

fprintf('Training complete.\n');
fprintf('Test the network directly, e.g.: net(300)  %% predicts V_ref at 300 W/m^2\n');

%% ---- STEP D: save it for use in Simulink ----
save('trained_nn_mppt.mat', 'net');
fprintf('Saved trained network to trained_nn_mppt.mat\n');

%% ---- STEP E: export for Simulink (run separately in Command Window) ----
% load('trained_nn_mppt.mat');
% genFunction(net, 'nn_mppt_generated', 'MatrixOnly', 'yes');
%
% NOTE: the 'MatrixOnly','yes' option is REQUIRED — without it,
% genFunction produces cell-array-based code that Simulink's MATLAB
% Function block cannot use (causes a "cell into double" coder error).
