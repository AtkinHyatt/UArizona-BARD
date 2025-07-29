%% ResOpt.m
% Atkin Hyatt 09/21/2023
%
% Last revised by Atkin Hyatt on 04/16/2024
%
% Defines the ResOpt object which contains everything needed to complete an
% optimization.

classdef ResOpt
    properties
        % File and session names
        name (1,:) char = 'Don Q-Xote'
        pathname (1,:) char = ''
        filename (1,:) char = ''
        figNum (1,1) uint16 = 1

        % Basic settings
        maxit (1,1) uint16 = 30                    % maximum number of iterations performed
        initialNum (1,1) uint16 = 10            % initial number of random samples to take before optimizing
        expRatio (1,1) double = 0.3                 % exploration ratio for 'expected-improvement-plus' mode

        % Optimization settings
        funcs (1,:) function_handle                      % functions to call during optimization
        objectiveFunction function_handle              % objective function to min/max
        acqfunc (1,:) char = 'expected-improvement-plus'            % acquition function
        constraints function_handle                 % constraints on optimizable variable values

        % Optimizable variables
        varNames (1,:) string                         % variable names
        lims (:,2) double = []                      % parameter limits specified by numOpt x 2 2D array
        vars (1,:) optimizableVariable                             % array containing all optimizable variables

        % Static parameters
        staticParams (:,:) cell = {}              % parameters in the design which are not meant to be optimized but still may want to be controlled
        intermediateData (:,:) uint16                   % elements of the objective function which are evaluated but not directly optimized
    end
    properties (Dependent)
        numOpt                          % number of optimizeable variables
        numStat                         % number of static parameters
    end

    methods
        function P = ResOpt(varargin)
            for ii = 1 : 2 : numel(varargin)
                switch varargin{ii}
                    case 'Name'
                        P.name = varargin{ii+1};
                    case 'Filename'
                        P.filename = varargin{ii+1};
                    otherwise
                        error('Argument #%d not recognized',ii+2);
                end
            end
            if isempty(P.filename)
                [P.filename, P.pathname] = uigetfile('*.mph','Select COMSOL Design File');
            end
        end

        function numOpt = get.numOpt(P)             % number of optimizeable variables
            numOpt = length(P.varNames);
        end

        function numStat = get.numStat(P)           % number of static parameters
            [numStat,~] = size(P.staticParams);
        end

        function P = generateVars(P)                % generate variables of class "optimizableVarible" for bayesopt() function
            num = P.numOpt;
            for ii = 1 : num
                P.vars(ii) = optimizableVariable(char(P.varNames(ii)),P.lims(ii,:));
            end
        end
    end
end