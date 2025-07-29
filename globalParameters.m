function out = globalParameters(P)
    persistent Q
    if nargin == 1
        % Save input
        Q = P;
        out = [];
    else
        % Return input
        out = Q;
    end
end