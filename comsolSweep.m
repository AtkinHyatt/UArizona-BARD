%% comsolSweep.m
% Atkin Hyatt 09/21/2023
%
% Last revised by Atkin Hyatt on 04/16/2024
%
% Performs simulations on a series of resonators (no optimization). Good
% for evaluating the performance of a set of resonators where optimization
% is not necessary.

clear; clc; close all

% COMSOL stuff
import com.comsol.model.*
import com.comsol.model.util.*

% Some parameters which stay constant throughout the sweep
len = 7e-3;
thic = 90e-9;
meshDens = 5;

% Define width and fillet radii sweep
wid = [400 600 800 1000]*1e-6; num = length(wid);
rad = [400 600 800 1000]*1e-6;
Q_rect = zeros(1,num); Q_diag = Q_rect;

% Open the model, set static parameters
model = mphload('rectBeamSim.mph');
model.param.set('len',len);
model.param.set('mesh_dens',meshDens);
model.param.set('thic',thic);

% Begin sweep
for ii = 1 : num
    fprintf('Calculating %d [μm] rectangular beam...\n',wid(ii)*1e6);
    
    % Set parameters to sweep
    model.param.set('wid',wid(ii));
    model.param.set('rad',rad(ii));

    % Run comsol solver, extract useful data
    model.sol.run;
    Qvals = model.result.numerical('gev2').getReal;
    participationFactors = model.result.numerical('gev1').getReal;

    % Determine torsional mode and Q
    Q = Qvals(participationFactors == max(participationFactors));
    Q_rect(ii) = Q;
    fprintf('\tQ = %f\n\n',Q);
end

ModelUtil.clear;