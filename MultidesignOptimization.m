%% UniversalOptimization.m
% Atkin Hyatt 09/21/2023
%
% Last revised by Atkin Hyatt on 07/23/2025
%
% Performs multi-variable optimization on a parametricized COMSOL design
% using MATLAB's bayesopt() function. This script allows a user to sweep a
% constant design parameter and perform optimization on several designs
% sequentially. Good for performing studies into feasibility or with
% studying the behavior of a class of resonators.

clear; clc

% Width sweep
wid = [25 50 100 200 400 600 800 1000]*1e-6;

for ii = 1 : length(wid)
%% Initialize Optimization Object
%P = BeamOpt('Filename','beamSim.mph');
P = ResOpt('Name',[num2str(40) 'nm Thick, ' num2str(wid(ii)*1e6) 'um Wide Diagonal Ribbon'],'Filename','diagBeam.mph');
fprintf('%s initialized, optimizing COMSOL file ''%s''\n',P.name,P.filename);
save = true;
eval = false;

%% Define Problem Parameters
% Optimizable variables
P.varNames = ['rad'];             % variable names (as used in the selected COMSOL file)

% Limits are width-dependent
if wid(ii) <= 100e-6
    P.lims = [10e-6 100e-6];
elseif wid(ii) > 100e-6 && wid(ii) < 400e-6
    P.lims = [10e-6 1000e-6];
elseif wid(ii) >= 400e-6
    P.lims = [200e-6 1e-3];
end

% Create optimizable variables
P = generateVars(P);            % create optimizable variables

% Define static parameters
P.staticParams = {'len',7e-3; 'meshDens',1; 'thic',90e-9; 'wid',wid(ii)};

%% Adjust Optimizer Settings
P.maxit = 20;                    % maximum number of iterations performed
P.initialNum = 5;            % initial number of random samples to take before optimizing
P.expRatio = 0.3;                 % exploration ratio for 'expected-improvement-plus' mode

P.funcs = @DoNothing;                      % functions to call during optimization
P.objectiveFunction = @calc_torsQ;               % objective function to min/max
P.acqfunc = 'expected-improvement-plus';            % acquition function
%P.constraints = {};                     % constraints on variable values

%% Data Save Setup
if save
    outputs = {@saveToFile P.funcs};        % @saveToFile is a built-in function
else
    outputs = P.funcs;
end

%% Optimize
% Save beamOpt object (do not delete)
globalParameters(P);

% Run the optimizer
results = bayesopt(P.objectiveFunction,P.vars,'AcquisitionFunctionName',P.acqfunc,'MaxObjectiveEvaluations',P.maxit,...
    'NumSeedPoints',P.initialNum,'OutputFcn',outputs,'SaveFileName',P.name,'ExplorationRatio',P.expRatio,...
    'PlotFcn',[],'XConstraintFcn',P.constraints,'NumCoupledConstraints',1);

% Collect results
bestParams(ii,:) = results.XAtMinObjective{1,:};
Q(ii) = -1*results.MinObjective;
freq(ii) = results.UserDataTrace{end};

%% Re-evaluate
if eval
    % Change the mesh size or whatnot and re-evaluate if needed
    P.staticParams = {'len',7e-3; 'meshDens',5; 'thic',90e-9};
    globalParameters(P);        % Save changes to object

    % Call objective function
    [Q,~,freq] = P.objectiveFunction(results.XAtMinObjective);
end

%% Display
fprintf('Optimal design objective = %e with f = %d kHz\n',Q,freq*1e-3);
end