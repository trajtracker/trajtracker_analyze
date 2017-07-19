function findCurves(allExpData, varargin)
%findCurves(allExpData, ...) -
% Find curves in trajectories - deviations of finger direction.
% A "deviation" is defined by several criteria, listed below.
% 
% Optional arguments:
% MinDur # : minimal duration (seconds) of the change
% MinChange # : the minimal total change of direction (degrees)
% MinCurvature # : minimal speed of changing theta (mean degrees per second)
% TrimThreshold # : theta/second values lower than this will be trimmed in the
%                   beginning and end of trajectories
% Smooth <seconds> : Apply Gaussian smoothing to theta values before starting
% TrialNum <#> : process only this trial (for debugging).

    [minDuration, minDTheta, minThetaChangeSpeed, thetaTrimThreshold, ...
        smoothFactor, dbgSingleTrialNumber, outAttrNames] = parseArgs(varargin);

    if isa(allExpData, 'ExperimentData')
        samplingRate = allExpData.SamplingRate;
    else
        allED = tt.util.structToArray(allExpData);
        samplingRate = allED(1).SamplingRate;
    end
    minNSamples = round(minDuration / samplingRate);
    
    if isempty(dbgSingleTrialNumber)
        
        % Standard mode
        tt.util.doPerTrial(allExpData, @processTrial, 'Trials', 'Trials');
        
    else
        
        % Debug mode
        trial = allExpData.getTrialByNum(dbgSingleTrialNumber);
        if isempty(trial)
            error('Trial #%d was not found', dbgSingleTrialNumber);
        end
        fprintf('Debug mode: processing only trial #%d\n', dbgSingleTrialNumber);
        processTrial(trial,1);
        
    end
    
    
    
    %-------------------------------------------------
    function processTrial(trial, ~)
        
        theta = trial.Trajectory(:, TrajCols.Theta);
        if (smoothFactor > 0)
            theta = smoothg(theta, smoothFactor/samplingRate);
        end
        dTheta = [0; diff(theta)] / samplingRate;
        
        thetaDirection = sign(dTheta)';
        
        [positiveStartRows, positiveEndRows] = findSequencesOf1(thetaDirection >= 0, minNSamples);
        [negativeStartRows, negativeEndRows] = findSequencesOf1(thetaDirection <= 0, minNSamples);
        
        startRows = [positiveStartRows negativeStartRows];
        endRows = [positiveEndRows negativeEndRows];
        
        [startRows, sortInd] = sort(startRows);
        endRows = endRows(sortInd);
        
        thetaChangeSize = (trial.Trajectory(endRows, TrajCols.Theta) - trial.Trajectory(startRows, TrajCols.Theta))';
        timeWindowDuration = (endRows - startRows) * samplingRate;
        
        % Filter the results
        
        goodCurves = true(size(startRows));
        
        % Remove low-change time points
        for i = 1:length(startRows)
            aboveThreshold = abs(dTheta(startRows(i):endRows(i))) >= thetaTrimThreshold;
            if sum(aboveThreshold) == 0
                % The whole time window doesn't cross the threshold:
                % remove it
                goodCurves(i) = false;
            else
                % Trim
                endRows(i) = startRows(i) + find(aboveThreshold, 1, 'last') - 1;
                startRows(i) = startRows(i) + find(aboveThreshold, 1) - 1;
                thetaChangeSize(i) = trial.Trajectory(endRows(i), TrajCols.Theta) - trial.Trajectory(startRows(i), TrajCols.Theta);
            end
        end
                
        if ~isempty(minDuration)
            goodCurves = goodCurves & (timeWindowDuration > minDuration);
        end
        
        if ~isempty(minDTheta)
            goodCurves = goodCurves & (abs(thetaChangeSize) > minDTheta);
        end
        
        if ~isempty(minThetaChangeSpeed)
            goodCurves = goodCurves & (abs(thetaChangeSize) ./ timeWindowDuration > minThetaChangeSpeed);
        end
        
        % Update trial
        
        if isempty(goodCurves)
            trial.Custom.ThetaChange1StartRow = [];
        else
            trial.Custom.ThetaChange1StartRow = startRows(find(goodCurves, 1));
        end
        trial.Custom.(outAttrNames.StartRows) = startRows(goodCurves);
        trial.Custom.(outAttrNames.EndRows) = endRows(goodCurves);
        trial.Custom.(outAttrNames.Direction) = thetaDirection(startRows(goodCurves));
        trial.Custom.(outAttrNames.Size) = thetaChangeSize(goodCurves);
        
    end
    
    %-------------------------------------------------
    function [minDuration, minDTheta, minThetaChangeSpeed, thetaTrimThreshold, ...
            smoothFactor, dbgSingleTrialNumber, outAttrNames] = parseArgs(args)
        
        minDuration = [];
        minDTheta = [];
        minThetaChangeSpeed = [];
        thetaTrimThreshold = 0.000000001;
        smoothFactor = 0;
        dbgSingleTrialNumber = [];
        
        outAttrPrefix = 'Curve';
        
        args = stripArgs(args);
        while ~isempty(args)
            switch(lower(args{1}))
                case 'mindur'
                    minDuration = args{2};
                    args = args(2:end);
                    
                case 'minchange'
                    minDTheta = args{2} / 360 * pi * 2;
                    args = args(2:end);
                    
                case {'mincurvature', 'mincurv'}
                    minThetaChangeSpeed = args{2} / 360 * pi * 2;
                    args = args(2:end);
                    
                case 'trimthreshold'
                    thetaTrimThreshold = args{2} / 360 * pi * 2;
                    args = args(2:end);
                    
                case 'smooth'
                    smoothFactor = args{2};
                    args = args(2:end);
                    
                case 'trialnum'
                    dbgSingleTrialNumber = args{2};
                    args = args(2:end);
                    
                case 'outattrprefix'
                    outAttrPrefix = args{2};
                    args = args(2:end);
                    
                otherwise
                    error('Unsupported argument "%s"', args{1});
            end
            
            args = stripArgs(args(2:end));
        end
        
        outAttrNames = struct;
        outAttrNames.StartRows = strcat(outAttrPrefix, 'StartRows');
        outAttrNames.EndRows = strcat(outAttrPrefix, 'EndRows');
        outAttrNames.Direction = strcat(outAttrPrefix, 'Direction');
        outAttrNames.Size = strcat(outAttrPrefix, 'Size');
        
    end
    
end

