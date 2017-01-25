function findVelocityOnset(expData, varargin)
%findVelocityOnset(expData, ...) -
%  Check when a certain x velocity was crossed and return the row num.
%  The velocity we look for is a certain percentage of the maximal X
%  velocity. The function will return the last threshold-crossing index
%  that is BEFORE the maximal velocity.
%
%  The x coordinates are smoothed prior to calculating the velocity using
%  the convolution vector [1,1,1,1] (which can be overriden].
% 
% expData - ExperimentData or struct of ExperimentData's
%
% The format of "result" is similar to the input format. When there are
% multiple subjects, "mergedResult" merges them all together.
%
% Optional arguments:
% Axis <x|y>   - Check for X or Y velocities
% SmoothArgs <cell-array>: smoothing parameters for tt.vel.getTrialVelocity
% SmoothSD <stdev>: Gaussian smoothing parameter for tt.vel.getTrialVelocity
% SaveAttr <attr-name> - for each trial, save the onset time on this 
%                custom attribute
% ExpData <ed> - When providing the function with a list of trials, specify
%                an exp-data that will be used as reference for extracting
%                various information.
% PeakMinPcnt <0-100>: a peak velocity is significant if it exceeds this
%                percentile of the velocities in all trials up to time
%                point MinTime. Default: 1%
% MinPeak #    - A fixed minimal value for the peak velocity threshold (the
%                value calculated using "PeakMinPcnt"). Default: 0.2
% MinTime <seconds> : Change the MinTime for identifying significant peak
%                velocities (see PeakMinPcnt above). Also, onsets earlier
%                than this time are ignored.
% OnsetMinPcnt <0-100>: A velocity onset is the time point that exceeds this
%                percentage of the peak velocity.
% TrialNum <n> - process only these trial numbers

    [getVelocityFunc, resultAttrs, minTime, maxTime, onsetPcntOfPeak, peakVelocityPercentileThreshold, ...
        minPeakVelThreshold, trialNums, debugLevel] = parseArgs(varargin);
    
    if isa(expData, 'ExperimentData')
        
        processSubject(expData, trialNums);
        
    elseif isstruct(expData) && ~isempty(tt.inf.listInitials(expData))
        
        if ~isempty(trialNums)
            error('The "TrialNum" flag can only be used for a single subject');
        end
        
        ini = tt.inf.listInitials(expData);
        for ii = 1:length(ini)
            processSubject(expData.(ini{ii}), []);
        end
        
    end
    
    fprintf('\n');

    %-----------------------------------------
    function processSubject(expData, trialNums)
        
        if (debugLevel == 0)
            fprintf('.');
        end
        
        velocities = getTrialVelocities(expData);
        peakVelThreshold = getInitialVelocityPercentile(velocities, round(minTime / expData.SamplingRate), peakVelocityPercentileThreshold);
        
        peakVelThreshold = max(peakVelThreshold, minPeakVelThreshold);
        
        if (debugLevel)
            fprintf('Subject %s: threshold for peak velocity is %.4f (or faster)\n', expData.SubjectInitials, peakVelThreshold);
        end
        
        expData.Custom.PeakVelocityThreshold = peakVelThreshold;
        expData.Custom.VelocityOnsetPercentOfPeak = onsetPcntOfPeak;
        expData.Custom.VelocityOnsetMinTime = minTime;
        expData.Custom.VelocityOnsetMaxTime = maxTime;
        
        if isempty(trialNums)
            trials = expData.Trials;
        else
            fprintf('Working on trial numbers: %s\n', sprintf('%d,', trialNums));
            trials = expData.Trials(arrayfun(@(t)ismember(t.TrialNum, trialNums), expData.Trials));
        end

        for i = 1:length(trials)
            processOneTrial(trials(i), peakVelThreshold, minTime, maxTime);
        end
        
    end

    %-----------------------------------------
    function velocities = getTrialVelocities(expData)
        
        velocities = [];
        for i = 1:length(expData.Trials)
            v = getVelocityFunc(expData.Trials(i));
            velocities = [velocities v];
        end
        
    end
        
    %-----------------------------------------
    % Find the distribution of X velocities in the initial trajectory
    % parts, and get a certain percentile of that.
    function result = getInitialVelocityPercentile(velocities, maxRow, percentile)
        
        % Get distribution of velocities
        v = [];
%        v1 = [];
        for i = 1:length(velocities)
%            fprintf('i=%d s=%d\n', i, size(v1, 1));
            vv = velocities(i).velocity;
            lastInd = min(maxRow, size(vv, 1));
            v = [v; vv(1:lastInd)];
