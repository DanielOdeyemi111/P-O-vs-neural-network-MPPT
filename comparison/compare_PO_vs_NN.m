%% compare_PO_vs_NN.m
% Loads real exported data from Model 1 (P&O) and Model 3 (NN) and
% produces the three comparison graphs for the thesis:
%   1. Full time-domain overlay (overall tracking behavior)
%   2. Zoomed transition region (speed of response + oscillation)
%   3. Quantified bar-chart metrics (settling time, ripple magnitude)

%% ---- Load your real exported data ----
load('model1_data.mat');   % gives t_PO, Vdc_PO, Pdc_PO
load('model3_data.mat');   % gives t_NN, Vdc_NN, Pdc_NN

%% ---- GRAPH 1: Full time-domain overlay ----
figure('Name', 'Graph 1 - Full Comparison');
subplot(2,1,1);
plot(t_PO, Pdc_PO, 'b-', 'LineWidth', 1.3); hold on;
plot(t_NN, Pdc_NN, 'r--', 'LineWidth', 1.3);
xlabel('Time (s)'); ylabel('Pdc mean (kW)');
title('PV Power Output: P&O vs Neural Network MPPT');
legend('P&O (Model 1)', 'Neural Network (Model 3)', 'Location', 'best');
grid on;

subplot(2,1,2);
plot(t_PO, Vdc_PO, 'b-', 'LineWidth', 1.3); hold on;
plot(t_NN, Vdc_NN, 'r--', 'LineWidth', 1.3);
xlabel('Time (s)'); ylabel('Vdc mean (V)');
title('DC-Link Voltage: P&O vs Neural Network MPPT');
legend('P&O (Model 1)', 'Neural Network (Model 3)', 'Location', 'best');
grid on;

%% ---- GRAPH 2: Zoomed transition regions ----
% Your irradiance profile drops at t=0.4s and recovers at t=1.0s —
% zoom tightly around each transition to see settling behavior.

figure('Name', 'Graph 2 - Zoomed Transitions');

subplot(2,1,1);
plot(t_PO, Pdc_PO, 'b-', 'LineWidth', 1.3); hold on;
plot(t_NN, Pdc_NN, 'r--', 'LineWidth', 1.3);
xlim([0.35 0.7]);   % zoom around the irradiance DROP
xlabel('Time (s)'); ylabel('Pdc mean (kW)');
title('Zoomed: Response to Irradiance Drop (t=0.4s)');
legend('P&O', 'Neural Network', 'Location', 'best');
grid on;

subplot(2,1,2);
plot(t_PO, Pdc_PO, 'b-', 'LineWidth', 1.3); hold on;
plot(t_NN, Pdc_NN, 'r--', 'LineWidth', 1.3);
xlim([0.95 1.3]);   % zoom around the irradiance RECOVERY
xlabel('Time (s)'); ylabel('Pdc mean (kW)');
title('Zoomed: Response to Irradiance Recovery (t=1.0s)');
legend('P&O', 'Neural Network', 'Location', 'best');
grid on;

%% ---- GRAPH 3: Quantified metrics ----
% Settling time: time from the disturbance until the signal stays
% within +/-2% of its final value.
% Ripple: peak-to-peak variation once settled (steady-state oscillation).

tol = 0.02; % 2% settling band

% --- Settling time after the DROP at t=0.4s ---
final_PO_drop  = mean(Pdc_PO(t_PO > 0.7 & t_PO < 0.9));
final_NN_drop  = mean(Pdc_NN(t_NN > 0.7 & t_NN < 0.9));

settle_PO_drop = find_settling_time(t_PO, Pdc_PO, 0.4, final_PO_drop, tol);
settle_NN_drop = find_settling_time(t_NN, Pdc_NN, 0.4, final_NN_drop, tol);

% --- Steady-state ripple (measured in the flat region before the drop) ---
ripple_PO = peak2peak(Pdc_PO(t_PO > 0.15 & t_PO < 0.35));
ripple_NN = peak2peak(Pdc_NN(t_NN > 0.15 & t_NN < 0.35));

figure('Name', 'Graph 3 - Quantified Metrics');

subplot(1,2,1);
bar([settle_PO_drop, settle_NN_drop]);
set(gca, 'XTickLabel', {'P&O', 'Neural Network'});
ylabel('Settling Time (s)');
title('Settling Time After Irradiance Drop');
grid on;

subplot(1,2,2);
bar([ripple_PO, ripple_NN]);
set(gca, 'XTickLabel', {'P&O', 'Neural Network'});
ylabel('Steady-State Ripple (kW, peak-to-peak)');
title('Power Oscillation at Steady State');
grid on;

fprintf('\n--- QUANTIFIED RESULTS ---\n');
fprintf('Settling time after drop:  P&O = %.4f s | NN = %.4f s\n', settle_PO_drop, settle_NN_drop);
fprintf('Steady-state ripple:       P&O = %.4f kW | NN = %.4f kW\n', ripple_PO, ripple_NN);

%% ---- Helper function: settling time ----
function ts = find_settling_time(t, y, t_disturbance, final_value, tol)
    % Finds time (relative to t_disturbance) until y stays within
    % +/- tol*|final_value| of final_value, and never leaves that band again.
    band = tol * abs(final_value);
    idx_start = find(t >= t_disturbance, 1);
    settled_idx = idx_start;
    for k = idx_start:length(y)
        if abs(y(k) - final_value) > band
            settled_idx = k;
        end
    end
    ts = t(settled_idx) - t_disturbance;
end
