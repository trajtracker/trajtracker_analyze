function expData = loadSessionAsExpData(sessionInfos, varargin)
%expData = loadSessionAsExpData(sessionInfos, ...) - Preprocess session(s) of
%one subject, and load them as an ExperimentData object
% 
% sessionInfos: array of SessionInf objects, or cell array of file paths
% 
%   Optional arguements:
% ========================
% 
% -- Creating average trials --
% 
% NoAvg: don't create average trials
% AvgBy <func>: Use this function to group trials for averaging. See
%               details in <a href="matlab:help tt.preprocess.createAverageTrials">createAverageTrials</a>
% 
% 
% -- Smoothing trajectories --
% 
% By default, the x,y coordinates are smoothed (and saved this way in the
% trajectory matrix).
% The velocity is smoothed before calculating acceleration (but on the
% trajectory matrix, the unsmoothed velocity data is saved).
% 
% SplineX <P>: Before splining trajectories to a fixed sampling rate,
%              apply additional smoothing to x coords using cubic spline 
%              based on y coords. "p" is a paramameter for <a href="matlab:help csaps">csaps</a>
% SmoothCoords <sigma>: standard deviation (in seconds) for smoothing x,y
%              coordinates. Default: 20 ms
% VelocitySmoothingSD <sigma>: standard deviation (in seconds) for smoothing 
%              the x,y velocities before deriving into acceleration.
%              Default: 20 ms
% ExtrapolatedSmoothing: By default, smoothing at the the ends of
%              trajectory uses only available information, which means that
%              the smoothed values may be biased towards the trajectory
%              center (because out-of-traj information is N/A). This flag
%              indicates that just for the purpose of smoothingm, the trajectory
%              will be artificially extrapolated with its endpoint
%              coordinates, and smoothing will use that information.
% iEPYCoord: For discrete-choice experiments (platform=DC), this determines the
%            reference y coordinate to use when calculating implied endpoints.
%            Default: use expData.Custom.iEPYCoord, and if N/A, use top of
%            screen.
% OldTheta: Use the old method for calculating theta and implied endpoints.
%           The x,y coordinates will not be smoothed.
% 
% 
% -- General --
% 
% ExcludeEPOutliers (relevant only for number-line experiments): find
%               endpoint outliers and mark them as error trials.
% CustomCols <cell array>: load these custom column names from the trials
%               file. Columns will be loaded into "trial.Custom". Some
%               columns (e.g., PresentedTarget) are loaded by default.
% ProcessEDFunc <function>: A function @(expData) to run after the
%               experiment object was loaded, but before calculating error
%               trials, outliers etc.
% STM or StimulusThenMove: The experiment used a stimulus-then-move
%               paradigm. This affects the trial's zero time point.
% SumCustomAttrs <cell-array>: Experiment-level numeric custom attributes are
%               from the XML file (<session><expLevelCounters><counter>)
%               into expData.Custom.
%               If an experiment is loaded from several sessions, the
%               custom attributes will be taken are taken from the first
%               (earliest) session file, except some attributes that are
%               summed over all files. Here you can specify names of
%               additional attributes to sum.
% 

    sessionInfos = normalizeInput(sessionInfos);
    
    [platform, trialGroupingFunc, trajT0Type, excludeEPOutliers, customColNames, customExpDataProcessFunc, ...
    splineXParam, createTrajMatrixArgs, sumExpCustomAttrs, samplingRate, minMovementTime, message1Suffix] = parseArgs(varargin, sessionInfos(1).Platform);
        
    fprintf('\nLoading data of %s%s...\n', upper(sessionInfos(1).SubjInitials), message1Suffix);
    validateSessions(sessionInfos);
    
    expData = createExpData(sessionInfos(1));
    
    %-- Load data
    loadTrialsAndTrajectories(sessionInfos, expData);
    loadGeneralAttrs(expData, sessionInfos, createTrajMatrixArgs, sumExpCustomAttrs);
    
    runCustomPreProcess(expData, customExpDataProcessFunc);
    identifyDeviatingTrials(expData, excludeEPOutliers);
    
    fprintf('   Calculating some more trial parameters...\n');
    tt.preprocess.markBackMovementError(expData);
    tt.preprocess.calcInitialDir(expData, 'trials');
    
    createAverageTrials(expData, trialGroupingFunc);
    
    %-------------------------------------------------------------------
    function sessionInfs = normalizeInput(sessionInfs)
        
        %-- If a cell array of file names: load them
        if iscell(sessionInfs)
            sessionInfs = myarrayfun(@(s)tt.preprocess.loadSessionFile(s{1}), sessionInfs);
        elseif ischar(sessionInfs)
            sessionInfs = tt.preprocess.loadSessionFile(sessionInfs);
        end
        
        %-- Sort subsessions by date
        runDates = myarrayfun(@(s)s.StartTime, sessionInfs);
        [~,i] = sort(runDates);
        sessionInfs = sessionInfs(i);
        
    end

    %-------------------------------------------------------------------
    function validateSessions(sessionInfos)
        
        filenames = join(', ', arrayfun(@(s){s.Filename}, sessionInfos));
        
        subjIDs = unique(arrayfun(@(s){s.SubjID}, sessionInfos));
        if length(subjIDs) > 1
            error('Sessions of different subjects (%s) cannot be loaded together. Files: %s', join(',', subjIDs), filenames);
        end
        
        subjNames = unique(arrayfun(@(s){s.SubjName}, sessionInfos));
        if length(subjNames) > 1
            error('Sessions of different subjects (%s) cannot be loaded together. Perhaps two subjects have the same initials? Files: %s', join(',', subjNames), filenames);
        end

        if strcmp(platform, 'NL')
            maxTargets = unique(arrayfun(@(s)s.MaxTarget, sessionInfos));
            if length(maxTargets) > 1
                error('Sessions with different number line legnths cannot be loaded together. Files: %s', filenames);
            end
        end
        
    end

    %-------------------------------------------------------------------
    function dur = getTotalSessionDuration(session)
        if ~isfield(session.xmlData.session, 'sub_dash_sessions')
            dur = 0;
            return;
        end
        
        subSessions = session.xmlData.session.sub_dash_sessions.sub_dash_session;
        if iscell(subSessions)
            dur = sum(arrayfun(@(ssn)str2double(ssn{1}.duration.Attributes.seconds), subSessions));
        else
            dur = str2double(subSessions.duration.Attributes.seconds);
        end
    end

    %-------------------------------------------------------------------
    function expData = createExpData(sessionInf)
        switch(upper(platform))
            case 'NL'
                expData = NLExperimentData(sessionInf.MaxTarget, sessionInf.SubjInitials, sessionInf.SubjName);
            case 'DC'
                expData = DCExperimentData(sessionInf.SubjInitials, sessionInf.SubjName);
            otherwise
                error('Unsupported platform "%s" (file=%s)', platform, sessionInf.Filename);
        end
        
    end
    
    %-------------------------------------------------------------------
    function loadTrialsAndTrajectories(sessionInfos, expData)
        
        %-- Load trials
        trialsPerSession = cell(1, length(sessionInfos));
        for iSession = 1:length(sessionInfos)
            session = sessionInfos(iSession);
            t0t = iif(~session.is_trajtracker() && session.BuildNumber <= 45, '0', trajT0Type); % Until build 45, the software exported trajectories with 0-based timeline
            
            trials = tt.preprocess.loadOneSessionTrialData(session, t0t, customColNames);
            trialsPerSession{iSession} = trials;
            
            tt.preprocess.loadOneSessionTrajData(session, expData, trials, t0t, splineXParam, samplingRate, createTrajMatrixArgs, minMovementTime);
        end

        %-- Fix trial numbers (which are duplicate in multiple sessions)
        fixTrialNums(trialsPerSession);
        
        %-- Add trials to ExpData, and fix numbers
        for iSession = 1:length(trialsPerSession)
            expData.addTrialData(trialsPerSession{iSession});
        end
        
        %-- Set unique index per trial
        for ii = 1:length(expData.Trials)
            expData.Trials(ii).TrialIndex = ii;
        end
        
    end
    
    %-------------------------------------------------------------------
    % If an experiment consists of several sessions, trial numbers should
    % be fixed from session#2 (to prevent duplicates)
    function fixTrialNums(trialsPerSession)
        
        maxTrialsPerSession = max(arrayfun(@(s)length(s{1}), trialsPerSession));
        d = 10 ^ ceil(log(maxTrialsPerSession) / log(10));
        for i = 2:length(trialsPerSession)
            for t = trialsPerSession{i}
                t.TrialNum = t.TrialNum + d*(i-1);
            end
        end
        
    end

    %-------------------------------------------------------------------
    function loadGeneralAttrs(expData, sessionInfos, trajMatrixArgs, sumExpCustomAttrs)
        
        expData.TotalDuration = sum(arrayfun(@(s)getTotalSessionDuration(s), sessionInfos));
        
        sessionInf = sessionInfos(1);
        expData.BuildNumber = sessionInf.BuildNumber;
        expData.RunDate = sessionInf.StartTime;
        
        expData.Custom = sessionInfos(1).CustomAttrs;
        calcSummableCustomAttrs(expData, sessionInfos, sumExpCustomAttrs);
        
        expData.Custom.CoordSmoothingSD = trajMatrixArgs.coordSmoothingSd;
        expData.Custom.VelocitySmoothingSD = trajMatrixArgs.velocitySmoothingSd;
        if isfield(trajMatrixArgs, 'iEPYCoord')
            expData.Custom.iEPYCoord = trajMatrixArgs.iEPYCoord;
        end
        
    end

    %-------------------------------------------------------------------
    function calcSummableCustomAttrs(expData, sessionInfos, sumExpCustomAttrs)
                
        for i = 1:length(sumExpCustomAttrs)
            attr = sumExpCustomAttrs{i};
            infosWithAttr = sessionInfos(arrayfun(@(s)isfield(s.CustomAttrs, attr), sessionInfos));
            expData.Custom.(attr) = sum(arrayfun(@(s)s.CustomAttrs.(attr), infosWithAttr));
        end
                
    end

    %-------------------------------------------------------------------
    function runCustomPreProcess(expData, customExpDataProcessFunc)
        
        if isempty(customExpDataProcessFunc)
            return;
        end
        
        fprintf('   Running custom operations...\n');
        customExpDataProcessFunc(expData);
        
    end

    %-------------------------------------------------------------------
    function identifyDeviatingTrials(expData, excludeEndpointOutliers)
        
        fprintf('   Scanning for deviating/outlier trials...\n');
        
        switch(expData.ExperimentPlatform)
            case 'NL'
                %-- Endpoint outliers
                if excludeEndpointOutliers
                    nTrialOutliers = common.preprocess.updateOutlierEndpoints(ed);
                    if nTrialOutliers > 0
                        fprintf('       %d endpoint outlier trials were found (marked as error trials)\n', nTrialOutliers);
                    end
                end
                
                %-- Trajectory outliers
                nTrajOutliers = tt.preprocess.updateOutlierTrajectories(expData);
                if nTrajOutliers > 0
                    fprintf('       %d trajectory outlier trials were found\n', nTrajOutliers);
                end
                
            case 'DC'
                
                %-- No outliers: just mark deviations
                okTrials = expData.Trials(arrayfun(@(t)t.ErrCode == TrialErrCodes.OK, expData.Trials));
                tt.preprocess.updateDeviationFromDiagonal(okTrials, expData);
        end
        
    end

    %-------------------------------------------------------------------
    function createAverageTrials(expData, trialGroupingFunc)
        
        if isempty(trialGroupingFunc)
            return;
        end
        
        fprintf('   Creating average trials...\n');
        
        tt.preprocess.createAverageTrials(expData, 'GrpFunc', trialGroupingFunc);
        
    end

    %-------------------------------------------------------------------
    function [platform, trialGroupingFunc, trajT0Type, excludeEPOutliers, customColNames, customExpDataProcessFunc, ...
            splineXParam, trajMatrixArgs, sumExpCustomAttrs, samplingRate, minMovementTime, message1Suffix] = parseArgs(args, platform)
        
        trialGroupingFunc = iif(strcmp(platform, 'NL'), @(t)t.Target, []);
        trajT0Type = 'TargetShown';
        excludeEPOutliers = false;
        customColNames = {};
        customExpDataProcessFunc = [];
        splineXParam = [];
        trajMatrixArgs = struct;
		trajMatrixArgs.useOldThetaCalculationMethod = false;
		trajMatrixArgs.coordSmoothingSd = .02;
		trajMatrixArgs.velocitySmoothingSd = .02;
        samplingRate = 0.01;
        minMovementTime = 0.2;
        message1Suffix = '';
        
        sumExpCustomAttrs = {'nExpectedGoodTrials', 'nExpectedTrials', 'nTrialsCompleted', 'nTrialsFailed', 'nTrialsSucceeded'};
        
        args = stripArgs(args);
        
        while ~isempty(args)
            switch(lower(args{1}))
                case 'noavg'
                    trialGroupingFunc = [];
                    
                case 'avgby'
                    trialGroupingFunc = args{2};
                    args = args(2:end);
                    
                case 'oldtheta'
                    trajMatrixArgs.coordSmoothingSd = 0;
                    trajMatrixArgs.useOldThetaCalculationMethod = true;
                    
                case 'smoothcoords'
                    trajMatrixArgs.coordSmoothingSd = args{2};
                    args = args(2:end);
                    
                case 'extrapolatedsmoothing'
                    trajMatrixArgs.extrapolateForSmoothing = true;
                    
                case 'velocitysmoothingsd'
                    trajMatrixArgs.velocitySmoothingSd = args{2};
                    args = args(2:end);
                    
                case 'iepycoord'
                    trajMatrixArgs.iEPYCoord = args{2};
                    args = args(2:end);
                    
                case 'splinex'
                    splineXParam = args{2};
                    args = args(2:end);
                    
                case {'stm', 'stimulusthenmove'}
                    trajT0Type = 'FingerMoved';
                    
                case 'excludeepoutliers'
                    excludeEPOutliers = true;
                    
                case 'customcols'
                    customColNames = args{2};
                    args = args(2:end);
                    
                case 'processedfunc'
                    customExpDataProcessFunc = args{2};
                    args = args(2:end);
                    
                case 'sumexpcustomattrs'
                    sumExpCustomAttrs = [sumExpCustomAttrs args(2)]; %#ok<AGROW>
                    args = args(2:end);
                    
                case 'msgsuffix'
                    message1Suffix = args{2};
                    args = args(2:end);
                    
                case 'platform'
                    platform = args{2};
                    args = args(2:end);
                    
                otherwise
                    error('Unknown flag "%s"', args{1});
            end
            
            args = stripArgs(args(2:end));
        end
        
    end

end

