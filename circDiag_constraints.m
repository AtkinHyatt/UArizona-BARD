%% circDiag_constraints.m
% Atkin Hyatt 07/23/2024
%
% Last revised by Atkin Hyatt on 07/23/2025
%
% Contraint function which ensures that circular fillets for diagonal
% beams are feasible. Note that in this file, the ribbon width is extracted
% as a static parameter by default.

function tf = circDiag_constraints(params)
    % Extract optimizable parameters
    % wid = params.wid;
    rad = params.rad;
    
    % Extract static parameters
    P = globalParameters();
    wid = P.staticParams{2,2};
    len = P.staticParams{1,2};

    % Test params, throw out bad combinations
    tf1 = rad < 1/sqrt(2) * (len - wid);

    % Combine logic expressions
    tf = tf1;
end