%% trackOptimization.m
% Atkin Hyatt 09/21/2023
%
% Last revised by Atkin Hyatt on 07/23/2024
%
% Displays the results of each algorithm iteration in a 2x2 grid. Upper
% left and upper right subfigures display the resomator's geometry for both
% the current iteration as well as the best seen so far respectively. The
% lower subfigures plot the objective function vs iteration as well as the
% best observed objective function value vs iteration (a demonstration of
% convergence).

function stop = trackOptimization(results,state)
% Track number of function calls
persistent n bestTrace bestIt;
persistent h

import com.comsil.model.*
import com.comsol.model.util.*

% bayesopt sends the current state of the algorithm (initializing and iteration)
switch state
    case 'initial'
        % Setup figure window
        P = globalParameters();
        n = 0;
        h = figure('Name',['Optimization of ' P.name],'NumberTitle','off','units','normalized','outerposition',[0 0 1 1]);
        subplot(2,2,1); title('Best Design'); axis equal off; set(gca,'fontsize',14);
        subplot(2,2,2); title('Iteration 0'); axis equal off; set(gca,'fontsize',14);
        subplot(2,2,3); title('Objective Function Value vs Iteration'); xlabel('Iteration'); ylabel('Q'); set(gca,'fontsize',14); grid on; grid minor;
        subplot(2,2,4); title('Best Q vs Iteration'); xlabel('Iteration'); ylabel('Best Q'); set(gca,'fontsize',14); grid on; grid minor; drawnow
    case 'iteration'
        % Update figure window
        P = globalParameters();
        n = n + 1;
        figure(h);

        % Compare performance
        if n == 1
            bestIt = 1;
            bestTrace = results.ObjectiveTrace(1);
        elseif n > 1
            if results.ObjectiveTrace(n) < bestTrace
                bestTrace = results.ObjectiveTrace(n); bestIt = n;
            end
        end

        % Recreate model for current iteration
        model = mphload(P.filename);
        for ii = 1 : P.numStat
            model.param.set(P.staticParams{ii,1},P.staticParams{ii,2});
        end
        for ii = 1 : P.numOpt
            model.param.set(P.varNames(ii),results.XTrace{n,ii});
        end

        % Generate new figure
        label = ['Iteration ' num2str(n)];
        if n == bestIt
            % Update best geometry so far if current geometry exceeds previous
            subplot(2,2,1); mphgeom(model); title(['Best Design (Iteration ' num2str(bestIt) ')']); axis equal off;
            set(gca,'fontsize',14);
        end
        
        % Current geometry
        subplot(2,2,2); mphgeom(model); title(label); axis equal off;
        set(gca,'fontsize',14);
        
        % Objective function value vs algorithm iteration
        subplot(2,2,3); plot(1:n,-1*results.ObjectiveTrace,'linewidth',2); title('Objective Function Value vs Iteration'); xlabel('Iteration'); ylabel('Q');
        set(gca,'fontsize',14); grid on; grid minor;
        
        % Best objective function value bs algorithm iteration (convergence check)
        subplot(2,2,4); plot(1:n,-1*results.ObjectiveMinimumTrace,'linewidth',2); title('Best Objective Function Value vs Iteration'); xlabel('Iteration'); ylabel('Best Q');
        set(gca,'fontsize',14); grid on; grid minor; drawnow

        % Close model
        ModelUtil.clear;
    otherwise
end
stop = false;       % No stopping condition
end