%            v1 = [v1 vv(1:lastInd)];
        end
        v = v(~isnan(v));
        
        result = prctile(abs(v), 100 - percentile);
        
    end
    
    %-----------------------------------------
    function processOneTrial(trial, peakVelocityThreshold, minTime, maxTime)
        
        velInf = getVelocityFunc(trial);
        
        minValidRow = find(velInf.times >= minTime, 1);
        if (maxTime <= 0)
            maxTime = velInf.times(end) + maxTime;
        elseif (maxTime <= minTime)
            error('"MaxTime" cannot be lower than "MinTime"!');
        end
        
        % Velocity in positive (rightward) /negative (leftward) direction
        velocityP = velInf.velocity(minValidRow:end);
        velocityN = -velInf.velocity(minValidRow:end);
        velocityT = velInf.times(minValidRow:end);
        
        peakRows = [];
        onsetInds = [];
        
        % Identify several velocity peaks
        while ~isempty(velocityP)
            
            [maxPosVel, maxPosInd] = max(velocityP);
            [maxNegVel, maxNegInd] = max(velocityN);
            if (maxPosVel < peakVelocityThreshold && maxNegVel < peakVelocityThreshold)
                % No peak for this trial
                break;
            end
            
            if (debugLevel > 1)
                fprintf('   Peak velocity: positive = %.4f (time=%.3f), negative = %.4f (time=%.3f)\n', maxPosVel, velocityT(maxPosInd), maxNegVel, velocityT(maxNegInd));
            end
            
            % Use the peak that occurs later in time, but ignore non-significant peaks
            if ((maxPosInd >= maxNegInd && maxPosVel >= peakVelocityThreshold) || maxNegVel < peakVelocityThreshold)
                currPeakInd = maxPosInd;
                currPeakVel = maxPosVel;
                currVel = velocityP(1:maxPosInd-1);
                peakDirection = 'positive';
            else
                currPeakInd = maxNegInd;
                currPeakVel = -maxNegVel;
                currVel = velocityN(1:maxNegInd-1);
                peakDirection = 'negative';
            end
            
            if (debugLevel > 1)
                fprintf('   Peak velocity (%s) = %.4f, time=%.2f, threshold for onset=%.4f\n', peakDirection, currPeakVel, velInf.times(currPeakInd+minValidRow-1), abs(currPeakVel) * onsetPcntOfPeak);
            end
            
            % Find the onset for this peak
            currOnsetInd = find(currVel <= abs(currPeakVel) * onsetPcntOfPeak, 1, 'last');
            if isempty(currOnsetInd)
                break;
            end
            
            if (velocityT(currOnsetInd) <= maxTime)
                % Valid onset time
                peakRows = [currPeakInd peakRows];
                onsetInds = [currOnsetInd onsetInds]; %#ok<*AGROW>
                if (debugLevel > 1)
                    fprintf('   Found velocity onset at time=%.2f\n', velInf.times(currOnsetInd+minValidRow-1));
                end
            end
            
            velocityP = velocityP(1:currOnsetInd-1);
            velocityN = velocityN(1:currOnsetInd-1);

        end
        
        if debugLevel > 1 && isempty(onsetInds)
            fprintf('   No onset was found\n');
        end
        
        if isempty(minValidRow)
            fprintf('Warning: trial #%d is shorter than %.2f seconds\n', trial.TrialNum, minTime);
            rowOffset = [];
            onsetInds = [];
            peakRows = [];
            minValidRow = 0;
        else
            rowOffset = find(trial.Trajectory(:, TrajCols.AbsTime) >= velInf.times(minValidRow), 1) - 1;
        end
        
        onsetIndsInVelInf = onsetInds + minValidRow - 1;
        peakRowsInVelInf  = peakRows  + minValidRow - 1;
        onsetIndsInTrial = onsetInds + rowOffset;
        peakRowsInTrial  = peakRows  + rowOffset;
        
        if ~isempty(resultAttrs)
            trial.Custom.(resultAttrs.AllRows) = onsetIndsInTrial;
            trial.Custom.(resultAttrs.AllTimes) = velInf.times(onsetIndsInVelInf);
            if isempty(onsetInds)
                trial.Custom.(resultAttrs.Row) = [];
                trial.Custom.(resultAttrs.Time) = [];
                trial.Custom.(resultAttrs.LastRow) = [];
                trial.Custom.(resultAttrs.LastTime) = [];
            else
                trial.Custom.(resultAttrs.Row) = onsetIndsInTrial(1);
                trial.Custom.(resultAttrs.Time) = velInf.times(onsetIndsInVelInf(1));
                trial.Custom.(resultAttrs.LastRow) = onsetIndsInTrial(end);
                trial.Custom.(resultAttrs.LastTime) = velInf.times(onsetIndsInVelInf(end));
            end
            trial.Custom.(resultAttrs.AllPeakRows) = peakRowsInTrial;
            trial.Custom.(resultAttrs.AllPeakTimes) = velInf.times(peakRowsInVelInf);
            trial.Custom.(resultAttrs.AllPeaks) = velInf.velocity(peakRowsInVelInf);
            trial.Custom.(resultAttrs.OnsetEncoder) = 'auto';
        end
        
