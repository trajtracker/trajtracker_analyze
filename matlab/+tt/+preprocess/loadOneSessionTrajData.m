function loadOneSessionTrajData(sessionInf, expData, trials, trajT0Type, splineXParam, samplingRate, createTrajMatrixArgs, minMovementTime)
%loadOneSessionTrajData(sessionInf, expData, trials, trajT0Type, splineXParam, samplingRate, createTrajMatrixArgs, minMovementTime)
% Load the trajectory data onto experiment with already-loaded trials

    if ~strcmpi(trajT0Type, 'FingerMoved')
        validateThatFingerMovesBeforeTarget(trials, trajT0Type);
    end
    
    fprintf('   Loading trajectories...\n');

    trialOK = arrayfun(@(t)t.ErrCode == TrialErrCodes.OK, trials);
    trialNums = arrayfun(@(t)t.TrialNum, trials);
    if length(trialNums) ~= length(unique(trialNums))
        un = unique(trialNums);
        nPerNum = arrayfun(@(n)sum(trialNums==n), un);
        dup = sprintf(',%d', un(nPerNum>1));
        dup = dup(2:end);
        error('There are duplicate trial numbers for subject %s: %s', sessionInf.SubjInitials, dup);
    end

    trialT0Getter = getT0Getter(trajT0Type);

    rawTrajData = loadTrajData(sessionInf);

    %-- Loop through trials, one at a time
    nRows = size(rawTrajData, 1);
    currRow = 1;
    lastTrialNum = -1;
    while (currRow < nRows && currRow > 0)

        trialNum = rawTrajData(currRow, 1);
        [x, y, rawTimes, currRow] = getNextTrialTrajectory(rawTrajData, currRow);
        if trialNum < lastTrialNum
            error('Invalid order of trials in trajectory file %s (trial #%d appears before #%d - see line #%d)', sessionInf.Files.trajectory, lastTrialNum, trialNum, currRow);
        end
        lastTrialNum = trialNum;
        trial = trials(trialNums==trialNum & trialOK);
        if isempty(trial)
            %-- This was a trajectory of a failed trial. Ignore it.
            continue;
        end

        t0 = trialT0Getter(trial);

        rawTimes = rawTimes - t0;
        rawTimes(rawTimes<0 & rawTimes>-0.00001) = 0; % Fix minor calculation errors

        if rawTimes(end) < minMovementTime
            %-- Trial too short: ignore it.
            trial.ErrCode = TrialErrCodes.TooFast;
            continue;
        end

        if rawTimes(1) > .1
            error('The trajectory of trial #%d doens''t start with time=0! Perhaps you should use the "StimulusThenMove" flag?', trialNum);
        end
        if sum(rawTimes(y >= 0) < 0) > 0
            error('Some trajectory times in trial #%d ended up being negative! Perhaps you wrongly specified the "StimulusThenMove" flag?', trialNum);
        end

        movementTime = iif(sessionInf.is_trajtracker(), trial.MovementTime, max(rawTimes));
        trial.Trajectory = createTrajMatrix(rawTimes, x, y, expData, sessionInf, createTrajMatrixArgs, trialNum, movementTime);
        trial.TrajectoryLength = tt.preprocess.getTrajectoryLength(x, y);
    end
    
                                 
    %---------------------------------------------------------------
    % If finger moves before target number - issue an error
    % (this function is called only when finger is expected to move after the target)
    function validateThatFingerMovesBeforeTarget(trials, trajT0Type)
        
        if strcmp(trajT0Type, '0')
            % Nothing to validate
            return;
        end
        
        % Count the number of trials in which finger moved after the target.
        % one frame is ~17 ms, and we allow few more ms for processing on slow machines (ipad-2)
        ONE_FRAME_DURATION = .025;
        fingerMovedAfterTarget = arrayfun(@(trial)trial.TimeUntilFingerMoved > trial.TimeUntilTargetShown + ONE_FRAME_DURATION, trials);

        % We also agree to ignore up to 5 "problematic" trials
        if sum(fingerMovedAfterTarget) > 5
            sss = join(',', arrayfun(@(t){sprintf('%d', t.Target)}, trials(fingerMovedAfterTarget)));
            error('It seems that the finger started moving only after the target was shown.\nTrials=%s\nPerhaps you should use the "StimulusThenMove" flag?', sss);
        end
        
    end

    %---------------------------------------------------------------
    % Return a function that extracts a trial's t0
    function func = getT0Getter(trajT0Type)
        switch(lower(trajT0Type))
            case '0'
                func = @(t)0;

            case 'targetshown'
                func = @(t)t.TimeUntilTargetShown;

            case 'fingermoved'
                func = @(t)t.TimeUntilFingerMoved;

            otherwise
                error('Invalid t0 argument!');
        end
    end

    %------------------------------------------------
    function trajData = loadTrajData(sessionInf)
        
        filePath = sprintf('%s/%s', sessionInf.RawDir, sessionInf.Files.trajectory);
        trajData = csvread(filePath, 1, 0);

        if size(trajData, 2) ~= 4
            error('Invalid input file format for trajectory file %s: expecting 4 columns', filePath);
        end
        
    end

    %------------------------------------------------------------
    function [x, y, t, nextTrialStartRow] = getNextTrialTrajectory(trajData, startRow)

        nnRows = size(trajData, 1);
        if (startRow > nnRows || startRow <= 0)
            error('Invalid startRow (%d), there are %d rows!', startRow, nnRows);
        end

        trialNumChangeInd = find(diff(trajData(startRow:nnRows, 1)), 1);
        if isempty(trialNumChangeInd)
            %-- This is the last trial - there's no trial after this one
            nextTrialStartRow = -1;
            endRow = nnRows;
        else
            nextTrialStartRow = startRow + trialNumChangeInd;
            endRow = nextTrialStartRow - 1;
        end
        
        t = trajData(startRow:endRow, 2);
        x = trajData(startRow:endRow, 3);
        y = trajData(startRow:endRow, 4);

    end

    %------------------------------------------------------------
    function trajMatrix = createTrajMatrix(rawTimes, rawX, rawY, expData, sessionInf, createTrajMatrixArgs, trialNum, movementTime)

        absTimes = (0:samplingRate:movementTime)';
        
        if (length(absTimes) < 10)
            if (length(absTimes) < 2)
                fprintf('    WARNING: Trial #%d has too few rows (%d) - trajectory ignored.\n', trialNum, length(absTimes));
                trajMatrix = [];
                return;
            else
                fprintf('    WARNING: Trial #%d has very few rows (%d)\n', trialNum, length(absTimes));
            end
        end

        % Remove samples where dt is too small. This should never
        % happen, probably happens due to a bug
        goodDT = [true; diff(rawTimes) >= .008];
        rawTimes = rawTimes(goodDT);
        rawX = rawX(goodDT);
        rawY = rawY(goodDT);

        %-- Change coordinate space from screen pixels to logical coordinates
        rawX = rawX ./ expData.PixelsPerUnit;
        if sessionInf.is_trajtracker() || sessionInf.BuildNumber >= 10
            rawY = (rawY + expData.YPixelsShift) ./ expData.PixelsPerUnit;
        end
        
        % Smooth the x values
        if ~isempty(splineXParam)
            if sum(diff(rawY) < 0) == 0
                rawX = csaps(rawY, rawX, splineXParam, rawY);
            else
                fprintf('   WARNING: trial %d has backward movement and cannot be smoothed\n', trialNum);
            end
        end

        % Interpolate X,Y coordinates to match the required time points
        interpolatedX = spline(rawTimes, rawX, absTimes);
        interpolatedY = spline(rawTimes, rawY, absTimes);

        switch(sessionInf.Platform)
            case 'NL'
                trajMatrix = tt.preprocess.createTrajectoryMatrixNL(absTimes, interpolatedX, interpolatedY, expData, createTrajMatrixArgs);

            case 'DC'
                trajMatrix = tt.preprocess.createTrajectoryMatrixDC(absTimes, interpolatedX, interpolatedY, expData, createTrajMatrixArgs);

            otherwise
                error('Unsupported ExperimentPlatform (%s)', self.ExperimentPlatform);
        end

    end

end

