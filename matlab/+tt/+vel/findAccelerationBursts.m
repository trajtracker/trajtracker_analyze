function findAccelerationBursts(allExpData, varargin)
% findAccelerationBursts(allExpData, ...) -
% Find acceleration bursts in each trial and write them on a custom attribute.
% An acceleration burst is a consecutive period of time in which
% the acceleration is higher than a certain threshold.
% 
% The following attributes will be saved per trial. Each of them is an
% array with one entry per burst. <pref> is a fixed prefix (default: 'X')
% <pref>AccelBurstsStartRows - first traj-matrix row number of the burst
% <pref>AccelBurstsEndRows - last traj-matrix row number of the burst
% <pref>AccelBurstsDirection - the burst direction (+1, -1)
% 
% Optional arguments:
% Axis <x/y> - the axis to use for acceleration
% MinAcc <#> - minimal acceleration that counts as a burst
% MinDur <#> - minimal burst duration
% MinTime <#> - ignore times before this
% Smooth <#> - Standard deviation for Gaussian smoothing of
%              velocities prior to deriving them into acceleration
% AttrPrefix <pref> - prefix of the saved custom attributes

    [minTime, minAcceleration, minDuration, accAxis, getVelocityArgs, customFieldNames] = parseArgs(varargin);

    allED = tt.util.structToArray(allExpData);
    samplingRate = allED(1).SamplingRate;
    minNSamples = round(minDuration / samplingRate);
    
    tt.util.doPerTrial(allExpData, @processTrial, 'Trials');
    
    
    %-------------------------------------------------
    function processTrial(trial, ~)
        
        switch(accAxis)
            case 'x'
                if isempty(getVelocityArgs)
                    accel = trial.Trajectory(:, TrajCols.XAcceleration);
                else
                    velInf = tt.vel.getTrialVelocity(trial, 'Axis', 'x', 'Acc', getVelocityArgs);
                    accel = velInf.acceleration;
                end
            case 'y'
                if isempty(getVelocityArgs)
                    accel = trial.Trajectory(:, TrajCols.YAcceleration);
                else
                    velInf = tt.vel.getTrialVelocity(trial, 'Axis', 'y', 'Acc', getVelocityArgs);
                    accel = velInf.acceleration;
                end
            case 'xy'
                velInf = tt.vel.getTrialVelocity(trial, 'Axis', 'xy', 'Acc', getVelocityArgs);
                accel = velInf.acceleration;
            otherwise
                error('Unsupported axis "%s"', accAxis);
        end

        goodTimes = trial.Trajectory(:, TrajCols.AbsTime) >= minTime;
        
        positiveAccel = (accel > minAcceleration) & goodTimes;
        [positiveBurstStartRows, positiveBurstEndRows] = findSequencesOf1(positiveAccel', minNSamples);
        
        negativeAccel = (accel < -minAcceleration) & goodTimes;
        [negativeBurstStartRows, negativeBurstEndRows] = findSequencesOf1(negativeAccel', minNSamples);
        
        startRows = [positiveBurstStartRows negativeBurstStartRows];
        endRows = [positiveBurstEndRows negativeBurstEndRows];
        directions = [ones(1, length(positiveBurstStartRows)), -ones(1, length(negativeBurstStartRows))];
        
        [startRows, sortInd] = sort(startRows);
        endRows = endRows(sortInd);
        directions = directions(sortInd);
        
        %-- If minTime was enforced, make sure the 1st acceleration burst
        %-- did not start before minTime
        if minTime > 0 && ~isempty(startRows) && startRows(1) > 1 && abs(accel(startRows(1)-1)) > minAcceleration
            startRows = startRows(2:end);
            endRows = endRows(2:end);
            directions = directions(2:end);
        end
        
        trial.Custom.(customFieldNames.AccelBurstsStartRows) = startRows;
        trial.Custom.(customFieldNames.AccelBurstsEndRows) = endRows;
        trial.Custom.(customFieldNames.AccelBurstsDirection) = directions;
        
    end
    
    %-------------------------------------------------
    function [minTime, minAcceleration, minDuration, accAxis, getVelocityArgs, customFieldNames] = parseArgs(args)
        
        minTime = 0;
        minAcceleration = 2;
        minDuration = .1;
        accAxis = 'x';
        getVelocityArgs = {};
        fldPrefix = 'X';

        args = stripArgs(args);
        while ~isempty(args)
            switch(lower(args{1}))
                case 'mintime'
                    minTime = args{2};
                    args = args(2:end);
                    
                case 'minacc'
                    minAcceleration = args{2};
                    args = args(2:end);
                    
                case 'mindur'
                    minDuration = args{2};
                    args = args(2:end);

                case 'attrprefix'
                    fldPrefix = args{2};
                    args = args(2:end);

                case 'axis'
                    accAxis = lower(args{2});
                    if ~ismember(accAxis, {'x', 'y', 'xy'})
                        error('Invalid Axis (%s)', args{2});
                    end
                    args = args(2:end);
                    
                case 'smooth'
                    getVelocityArgs = [getVelocityArgs, {'VSmooth', 'Gauss', args{2}}]; %#ok<AGROW>
                    args = args(2:end);
                    
                otherwise
                    error('Unsupported argument "%s"', args{1});
            end
            
            args = stripArgs(args(2:end));
        end
        
        if isempty(fldPrefix), fldPrefix = upper(accAxis); end;
        customFieldNames = struct;
        customFieldNames.AccelBurstsStartRows = strcat(fldPrefix, 'AccelBurstsStartRows');
        customFieldNames.AccelBurstsEndRows = strcat(fldPrefix, 'AccelBurstsEndRows');
        customFieldNames.AccelBurstsDirection = strcat(fldPrefix, 'AccelBurstsDirection');
    end
    
end

