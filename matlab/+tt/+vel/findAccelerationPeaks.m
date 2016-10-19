function findAccelerationPeaks(allExpData, varargin)
% findAccelerationPeaks(allED) - Find the 2 largest peaks of positive/negative
% acceleration per trial.
% 
% Optional args:
% PeakLen <seconds> - duration of acceleration peak
% SafeZone <seconds> - when a peak was found, don't look for a 2nd peak in
%                      this area around the first peak.

    trials = tt.util.getAllTrials(allExpData);
    [convNRows, accelPeakIgnoreNRows] = parseArgs(varargin, trials(1).SamplingRate);
    
    for trial = trials
        [p1, p2, p1t, p2t] = findPerTrial(trial, 1, convNRows, accelPeakIgnoreNRows);
        [n1, n2, n1t, n2t] = findPerTrial(trial, 1, convNRows, accelPeakIgnoreNRows);
        trial.Custom.AccelPeaksP = [p1 p2];
        trial.Custom.AccelPeaksTimesP = [p1t p2t];
        trial.Custom.AccelPeaksN = [n1 n2];
        trial.Custom.AccelPeaksTimesN = [n1t n2t];
    end
    
    %-------------------------------------------
    function [peak1, peak2, peak1Time, peak2Time] = findPerTrial(trial, expectedSign, convNRows, accelPeakIgnoreNRows)
        peak1 = NaN;
        peak2 = NaN;
        peak1Time = NaN;
        peak2Time = NaN;

        accel = conv(trial.Trajectory(:, TrajCols.YAcceleration), ones(convNRows, 1), 'valid');
        times = trial.Trajectory(convNRows:end, TrajCols.AbsTime);

        % Look only for accelerations in the required direction
        accel = accel * expectedSign;
        accel(1:accelPeakIgnoreNRows) = 0;
        good = accel > 0;
        accel(~good) = 0;
        if sum(good) == 0
            return;
        end

        % Find first peak
        [peak1,i] = max(accel);
        peak1Time = round(1000*times(i));

        % clear data around first peak
        accel(max(1, i-convNRows) : min(length(accel),i+convNRows)) = 0;

        % Find second peak
        [~,i] = max(accel);
        if isempty(i)
            return;
        end
        peak2 = accel(i);
        peak2Time = round(1000*times(i));

    end


    %--------------------------------------------------------------
    function [convNRows, accelPeakIgnoreNRows] = parseArgs(args, samplingRate)
        
        convNRows = 15;
        accelPeakIgnoreNRows = 10;
        
        args = stripArgs(args);
        while ~isempty(args)
            
            switch(lower(args{1}))
                case 'peaklen'
                    convNRows = round(args{2} / samplingRate);
                    args = args(2:end);
                
                case 'safezone'
                    accelPeakIgnoreNRows = round(args{2} / samplingRate);
                    args = args(2:end);
                
                otherwise
                    error('Unsupported argument "%s"', args{1});
            end
            
            args = stripArgs(args(2:end));
            
        end
        
    end

end

