function trials = loadOneSessionTrialData(sessionInf, expData, trajT0Type, customColNames)
% trials = loadOneSessionTrialData(sessionInf, expData, trajT0Type, customColNames) -
% Load the trials from file.

    minMovementTime = 0.2;
    customColNames = arrayfun(@(c){tt.preprocess.normalizeTrialsFileColumnName(c{1})}, customColNames);
    
    fprintf('   Loading trials...\n');
    filPath = sprintf('%s/%s', sessionInf.RawDir, sessionInf.Files.trials);
    
    mtGetter = getMovementTimeGetter(sessionInf.Software, trajT0Type);

    [mandatoryCols, defaultCols] = tt.preprocess.trialFileMandatoryColumns(sessionInf.Platform);
    [allTrialInfo, extraColNames] = tt.preprocess.readTrialDataFile(filPath, 'MandatoryCols', mandatoryCols, 'OutFormat', 'struct');

    missingCustomCols = customColNames(arrayfun(@(c)~ismember(lower(c{1}), lower(extraColNames)), customColNames));
    if ~isempty(missingCustomCols)
        error('Custom column/s "%s" are missing from %s', join(',', missingCustomCols), filPath);
    end

    % Some custom columns are loaded anyway, even if they were not requested
    for defaultCustomCol = defaultCols
        c = lower(defaultCustomCol{1});
        if isempty(customColNames) || (~ismember(c, lower(customColNames)) && ismember(c, lower(extraColNames)))
            customColNames = [customColNames defaultCustomCol]; %#ok<AGROW>
        end
    end
    nl_changes_position = ismember('nl_position_x', lower(customColNames));

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
        errCode = tt.preprocess.statusToErrCode(trialInfo.status);

        switch(sessionInf.Platform)
            case 'NL'
                td = NLOneTrialData(trialInfo.trialnum, target);
                td.EndPoint = trialInfo.endpoint;
                if isnan(td.EndPoint) && errCode == TrialErrCodes.OK
                    error('Missing endpoint data in line %d', rowNum)
                end
                td.PrevEndPoint = prevEndPoint;
                prevEndPoint = td.EndPoint;

            case 'DC'
                td = DCOneTrialData(trialInfo.trialnum, target);
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
        td.ErrCode = errCode;
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
        
        %-- If the number line changes its position on every trial: calc
        %-- this position in the logical coordinate space
        if nl_changes_position
            td.Custom.nl_position_x_pixels = td.Custom.nl_position_x;
            td.Custom.nl_position_x = td.Custom.nl_position_x / expData.PixelsPerUnit;
        end

        trials = [trials td]; %#ok<AGROW>

        prevTarget = td.Target;
        
    end

    %---------------------------------------------------------------
    % Decide how to calculate the movement time
    %
    function func = getMovementTimeGetter(software, trajT0Type)
        if strcmpi(software, 'trajtracker')
            % In TrajTracker, movement time is saved correctly
            func = @(t)t.movementtime;
            return;
        end
        
        %-- For older versions (pre-TrajTracker):
        switch(lower(trajT0Type))
            case '0'
                % Old software versions exported movement time correctly too
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
