%% ellipRect_constraints.m
% Atkin Hyatt 07/23/2024
%
% Last revised by Atkin Hyatt on 07/23/2025
%
% Contraint function which ensures that elliptical fillets for rectangular
% beams are feasible. Note that in this file, the ribbon width is extracted
% as a static parameter by default.

function tf = ellipRect_constraints(params)
    % Extract optimizable parameters
    % wid = params.wid;
    xrad = params.xrad;
    yrad = params.yrad;
    
    % Extract static parameters
    P = globalParameters();
    wid = P.staticParams{2,2};
    len = P.staticParams{1,2};

    % Test params, throw out bad combinations
    tf1 = yrad < len/2;
    tf2 = xrad < abs(len - wid)/2;

    % Combine logic expressions
    tf = tf1 & tf2;
end