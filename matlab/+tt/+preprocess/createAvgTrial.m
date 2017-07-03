function avgTrial = createAvgTrial(expData, trials, absOrNorm, aggregationFunc)
% avgTrial = createAvgTrial(expData, trials, absOrNorm, aggregationFunc) -
% Create a trial averaging trajectory of several trials.
% 
% absOrNorm: whether to average by absolute or normalized times
% aggFunc: 'mean' or 'median'

    subjectInitials = expData.SubjectInitials;
    
    if numel(trials) == 1
        avgTrial = trials(1);
        return;
    elseif numel(trials) == 0
        avgTrial = [];
        return;
    end
    
    switch(absOrNorm)
        case 'abs'
            avgTrial = createMedianTrialAbs(trials);
            
        case 'norm'
            avgTrial = createMedianTrialNorm(trials);
            
        otherwise
            error('Invalid "absOrNorm" argument. Specify "abs" or "norm".');
    end
    
    
    %----------------------------------------------------------
    % Create mean trials.
    % The trajectory averaging method is by absolute time.
    % (we're still creating both regular and normalized trajectory for each
    % mean trial)
    %
    function medianTrial = createMedianTrialAbs(trials)
        
        trials = trials(arrayfun(@(t)t.Target >= 0, trials)); % filter out invalid (dummy) trials
        if (isempty(trials))
            medianTrial = createNewTrial(-1,-1);
            return;
        end
        
        longestTrial = tt.util.getLongestTrial(trials);
        
        medianTrial = createNewTrial(trials(1).Target, trials(1).Target);
        if strcmp(expData.ExperimentPlatform, 'NL')
            medianTrial.EndPoint = mean(arrayfun(@(t)t.EndPoint, trials));
            medianTrial.PrevEndPoint = safemean(trials, 'PrevEndPoint');
        end
        medianTrial.ErrCode = TrialErrCodes.OK;
        medianTrial.OutlierDueToArea = 0;
        medianTrial.OutlierDueToDistance = 0;
        medianTrial.InitialDirectionTheta = 0;
        medianTrial.InitialDirectionX0 = 0;
        medianTrial.Subject = subjectInitials;
        medianTrial.PrevTarget = safemean(trials, 'PrevTarget');
        
        % Get the mean trajectory. The result is a matrix with 3 columns: AbsTime, X, Y
        meanTraj = tt.preprocess.averageTrajectoryByTime(trials, trials(1).SamplingRate, size(longestTrial.Trajectory, 1), [TrajCols.X, TrajCols.Y], aggregationFunc);
        
        medianTrial.MovementTime = meanTraj(end,1);
        
        medianTrial.Trajectory = createTrajectoryData(meanTraj(:,1), meanTraj(:,2), meanTraj(:,3));
        medianTrial.NormalizedTrajectory = createNormTrajectoryData(meanTraj(:,1), meanTraj(:,2), meanTraj(:,3));
        
    end
    
    %----------------------------------------------------------
    function m = safemean(trials, property)
        validTrials = trials(arrayfun(@(t)~isempty(t.(property)), trials));
        v = arrayfun(@(t)t.(property), validTrials);
        v = v(~isnan(v));
        if isempty(v)
            m = [];
        else
            m = mean(v);
        end
    end

    %----------------------------------------------------------
    % Create mean trials.
    % The trajectory averaging method is by normalized time.
    % (we're still creating both regular and normalized trajectory for each
    % mean trial)
    %
    function medianTrial = createMedianTrialNorm(trials)
        
        trials = trials(arrayfun(@(t)t.Target >= 0, trials)); % filter out invalid (dummy) trials
        if (isempty(trials))
            medianTrial = createNewTrial(-1,-1);
            return;
        end
        
        medianTrial = createNewTrial(trials(1).Target, trials(1).Target);
        if strcmp(expData.ExperimentPlatform, 'NL')
            medianTrial.EndPoint = mean(arrayfun(@(t)t.EndPoint, trials));  %TODO-DC
            medianTrial.PrevEndPoint = safemean(trials, 'PrevEndPoint');
        end
        medianTrial.ErrCode = TrialErrCodes.OK;
        medianTrial.OutlierDueToArea = 0;
        medianTrial.OutlierDueToDistance = 0;
        medianTrial.InitialDirectionTheta = 0;
        medianTrial.InitialDirectionX0 = 0;
        medianTrial.TrialIndex = trials(1).Target + 1;
        medianTrial.Subject = subjectInitials;
        
        % Get the mean trajectory. The result is a matrix with 4 columns:
        % AbsTime, X, Y, and an ignored column
        meanTraj = tt.preprocess.averageTrajectoryByNormTime(trials, 101, aggregationFunc);
        
        medianTrial.MovementTime = meanTraj(end,1);
        
        medianTrial.Trajectory = createTrajectoryData(meanTraj(:,1), meanTraj(:,2), meanTraj(:,3));
        medianTrial.NormalizedTrajectory = createNormTrajectoryData(meanTraj(:,1), meanTraj(:,2), meanTraj(:,3));
        
    end
    

    %-----------------------------------------------------
    % Calculate the trajectory matrix for a single trial.
    % trialNum: a scalar
    % The x,y vectors should be according to the FixedSamplingRate
    % Return: trajectory data with self's fixed sampling rate
    function trajData = createTrajectoryData(absTimes, x, y)
        switch(expData.ExperimentPlatform)
            case 'NL'
                trajData = tt.preprocess.createTrajectoryMatrixNL(absTimes, x, y, expData.MaxTarget);
            case 'DC'
                trajData = tt.preprocess.createTrajectoryMatrixDC(absTimes, x, y, expData);
            otherwise
                error('Unsupported platform "%s"', expData.ExperimentPlatform);
        end
    end

    %-----------------------------------------------------
    % Calculate the normalized trajectory matrix for a single trial.
    % trialNum: a scalar
    % The x,y vectors should be normalized trajectories (i.e. with 201 samples)
    % Return: normalized trajectory data - i.e. with a fixed sampling rate and the given
    % number of samples
    function trajData = createNormTrajectoryData(absTimes, x, y)

        movementTime = absTimes(end);
        origtimePercentages = absTimes / movementTime;

        if sum(isnan(x)) > 0
        fprintf('# NAN: %d,%d\n', sum(isnan(origtimePercentages)), sum(isnan(x)));
        end
        
        timePercentages = ( 0:0.005:1 )';
        absTimes = spline(origtimePercentages, absTimes, timePercentages);
        x = spline(origtimePercentages, x, timePercentages);
        y = spline(origtimePercentages, y, timePercentages);
        
        switch(expData.ExperimentPlatform)
            case 'NL'
                trajData = tt.preprocess.createTrajectoryMatrixNL(absTimes, x, y, expData.MaxTarget);
            case 'DC'
                trajData = tt.preprocess.createTrajectoryMatrixDC(absTimes, x, y, expData);
            otherwise
                error('Unsupported platform "%s"', expData.ExperimentPlatform);
        end
    end
    
    %-------------------------------------------------------
    function trial = createNewTrial(trialNum, target)
        switch(expData.ExperimentPlatform)
            case 'NL'
                trial = NLOneTrialData(trialNum, target);
            case 'DC'
                trial = DCOneTrialData(trialNum, target);
        end
    end

end
