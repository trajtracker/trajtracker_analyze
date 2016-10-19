function [trial, longestTrialInd] = getLongestTrial(trials)
% [trial, longestTrialInd] = getLongestTrial(trials) -
% From the given array of trials, return the one with longest movement
% time, and its index in the input array.

    [~,longestTrialInd] = max(arrayfun(@(t)getMovementTimeForValidTrial(t), trials));
    trial = trials(longestTrialInd);
    
    %-----------------------------------------------------
    function mt = getMovementTimeForValidTrial(trial)
        if ~isempty(trial.Trajectory)
            mt = trial.Trajectory(end, TrajCols.AbsTime);
        else
            mt = -1;
        end
    end
    
end
