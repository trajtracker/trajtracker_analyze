function [trial, longestTrialInd] = getLongestTrial(trials)

    [~,longestTrialInd] = max(arrayfun(@(t)getMovementTimeForValidTrial(t), trials));
    trial = trials(longestTrialInd);
    
    %-----------------------------------------------------
    function mt = getMovementTimeForValidTrial(trial)
        if ~isempty(trial.Trajectory)
            mt = trial.MovementTime;
        else
            mt = -1;
        end
    end
    
end
