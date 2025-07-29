%% calc_torsQ.m
% Atkin Hyatt 09/21/2023
%
% Last revised by Atkin Hyatt on 07/23/2025
%
% Objective function which finds the Q of the first order torsional mode.
% Note that the number of modes to solve for in COMSOL needs to be
% sufficiently low such that the only torsional mode present is the first
% order mode. This is because the algorithm makes the assumptoin that the
% first order torional mode has the highest contribution to the total
% rotational energy of the resonator which may not be the case in the
% presence of higher order modes. Also calculates maximum stress and
% rejects any design which exceeds the yield strength of SiN.

function [Q,constr,extraData] = calc_torsQ(z)
    % Ensure COMSOL server is established
    import com.comsol.model.*
    import com.comsol.model.util.*
    
    % Extract parameters
    parameters = z{1,:};    % parameters are stored in a table class type
    P = globalParameters();         % call ResOpt object from master script

    % Generate beam, load into comsol
    model = mphload(P.filename);
    for ii = 1 : P.numOpt
        model.param.set(P.varNames(ii),parameters(ii));     % set optimizable parameters
    end
    for ii = 1 : P.numStat
        model.param.set(P.staticParams{ii,1},P.staticParams{ii,2});     % set static parameters
    end

    % Run comsol solver, extract useful data
    model.sol.run;
    Qvals = model.result.numerical('gev2').getReal;                 % evaluate Q of first few (check model) modes
    participationFactors = model.result.numerical('gev1').getReal;              % measure of how much energy is contributing to y-rot (check model)
    freq = mphglobal(model,'freq');                         % frequencies
    vonMisses = model.result.numerical('max1').getReal;             % max von misses stress, keep < 6 GPa

    % Determine torsional mode index and Q
    index = participationFactors == max(participationFactors);      % torsional modes contribute the most rotational energy, if no higher order modes are present, this reliably gives the first order torsional mode
    Q = -1*Qvals(index);                % bayesopt only minimizes so Q -> -Q for maximization

    % Record frequency
    extraData = freq(index);

    % Test constraints
    constr = vonMisses - 4e9;           % evaluate max stress, make sure it's under 6 GPa (use 4 GPa as a FOS), set # of coupled constraints to 1
    
    % Close model
    ModelUtil.remove('model');
    ModelUtil.clear;
end