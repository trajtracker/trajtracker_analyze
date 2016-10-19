function trials = loadOneSessionTrialData(sessionInf, trajT0Type, customColNames)
% trials = loadOneSessionTrialData(sessionInf, trajT0Type, customColNames) -
% Load the trials from file.

    fprintf('   Loading trials...\n');
    filPath = sprintf('%s/%s', sessionInf.RawDir, sessionInf.Files.trials);
    
    mtGetter = getMovementTimeGetter(trajT0Type);

    mandatoryCols = tt.preprocess.trialFileMandatoryColumns(sessionInf.Platform);
    [allTrialInfo, extraColNames] = tt.preprocess.readTrialDataFile(filPath, 'MandatoryCols', mandatoryCols, 'OutFormat', 'struct');

    missingCustomCols = customColNames(arrayfun(@(c)~ismember(lower(c{1}), lower(extraColNames)), customColNames));
    if ~isempty(missingCustomCols)
        error('Custom column/s "%s" are missing from %s', join(',', missingCustomCols), filPath);
    end

    % Some custom columns are loaded anyway, even if they were not requested
    for defaultCustomCol = {'PresentedTarget', 'Tag'}
        c = lower(defaultCustomCol{1});
        if ~ismember(c, lower(customColNames)) && ismember(c, lower(extraColNames))
            customColNames = [customColNames defaultCustomCol]; %#ok<AGROW>
        end
    end

    colsThatShouldBeIgnored = [{'subject', 'session'} lower(customColNames)];
    ignoredExtraCols = extraColNames(arrayfun(@(c)~ismember(lower(c{1}), colsThatShouldBeIgnored), extraColNames));
    if ~isempty(ignoredExtraCols)
        fprintf('      WARNING: some columns in the trials file will be ignored: %s\n', join(', ', ignoredExtraCols));
    end

    trials = [];
    
    prevTarget = NaN;
    prevResponse = NaN;
    prevEndPoint = NaN;

    for rowNum = 1 : length(allTrialInfo)

        trialInfo = allTrialInfo(rowNum);

        target = trialInfo.target;

        switch(sessionInf.Platform)
            case 'NL'
                td = NLOneTrialData(trialInfo.trialnum, target);
                td.EndPoint = trialInfo.endpoint;
                td.PrevEndPoint = prevEndPoint;
                prevEndPoint = td.EndPoint;

            case 'DC'
                td = GDOneTrialData(trialInfo.trialnum, target);
                td.UserResponse = trialInfo.userresponse;
                td.PrevResponse = prevResponse;
                prevResponse = td.UserResponse;
                if isfield(trialInfo, 'requiredresponse')
                    td.RequiredResponse = trialInfo.requiredresponse;
                end

            otherwise
                error('Unsupported platform %s', sessionInf.Platform);
        end

        td.TrialIndex = rowNum;

        td.MovementTime = mtGetter(trialInfo);
        td.TrajectoryLength = trialInfo.trajectorylength;
        td.ErrCode = getErrCode(trialInfo.status, td.MovementTime);
        if isfield(trialInfo, 'filler') && trialInfo.filler
            td.ErrCode = TrialErrCodes.Filler;
        end

        td.PrevTarget = prevTarget;
        td.SubSession = trialInfo.subsession;
        td.TimeInSubSession = trialInfo.timeinsession;
        td.TimeUntilTargetShown = trialInfo.timeuntiltarget;
        td.TimeUntilFingerMoved = trialInfo.timeuntilfingermoved;

        for i = 1:length(customColNames)
            td.Custom.(customColNames{i}) = trialInfo.(lower(customColNames{i}));
        end

        trials = [trials td]; %#ok<AGROW>

        prevTarget = td.Target;
        
    end

    %---------------------------------------------------------------
    function func = getMovementTimeGetter(trajT0Type)
        switch(lower(trajT0Type))
            case '0'
                func = @(t)t.movementtime;

            case 'targetshown'
                func = @(t)t.movementtime - t.timeuntiltarget;

            case 'fingermoved'
                func = @(t)t.movementtime - t.timeuntilfingermoved;

            otherwise
                error('Invalid t0 argument!');
        end
    end

    %---------------------------------------------------------------
    function ec = getErrCode(errCodeStr, movementTime)
        switch(errCodeStr)
            case 'OK'
                if (movementTime >= 0.2)
                    ec = TrialErrCodes.OK;
                else
                    ec = TrialErrCodes.TrialTooShort;
                end
            case 'ERR_MultiFingers'
                ec = TrialErrCodes.MultiFingers;
            case 'ERR_FingerLifted'
                ec = TrialErrCodes.FingerLifted;
            case 'ERR_StartedSideways'
                ec = TrialErrCodes.StartedSideways;
            case 'ERR_SpeechNotDetected'
                ec = TrialErrCodes.SpeechTooLate; % Changing to speech-too-late, which is usually the case. If indeed there was no speech, the error code will be later fixed manually
            case 'ERR_SpeechTooEarly'
                ec = TrialErrCodes.SpeechTooEarly;
            case 'ERR_MovedBackwards'
                ec = TrialErrCodes.MovedBackwards;
            case {'ERR_TooSlowGlobal', 'ERR_TooSlow'}
                ec = TrialErrCodes.TooSlowGlobal;
            case 'ERR_TooSlowInstantaneous'
                ec = TrialErrCodes.TooSlowInstantaneous;
            case 'ERR_MovedTooEarly'
                ec = TrialErrCodes.FingerMovedTooEarly;
            case 'ERR_MovedTooLate'
                ec = TrialErrCodes.FingerMovedTooLate;
            case {'ERR_TooFastMT', 'ERR_TooFastGlobal'}
                ec = TrialErrCodes.TooFast;
            case {'ERR_TrialTooShort', 'ERR_TooSlowMT'}
                ec = TrialErrCodes.TrialTooShort;
            case 'ERR_NoResponse'
                ec = TrialErrCodes.NoResponse;
            otherwise
                error('Unknown error code "%s"', errCodeStr);
        end
    end
    
end
