function trials = loadOneSessionTrialData(sessionInf, trajT0Type, customColNames)
% trials = loadOneSessionTrialData(sessionInf, trajT0Type, customColNames) -
% Load the trials from file.

    minMovementTime = 0.2;
    
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
        td.ErrCode = tt.preprocess.statusToErrCode(trialInfo.status);
        if ~isnan(minMovementTime) && td.ErrCode == TrialErrCodes.OK && td.MovementTime < minMovementTime
            td.ErrCode  = TrialErrCodes.TrialTooShort;
        end

        if isfield(trialInfo, 'filler') && trialInfo.filler
            td.ErrCode = TrialErrCodes.Filler;
        end

        td.PrevTarget = prevTarget;
        if isfield(trialInfo, 'subsession')
            td.SubSession = trialInfo.subsession;
        else
            td.SubSession = 1;
        end
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
    
end