%        fprintf('Trial %d: found %d peaks, %d onsets\n', trial.TrialIndex, length(peakRows), length(onsetInds));
        
    end

    %-----------------------------------------
    function velInf = getTrialXVelocity(trial)
        velInf = struct;
        velInf.times = trial.Trajectory(:, TrajCols.AbsTime);
        velInf.velocity = trial.Trajectory(:, TrajCols.XVelocity);
    end

    %-----------------------------------------
    function [getVelocityFunc, resultAttrs, minTime, maxTime, onsetPcntOfPeak, ...
            peakVelocityPercentileThreshold, minPeakVelThreshold, trialNums, debugLevel] = parseArgs(args)
        
        attrPrefix = 'XVelocity';
        axis = 'x';
        getVelocityArgs = {};
        minTime = 0.25;
        maxTime = -0.1;
        peakVelocityPercentileThreshold = 1;
        minPeakVelThreshold = 0.2;
        trialNums = [];
        debugLevel = 0;
        onsetPcntOfPeak = .05;
        recalcOnset = false;
        
        args = stripArgs(args);
        while ~isempty(args)
            switch(lower(args{1}))
                case 'smoothsd'
                    getVelocityArgs = {'CSmooth', 'Gauss', args{2}};
                    recalcOnset = true;
                    args = args(2:end);
                    
                case 'smoothargs'
                    getVelocityArgs = args{2};
                    recalcOnset = true;
                    args = args(2:end);
                    
                case 'axis'
                    axis = args{2};
                    args = args(2:end);
                    if ~strcmpi(axis, 'x') && ~strcmpi(axis, 'y')
                        recalcOnset = true;
                    end
                    
                case 'saveattr'
                    attrPrefix = args{2};
                    args = args(2:end);
                    
                case 'mintime'
                    minTime = args{2};
                    args = args(2:end);
                    
                case 'maxtime'
                    maxTime = args{2};
                    args = args(2:end);
                    
                case 'onsetminpcnt'
                    onsetPcntOfPeak = args{2} / 100;
                    args = args(2:end);
                    
                case 'peakminpcnt'
                    peakVelocityPercentileThreshold = args{2};
                    args = args(2:end);
                    if (peakVelocityPercentileThreshold <= 0 || peakVelocityPercentileThreshold >= 100)
                        error('Invalid "percentile" value');
                    elseif (peakVelocityPercentileThreshold > 60)
                        fprintf('WARNING: Note that small "Percentile" values indicate a stricter threshold!!\n');
                    elseif (peakVelocityPercentileThreshold < .5)
                        fprintf('WARNING: Note that the range for "Percentile" values is 0-100; you specified %.3f\n', peakVelocityPercentileThreshold);
                    end
                    
                case 'minpeak'
                    minPeakVelThreshold = args{2};
                    args = args(2:end);
                    
                case 'trialnum'
                    trialNums = args{2};
                    args = args(2:end);
                    
                case {'debug', 'v'}
                    debugLevel = args{2};
                    args = args(2:end);
                    
                otherwise
                    error('Invalid argument: %s', args{1});
            end
            args = stripArgs(args(2:end));
        end
        
        
        if recalcOnset
            getVelocityFunc = @(trial)tt.vel.getTrialVelocity(trial, 'Axis', axis, getVelocityArgs);
        else
            getVelocityFunc = @getTrialXVelocity;
        end
        
        resultAttrs = struct;
        resultAttrs.Time = strcat(attrPrefix, 'OnsetTime');
        resultAttrs.AllTimes = strcat(attrPrefix, 'OnsetTimes');
        resultAttrs.Row = strcat(attrPrefix, 'OnsetRow');
        resultAttrs.AllRows = strcat(attrPrefix, 'OnsetRows');
        resultAttrs.AllPeakRows = strcat(attrPrefix, 'PeakRows');
        resultAttrs.AllPeakTimes = strcat(attrPrefix, 'PeakTimes');
        resultAttrs.AllPeaks = strcat(attrPrefix, 'Peaks');
        resultAttrs.LastTime = strcat(attrPrefix, 'LastOnsetTime');
        resultAttrs.LastRow = strcat(attrPrefix, 'LastOnsetRow');
        resultAttrs.OnsetEncoder = strcat(attrPrefix, 'OnsetEncoder');
        
    end

end

