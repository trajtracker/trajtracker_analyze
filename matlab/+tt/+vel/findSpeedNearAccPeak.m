function findSpeedNearAccPeak(allExpData, varargin)
% findSpeedNearAccPeak(allExpData) -
% Get the speed before and after each acceleration peak.
% 
% Optional args:
% DelayAfter <#>: Delay from peak until the beginning of the post- time window
% DelayBefore <#>: Delay from peak until the end of the pre- time window
% MinTime <#>: don't use information before this time
    
    [delayAfter, delayBefore, minTime, isXY] = parseArgs(varargin);
    
    trials = tt.util.getAllTrials(allExpData);
    samplingRate = trials(1).SamplingRate;
    minRow = round(minTime/samplingRate)+1;
    delayAfter = round(delayAfter/samplingRate);
    delayBefore = round(delayBefore/samplingRate);
    
    if isXY
        velBeforeAccPeak = 'XYVelBeforeAccPeak';
        velAfterAccPeak = 'XYVelAfterAccPeak';
        dVelAtAccPeak = 'dXYVelAtAccPeak';
        getVelocity = @getXYVelocity;
    else
        velBeforeAccPeak = 'YVelBeforeAccPeak';
        velAfterAccPeak = 'YVelAfterAccPeak';
        dVelAtAccPeak = 'dYVelAtAccPeak';
        getVelocity = @(trial, rows)trial.Trajectory(rows, TrajCols.YVelocity);
    end
    
    nBef = 0;
    nAfter = 0;
    
    for trial = trials
        
        trial.Custom.(velBeforeAccPeak) = NaN;
        trial.Custom.(velAfterAccPeak) = NaN;
        trial.Custom.(dVelAtAccPeak) = NaN;
        
        peakRow = find(trial.Trajectory(:, TrajCols.AbsTime) >= trial.Custom.AccelPeaksTimesP(1)/1000, 1);
        if isempty(peakRow)
            continue;
        end
        
        nRows = size(trial.Trajectory, 1);
        if peakRow + delayAfter <= nRows % Make sure peak is not too late
            trial.Custom.(velAfterAccPeak) = getVelocity(trial, peakRow + delayAfter);
            nAfter = nAfter+1;
        end
    
        if peakRow - delayAfter >= minRow % Make sure peak is not too early
            trial.Custom.(velBeforeAccPeak) = getVelocity(trial, peakRow - delayBefore);
            nBef = nBef+1;
        end
        
        trial.Custom.(dVelAtAccPeak) = trial.Custom.(velAfterAccPeak) - trial.Custom.(velBeforeAccPeak);
        
    end

    n = length(trials);
    fprintf('Found before-peak speed for %d%% of the trials and after-peak speed for %d%%\n', round(100*nBef/n), round(100*nAfter/n));
    
    %--------------------------------------------------------------
    function v = getXYVelocity(trial, rows)
        velInf = tt.vel.getTrialVelocity(trial, 'Axis', 'xy', 'CSmooth', 'Gauss', 0.02);
        v = velInf.velocity(rows);
    end

    %--------------------------------------------------------------
    function [delayAfter, delayBefore, minTime, isXY] = parseArgs(args)
        
        delayAfter = 0;
        delayBefore = 0;
        minTime = 0;
        isXY = false;
        
        args = stripArgs(args);
        while ~isempty(args)
            
            switch(lower(args{1}))
                case 'delayafter'
                    delayAfter = args{2};
                    args = args(2:end);
                    
                case 'delaybefore'
                    delayBefore = args{2};
                    args = args(2:end);
                    
                case 'mintime'
                    minTime = args{2};
                    args = args(2:end);
                    
                case 'xy'
                    isXY = true;
                    
                otherwise
                    error('Unsupported argument "%s"', args{1});
            end
            
            args = stripArgs(args(2:end));
            
        end
        
    end


end
