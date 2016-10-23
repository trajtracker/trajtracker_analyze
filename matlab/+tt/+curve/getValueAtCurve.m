function value = getValueAtCurve(trial, curveNumber, atStart, trajCol)
%value = getValueAtCurve(trial, curveNumber, atStart, col) -
% Get a trajectory matrix value at the start/end of a certain curve.
% Before calling this, you must call findCurves()
% 
% trial: a trial object
% curveNumber: 1 = first curve, etc.
% atStart: whether to get the value from the curve's start or end
% trajCol: column in the trajectory matrix (TrajCols.####)

    if ~isfield(trial.Custom, 'ThetaChangeStartRows')
        error('Trajectory curves were not identified for trial #%d', trial.TrialNum);
    end

    value = NaN;
    
    if length(trial.Custom.ThetaChangeStartRows) < curveNumber
        fprintf('getValueAtCurve() WARNING: Invalid curve number (%d) - trial #%d has only %d curves', curveNumber, trial.TrialNum, length(trial.Custom.ThetaChangeStartRows));
        return;
    end
    
    if (atStart)
        value = trial.Trajectory(trial.Custom.ThetaChangeStartRows(curveNumber), trajCol); 
    else
        value = trial.Trajectory(trial.Custom.ThetaChangeEndRows(curveNumber), trajCol); 
    end

end

