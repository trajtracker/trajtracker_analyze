function markBackMovementError(expData, includedErrCodes)
% markBackMovementError(expData) -
% Mark trials in which the trajectory has 2 time points with the same Y
% value.
% This can happen due to backward movement, and it may cause errors
% in various spline calculations.

    if ~exist('includedErrCodes', 'var'), includedErrCodes=[]; end;
    
    includedErrCodes = unique([includedErrCodes TrialErrCodes.OK]);
    trialsToProcess = expData.Trials(arrayfun(@(t)~isempty(t.Trajectory) && ismember(t.ErrCode, includedErrCodes), expData.Trials));

    for trial = trialsToProcess
        
        if containsDuplicates(trial.Trajectory(:, TrajCols.Y)) || ...
            (~isempty(trial.NormalizedTrajectory) && containsDuplicates(trial.NormalizedTrajectory(:, TrajCols.Y)))
        
            trial.ErrCode = TrialErrCodes.BackMovement;
            fprintf('      Trial #%d excluded due to backward movement\n', trial.TrialNum);
        end
        
    end

    %--------------------------------------------------
    function c = containsDuplicates(v)
        c = sum(diff(sort(v)) == 0) > 0;
    end

end

