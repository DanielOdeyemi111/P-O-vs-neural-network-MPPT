function D = nn_mppt_controller(Enabled, Irradiance, V, I, Dmax, Dmin, Dinit)
%#codegen
% Neural-Network-based MPPT controller — drop-in replacement for the
% PandO.m block used in Model 1. Same D output role: reference for the
% DC link voltage (Vdc_ref), feeding the same VDC Regulator -> Current
% Regulator -> PWM chain.
%
% Requires nn_mppt_generated.m in the same folder / on the MATLAB path
% (created via: genFunction(net, 'nn_mppt_generated', 'MatrixOnly', 'yes'))

persistent Dold;
if isempty(Dold)
    Dold = Dinit;
end

if Enabled ~= 0
    D = nn_mppt_generated(Irradiance);   % predicted Vdc_ref from irradiance
else
    D = Dold;
end

% Same safety clamping as the P&O controller, for a fair comparison
if D >= Dmax || D <= Dmin
    D = Dold;
end

Dold = D;
end
