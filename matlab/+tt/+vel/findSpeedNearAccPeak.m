function findSpeedNearAccPeak(allExpData, varargin)
% findSpeedNearAccPeak(allExpData) -
% Get the speed before and after each acceleration peak.
% 
% Optional args:
% DelayAfter <#>: Delay from peak until the beginning of the post- time window
% DelayBefore <#>: Delay from peak until the end of the pre- time window
% MinTime <#>: don't use information before this time
    
    [delayAfter, delayBefore, minTime] = parseArgs(varargin);
    
    trials = tt.util.getAllTrials(allExpData);
    samplingRate = trials(1).SamplingRate;
    minRow = round(minTime/samplingRate)+1;
    delayAfter = round(delayAfter/samplingRate);
    delayBefore = round(delayBefore/samplingRate);
    
    nBef = 0;
    nAfter = 0;
    
    for trial = trials
        
        trial.Custom.YVelAfterAccPeak = NaN;
        trial.Custom.YVelBeforeAccPeak = NaN;
        trial.Custom.dYVelAtAccPeak = NaN;
        
        peakRow = find(trial.Trajectory(:, TrajCols.AbsTime) >= trial.Custom.AccelPeaksTimesP(1)/1000, 1);
        if isempty(peakRow)
            continue;
        end
        
        nRows = size(trial.Trajectory, 1);
        if peakRow + delayAfter <= nRows % Make sure peak is not too late
            trial.Custom.YVelAfterAccPeak = trial.Trajectory(peakRow + delayAfter, TrajCols.YVelocity);
            nAfter = nAfter+1;
        end
    
        if peakRow - delayAfter >= minRow % Make sure peak is not too early
            trial.Custom.YVelBeforeAccPeak = trial.Trajectory(peakRow - delayBefore, TrajCols.YVelocity);
            nBef = nBef+1;
        end
        
        trial.Custom.dYVelAtAccPeak = trial.Custom.YVelAfterAccPeak - trial.Custom.YVelBeforeAccPeak;
        
    end

    n = length(trials);
    fprintf('Found before-peak speed for %d%% of the trials and after-peak speed for %d%%\n', round(100*nBef/n), round(100*nAfter/n));
    
    %--------------------------------------------------------------
    function [delayAfter, delayBefore, minTime] = parseArgs(args)
        
        delayAfter = 0;
        delayBefore = 0;
        minTime = 0;
        
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
                    
                otherwise
                    error('Unsupported argument "%s"', args{1});
            end
            
            args = stripArgs(args(2:end));
            
        end
        
    end


end
