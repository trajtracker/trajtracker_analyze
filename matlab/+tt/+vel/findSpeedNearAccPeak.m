function findSpeedNearAccPeak(allExpData, varargin)
% findSpeedNearAccPeak(allExpData)
% After an acceleraiton peak was found: calculate the speed before and
% after it.
% 
% Optional args:
% Duration <#>: the duration of the time window to use for speed calculation
% DelayAfter <#>: Delay from peak until the beginning of the post- time window
% DelayBefore <#>: Delay from peak until the end of the pre- time window
% MinTime <#>: don't use information before this time
    
    [windowLen, delayAfter, delayBefore, minTime] = parseArgs(varargin);
    
    trials = tt.util.getAllTrials(allExpData);
    samplingRate = trials(1).SamplingRate;
    minRow = round(minTime/samplingRate)+1;
    windowNRows = round(windowLen/samplingRate);
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
        if peakRow + delayAfter + windowNRows/2 <= nRows
            % Peak is not too late
            r1 = peakRow + delayAfter;
            r2 = min(r1 + windowNRows, nRows);
            trial.Custom.YVelAfterAccPeak = diff(trial.Trajectory([r1 r2], TrajCols.Y)) / ((r2-r1)*samplingRate);
            nAfter = nAfter+1;
        end
    
        if peakRow - delayAfter - windowNRows/2 >= minRow
            % Peak is not too early
            r2 = peakRow - delayBefore;
            r1 = max(r2 - windowNRows, minRow);
            trial.Custom.YVelBeforeAccPeak = diff(trial.Trajectory([r1 r2], TrajCols.Y)) / ((r2-r1)*samplingRate);
            nBef = nBef+1;
        end
        
        trial.Custom.dYVelAtAccPeak = trial.Custom.YVelAfterAccPeak - trial.Custom.YVelBeforeAccPeak;
        
    end

    n = length(trials);
    fprintf('Found before-peak speed for %d%% of the trials and after-peak speed for %d%%\n', round(100*nBef/n), round(100*nAfter/n));
    
    %--------------------------------------------------------------
    function [windowLen, delayAfter, delayBefore, minTime] = parseArgs(args)
        
        windowLen = 0.2;
        delayAfter = 0;
        delayBefore = 0;
        minTime = 0;
        
        args = stripArgs(args);
        while ~isempty(args)
            
            switch(lower(args{1}))
                case 'duration'
                    windowLen = args{2};
                    args = args(2:end);
                    
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
