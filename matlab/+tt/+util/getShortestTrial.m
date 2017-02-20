function [trial, shortestTrialInd] = getShortestTrial(trials)
% [trial, shortestTrialInd] = getShortestTrial(trials) -
% From the given array of trials, return the one with shortest movement
% time, and its index in the input array.

    [~,shortestTrialInd] = min(arrayfun(@(t)getMovementTimeForValidTrial(t), trials));
    trial = trials(shortestTrialInd);
    
    %-----------------------------------------------------
    function mt = getMovementTimeForValidTrial(trial)
        if ~isempty(trial.Trajectory)
            mt = trial.Trajectory(end, TrajCols.AbsTime);
        else
            mt = -1;
        end
    end
    
end
