%% no_constraints.m
% Atkin Hyatt 04/10/2025
%
% Last revised by Atkin Hyatt on 04/10/2025
%
% Contraint function which does nothing. Declares no constraints in such a
% way to avoid error and warning messages.

function tf = no_constraints(params)
    % Output true for all param combos (do nothing)
    params_mat = table2array(params);
    tf = isfinite(params_mat(:,1));
end