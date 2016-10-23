function foundErrors = setTrialVelocityOnsetTime(allExpData, subjInitials, trialNum, onsetTimes, peakTimes, wrongDir, changeOfMind, override)
%setTrialVelocityOnsetTime(allExpData, subj, trialNum, onsetTimes, peakTimes, wrongDir, changeOfMind, override)
% manually set the trial's X velocity onset (and potentially the peak) time
% 
% This is used for updating manually-defined onsets, after you encoded them
% with encodeVelocityOnsetManually()

    foundErrors = false;
    
    expData = allExpData.(subjInitials);

    if ~exist('override', 'var')
        override = 0;
    end

    trial = expData.Trials(arrayfun(@(t)t.TrialNum==trialNum, expData.Trials));
    if length(trial) ~= 1
        error('Trial %d not found for %s', trialNum, expData.SubjectInitials);
    end

    if ~isempty(trial.Custom.XVelocityOnsetTime) && ~override
        fprintf('ERROR: Onset time is already updated (%s, subject %s, trial #%d)!\n', allExpData.general.CondName, subjInitials, trialNum);
        foundErrors = true;
    end

    vi = tt.vel.getTrialVelocity(trial, 'Smooth', 'Gauss', 0.02);

    trial.Custom.XVelocityOnsetTimes = onsetTimes;
    trial.Custom.XVelocityOnsetRows = arrayfun(@(t)find(trial.Trajectory(:, TrajCols.AbsTime) >= t, 1), onsetTimes);
    if isempty(onsetTimes)
        trial.Custom.XVelocityOnsetTime = [];
        trial.Custom.XVelocityOnsetRow = [];
        trial.Custom.XVelocityLastOnsetTime = [];
        trial.Custom.XVelocityLastOnsetRow = [];
    else
        trial.Custom.XVelocityOnsetTime = onsetTimes(1);
        trial.Custom.XVelocityOnsetRow = trial.Custom.XVelocityOnsetRows(1);
        trial.Custom.XVelocityLastOnsetTime = onsetTimes(end);
        trial.Custom.XVelocityLastOnsetRow = trial.Custom.XVelocityOnsetRows(end);
    end

    trial.Custom.XVelocityPeakTimes = peakTimes;
    trial.Custom.XVelocityPeakRows = arrayfun(@(t)find(trial.Trajectory(:,TrajCols.AbsTime) >= t, 1), peakTimes);
    rows = arrayfun(@(t)find(vi.times >= t, 1), peakTimes);
    trial.Custom.XVelocityPeaks = vi.velocity(rows);

    if isempty(peakTimes)

        trial.Custom.XVelocityPeakTime = [];

    else

        trial.Custom.XVelocityPeakTime = peakTimes(1);

        % Validae that peak is in the correct direction
        targetIsLeft = trial.Target < expData.MaxTarget/2;
        peakIsLeft = vi.velocity(rows(1)) < 0;
        if (targetIsLeft ~= peakIsLeft)
            DIRECTIONS = {'rightwards', 'leftwards'};
            fprintf('Error in manually-encoded velocity of %s(%s), trial #%d: target=%d but the velocity goes %s\n', ...
                allExpData.general.CondName, subjInitials, trial.TrialNum, trial.Target, DIRECTIONS{peakIsLeft+1});
            foundErrors = 1;
        end

    end

    trial.Custom.XVelocityOnsetFound = true;
    trial.Custom.XVelocityOnsetEncoder = 'user';
    trial.Custom.ChangeOfMind = logical(changeOfMind);
    trial.Custom.WrongDirection = logical(wrongDir);
        
end

