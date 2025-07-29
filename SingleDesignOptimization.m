%% SingleDesignOptimization.m
% Atkin Hyatt 09/21/2023
%
% Last revised by Atkin Hyatt on 07/23/2025
%
% Performs multi-variable optimization on a parametricized COMSOL design
% using MATLAB's bayesopt() function. This script runs a COMSOL simulation
% using LiveLink and extracts the results for Matlab to process. Though the
% bayesopt() function can be used on its own, this script attempts to
% simplify its use as well as provide a blueprint for integrating design
% optimization into other future programming endeavors. For more on the
% Bayesian optimization algorithm, see reference folder.
%
% Note that there are two ways to select your COMSOL file. One way is to
% specify the name of the file when initializing the 'ResOpt' object.
% The other is to simply leave it blank. The code will pull up a UI for you
% to look for it in your finder/library.
%
% There are a lot of things to keep track of in terms of the design and
% algorithm control but here's the gist:
%   1) P.varNames and P.lims specify which parameters to optimize and what
%      their bounds are
%   2) P.staticParams are parameters which are held constant throughout the
%      optimization but the user wants to control outside of COMSOL
%   3) P.maxit tells bayesopt the maximum number of times it should sample
%      the objective function while P.initialNum specifies the first N of
%      those samples to be random (not following the acquisition function).
%   4) P.expRatio controls the how much the algorithm should explore new
%      regions of the parameter space rather than exploiting local regions.
%      Good for avoiding local optima.
%   5) P.funcs is a cell array of function handles referencing any function
%      that should be called after every iteration of the optimizer, good
%      for displaying intermediate results.
%   6) P.objectiveFunction is the objective function to optimize. Crafting
%      the objective function is a bit weird and requires some programming
%      shenanigans, see the readme.
%   7) P.constraints provides the algorithm with a set of logical
%      constraints on parameters (x1 > x2 or x1 + x2 ~= 1, etc)

% TLDR: Optimizes COMSOL files given parameters and their constraints

clear; clc; close all

%% Initialize Optimization Object
%P = ResOpt('Filename',' ');
P = ResOpt();
P.name = 'Rectangular Ribbon with Elliptical Fillets';
fprintf('%s initialized, optimizing COMSOL file ''%s''\n',P.name,P.filename);
eval = false;
save = true;

%% Define Problem Parameters
% Optimizable variables
P.varNames = ["xrad" "yrad"];             % variable names (as used in the selected COMSOL file)
P.lims = [10e-6 1750e-6; 10e-6 1750e-6];         % variable limits

% Create optimizable variables
P = generateVars(P);            % create optimizable variables, don't forget this step

% Define static parameters
P.staticParams = {'len',7e-3; 'wid',400e-6; 'meshDens',1; 'thic',90e-9};          % user defined parameters to keep controlled

%% Adjust Optimizer Settings
P.maxit = 20;                    % maximum number of iterations performed
P.initialNum = 5;            % initial number of random samples to take before optimizing based on the acquisition function
P.expRatio = 0.3;                 % exploration ratio for 'expected-improvement-plus' mode

P.funcs = @trackOptimization;                      % functions to call during optimization
%P.funcs = @DoNothing;                              % turn off plotting
P.objectiveFunction = @calc_torsQ;               % objective function to min/max
P.acqfunc = 'expected-improvement-plus';            % acquition function type
P.constraints = @no_constraints;
%P.constraints = @constraints;                     % constraints function on parameter values

%% Data Save Setup
if save
    outputs = {@saveToFile P.funcs};        % @saveToFile is a built-in function
else
    outputs = P.funcs;
end

%% Optimize
% Save ResOpt object for objective function to access later (do not delete)
globalParameters(P);

% Run the optimizer
results = bayesopt(P.objectiveFunction,P.vars,'AcquisitionFunctionName',P.acqfunc,'MaxObjectiveEvaluations',P.maxit,...
    'NumSeedPoints',P.initialNum,'OutputFcn',outputs,'SaveFileName',P.name,'ExplorationRatio',P.expRatio,...
    'PlotFcn',[],'XConstraintFcn',P.constraints,'NumCoupledConstraints',1);

% Collect the results
bestParams = results.XAtMinObjective{1,:};
Q = -1*results.MinObjective;
freq = results.UserDataTrace{end};

%% Re-evaluate
if eval
    fprintf('Re-evaluating Best Design...\n');

    % Change the mesh size or whatnot and re-evaluate if needed
    P.staticParams = {'len',7e-3; 'meshDens',10; 'thic',90e-9};
    globalParameters(P);        % Save changes to object

    % Call objective function
    [Q,~,freq] = P.objectiveFunction(results.XAtMinObjective);
end

%% Display
fprintf('Optimal design objective = %e at f = %d\n',Q,freq);