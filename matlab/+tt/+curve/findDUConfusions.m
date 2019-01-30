function result = findDUConfusions(allExpData, varargin)
%result = findDUConfusions(allExpData, ...) - find trials in which there
%seem to be a confusion, even if transient, between the decade and unit
%digits.
%
% allExpData: one dataset, or a cell array with datasets
% 
% Optional arguments:
% ===================
% Method <value>: indicates how we decide whether a trial includes a confusion:
%      StartOpposite (default): One of the first 2 curves starts by pointing to the
%                incorrect side.
%                Testing only trials in which the 2 digits are on different sides.
%      BadToGood: One of the first 2 curves starts by pointing to the
%                incorrect side, and ends towards the correct side.
%                Testing only trials in which the 2 digits are on different sides.
%      DUConfusin:  A trial is considered as "confusion" if the first curve is 
%                towards the incorrect side; OR if one of the first 2 curves starts towards the
%                incorrect side and ends towards the correct side.
%                Testing only trials in which the 2 digits are on different sides.
%      DUConfAt: At a given time point, the finger was pointing more towards the unit digit than towards
%                the decade digit. when specifying this, you must specify the time point in question
%                using the "ConfTime" parameter.
%      RandomConfusion: Same like "DUConfusion", but applied to trials where both digits are on the same side
%                (i.e, the pointing towards incorrect side actually goes against BOTH digits)
%      GoodToBad: One of the first two curves starts by pointing to the correct side and ends by pointing 
%                to the incorrect side.
%      DUConfReg: Examine the confusions based on tegressions. TBD.
%
% TrialFilter <func>: filter only certain trials
% MinTime <time>: Ignore curves / time points earlier than this
% Print: print statistics of confusions
% Description <cell-array>: description of each dataset
% Export <filename>: Export data to this file
% ExportCond <cols/rows>: Format of exporting
% Mark: if this flag is specified, trial.Custom.DUConfusion will be updated for each trial.
% 
% ConfTime: See above, Method='DUConfAt'
% 
% RR: See above, method='DUConfReg'
% RRKey: See above, method='DUConfReg'
% MinErrRatio: See above, method='DUConfReg'
% 
% Compare <m>: If 'allExpData' is a list of datasets, use this flag to compare
%        the confustion rate between datasets. <m> should be an N*2 matrix
%        containing conditions numbers (indices in 'allExpData'): each row
%        is a comparison to run, and it contains the numbers of the two
%        datasets to compare.

					
    [identifyPatternFunc, minTime, trialFilters, printResult, leftThreshold, rightThreshold, ...
        maxTarget, setNames, exportFN, exportCondsAsColumns, markConfusionsOnCustomAttr, compareConds] = parseArgs(varargin, allExpData);
    midTarget = maxTarget/2;
    
    if iscell(allExpData)
        result = myarrayfun(@(iCond)processOneCondition(allExpData{iCond}, setNames{iCond}, iCond), 1:length(allExpData));
    else
        result = processOneCondition(allExpData, setNames{1}, 1);
    end
    
    if ~isempty(compareConds)
        compareConfusionsInConds(result, compareConds);
    end
    
    if ~isempty(exportFN)
        doExport(result, exportFN, setNames, exportCondsAsColumns);
    end
    
    %----------------------------------------------
    function result = processOneCondition(allExpData, setName, iCond)
        
        subjIDs = tt.inf.listInitials(allExpData);

        result = struct;
        result.SubjIDs = subjIDs;
        result.CondName = allExpData.general.CondName;

        for iSubj = 1:length(subjIDs)

            sid = subjIDs{iSubj};

            expData = allExpData.(sid);

            trials = expData.Trials;
            if markConfusionsOnCustomAttr
                for i = 1:length(trials)
                    trials(i).Custom.DUConfusion = false;
                end
            end
            
            for iFilter = 1:length(trialFilters)
                trials = trials(arrayfun(trialFilters{iFilter}, trials));
            end

            nConfusions = 0;
            sumConfDegrees = 0;
            confTrialNums = [];
            
            for trial = trials
                
                [isConf, confusionDegree] = identifyPatternFunc(trial, expData, iCond);
                
                nConfusions = nConfusions + isConf;
                sumConfDegrees = sumConfDegrees + confusionDegree;
                if (isConf)
                    confTrialNums = [confTrialNums trial.TrialNum];
                end
                
                if markConfusionsOnCustomAttr
                    trial.Custom.DUConfusion = isConf;
                    trial.Custom.DUConfusionDegree = confusionDegree;
                end
            end

            result.confTrials{iSubj} = confTrialNums;
            result.nConfusions(iSubj) = nConfusions;
            result.nTrials(iSubj) = length(trials);
            result.confRate(iSubj) = nConfusions / length(trials);
            result.confDegree(iSubj) = sumConfDegrees / length(trials);

        end

        if printResult
            fprintf('Mean confusion rate for %s: %.2f%%   confusion degree:%.2f\n', setName, mean(result.confRate)*100, mean(result.confDegree));
        end
        
    end
    

    %----------------------------------------------------
    function compareConfusionsInConds(result, compareConds)
        
        % Compare each pair
        for iPair = 1:size(compareConds, 1)
            cond1 = result(compareConds(iPair, 1));
            cond2 = result(compareConds(iPair, 2));
            confPcnt1 = cond1.confRate;
            confPcnt2 = cond2.confRate;
            
            [~, p, ~, stat] = ttest(confPcnt1, confPcnt2);
            
            fprintf('%s (%.1f%%) vs %s (%.1f%%): t(%d) = %.2f, two-tailed p=%s\n', cond1.CondName, mean(confPcnt1) * 100, ...
                    cond2.CondName, mean(confPcnt2) * 100, stat.df, stat.tstat, format_pval(p));
        end
        
    end
    
    %========================================================================
    % Determine confusions according to left/right pointing: a confusion is
    % defined only for trials in which the decade and unit digits are on
    % two different sides of the screen, and the subject transiently points
    % to the wrong side
    %========================================================================
    
    %----------------------------------------------------
    % A trial is considered as "confusion" if any of the following is true:
    % - The first curve is towards the opposite side
    % - Either the first or the 2nd curve start towards the opposite side
    %   and end towards the correct side
    function [confusion, confDegree] = isConfusionTrialLR(trial, ~, ~)
        
        confDegree = 0;
        confusion = false;
        
        if isempty(trial.Custom.CurveStartRows)
            return;
        end
        
        startRows = trial.Custom.CurveStartRows;
        endRows = trial.Custom.CurveEndRows;
        
        % Check if first curve ends towards the wrong side
        if isPointingTo(trial.Target > midTarget, trial.Trajectory(endRows(1), TrajCols.ImpliedEP)) && ...
                trial.Trajectory(endRows(1), TrajCols.AbsTime) >= minTime
            confusion = true;
            confDegree = 1;
            return;
        end
        
        % Check if any curve (except the first) is a correction from the wrong side to the correct side
        for iCurve = 1:min(2, length(startRows))
            if isPointingTo(trial.Target > midTarget, trial.Trajectory(startRows(iCurve), TrajCols.ImpliedEP)) && ...
                    isPointingTo(trial.Target < midTarget, trial.Trajectory(endRows(iCurve), TrajCols.ImpliedEP)) && ...
                    trial.Trajectory(startRows(iCurve), TrajCols.AbsTime) >= minTime
                confusion = true;
                confDegree = 1;
                return;
            end
        end
        
    end
    
    %----------------------------------------------------
    % A trial is considered as "confusion" if one of the first two curves
    % starts by pointing to the incorrect side
    function [confusion, confDegree] = startingToIncorrectSide(trial, ~, ~)
        
        confDegree = 0;
        confusion = false;
        
        if isempty(trial.Custom.CurveStartRows)
            return;
        end
        
        startRows = trial.Custom.CurveStartRows;
        endRows = trial.Custom.CurveEndRows;
        
        % Check if one of the first two curves starts towards the incorrect side
        for iCurve = 1:min(2, length(startRows))
            if isPointingTo(trial.Target > midTarget, trial.Trajectory(endRows(iCurve), TrajCols.ImpliedEP)) && ...
                    trial.Trajectory(endRows(1), TrajCols.AbsTime) >= minTime
                confusion = true;
                confDegree = 1;
                return;
            end
        end
        
    end
    
    %----------------------------------------------------
    % A trial is considered as "confusion" if one of the first two curves
    % starts by pointing to the incorrect side and ends by pointing to the
    % correct side
    function [confusion, confDegree] = isBadToGood(trial, ~, ~)
        
        confDegree = 0;
        confusion = false;
        
        if isempty(trial.Custom.CurveStartRows)
            return;
        end
        
        startRows = trial.Custom.CurveStartRows;
        endRows = trial.Custom.CurveEndRows;
        
        % Check if any curve (except the first) is a correction from the wrong side to the correct side
        for iCurve = 1:min(2, length(startRows))
            if isPointingTo(trial.Target > midTarget, trial.Trajectory(startRows(iCurve), TrajCols.ImpliedEP)) && ...
                    isPointingTo(trial.Target < midTarget, trial.Trajectory(endRows(iCurve), TrajCols.ImpliedEP)) && ...
                    trial.Trajectory(startRows(iCurve), TrajCols.AbsTime) >= minTime
                confusion = true;
                confDegree = 1;
                return;
            end
        end
        
    end
    
    %----------------------------------------------------
    function [confusion, confDegree] = pointingCloserToIncorrectDigitAt(trial, rowNum, maxTarget)
        
        rowNum = min(rowNum, size(trial.Trajectory, 1));
        iep = trial.Trajectory(rowNum, TrajCols.ImpliedEP);
        decadeDigit = floor(trial.Target/10);
        unitDigit = mod(trial.Target, 10);
        
        confDegree = (abs(iep-decadeDigit*10) - abs(iep-unitDigit*10)) / maxTarget;
        confusion = confDegree > 0.05;
        if confusion
            confDegree = confDegree*100;
        else
            confDegree = 0;
        end
        
    end

    %----------------------------------------------------
    % A trial is considered as "confusion" if one of the first two curves
    % starts by pointing to the correct side and ends by pointing to the
    % incorrect side
    function conf = isGoodToBadTrial(trial)
        
        conf = false;
        
        if isempty(trial.Custom.CurveStartRows)
            return;
        end
        
        startRows = trial.Custom.CurveStartRows;
        endRows = trial.Custom.CurveEndRows;
        trTrg = getTransposedTarget(trial);
        
        % Check if a curve is a fix from CORRECT target to the TRANSPOSED
        % target
        for iCurve = 1:min(2, length(startRows))
            if isPointingTo(trial.Target < midTarget, trial.Trajectory(startRows(iCurve), TrajCols.ImpliedEP)) && ...
                    isPointingTo(trTrg > midTarget, trial.Trajectory(endRows(iCurve), TrajCols.ImpliedEP)) && ...
                    trial.Trajectory(startRows(1), TrajCols.AbsTime) >= minTime
                conf = true;
                return;
            end
        end
        
    end
    
    %----------------------------------------------------
    function p = isPointingTo(expectingLeft, iEP)
        if (expectingLeft)
            p = iEP < leftThreshold;
        else
            p = iEP > rightThreshold;
        end
    end

    %---------------------------------------------------
    function ud = getTransposedTarget(trial)
        decade = floor(trial.Target/10);
        unit = mod(trial.Target, 10);
        ud = unit*10 + decade;
    end

    %----------------------------------------------------
    function d = digitsAreOnTheSameSide(target)
        decade = floor(target/10);
        unit = mod(target, 10);
        midDigit = midTarget/10;
        d = (decade < midDigit && unit < midDigit) || (decade > midDigit && unit > midDigit);
    end

    %========================================================================
    % Regression-based confusions
    % A confusion here can be defined for any trial. For a given time t, we
    % can calculate the predicted implied endpoint according to the regression results. 
    % A confusion trials is when the transposed target predicts the implied endpoint 
    % better than the actual target. This test is done at the end of each
    % curve.
    % If the two targets yield very similar predictions ("implied endpoint
    % error" ratio < threshold), the trial is not considered as confusion.
    %========================================================================
    
    % The main function for finding a confusion
    function [conf, confDegree] = isConfusionTrialRegressionBased(iCond, expData, trial, allRR, rrKey, predictorExtractors, minErrRatio, checkConfusionTime)
        
        predictorValuesByTarget = arrayfun(@(pe)pe{1}(expData, trial, trial.Target), predictorExtractors);
        predictorValuesByTransposedTarget = arrayfun(@(pe)pe{1}(expData, trial, getTransposedTarget(trial)), predictorExtractors);
        
        if isempty(checkConfusionTime)
            checkConfusionRows = trial.Custom.CurveEndRows;
        else
            checkConfusionRows = find(expData.LongestTrial.Trajectory(:, TrajCols.AbsTime) >= checkConfusionTime, 1);
            if isempty(checkConfusionRows)
                error('Try a time later than %.2f', checkConfusionTime);
            end
        end
        
        conf = false;
        confDegree = 0;
        
        rr = allRR{iCond}.(expData.SubjectInitials).(rrKey);
        
        for row = checkConfusionRows
            
            row = min(row, size(trial.Trajectory, 1)); %#ok<FXSET>
            
            timeAtRow = trial.Trajectory(row, TrajCols.AbsTime);
            actualIEP = trial.Trajectory(row, TrajCols.ImpliedEP);
            
            b = getBCoeffs(rr, timeAtRow);
            
            predictedIEPByTarget = sum(b .* predictorValuesByTarget);
            errByTarget = abs(predictedIEPByTarget - actualIEP);
            
            predictedIEPByTransposedTarget = sum(b .* predictorValuesByTransposedTarget);
            errByTransposedTarget = abs(predictedIEPByTransposedTarget - actualIEP);
            
            if (errByTarget > errByTransposedTarget)
                confDegree = max(confDegree, errByTarget - errByTransposedTarget);
                if (errByTarget / errByTransposedTarget > minErrRatio)
                    conf = true;
                end
            end
            
        end
        
    end
    
    %-------------------------------------------------------------
    % Predict the implied endpoint of a trial
    function b = getBCoeffs(rr, timeToPredict)
        
        row = find(rr.times >= timeToPredict, 1);
        if isempty(row)
            row = length(rr.times);
        end
        
        b = arrayfun(@(pn)rr.(strcat('b_', pn{1}))(row), rr.predictorNames);
        
    end
    
    %-------------------------------------------------------------
    % This function returns a list of functions - one per regression
    % predictor.
    % Each such function is of the form value = func(trial, target)
    % It returns the value of the corresponding predictor for that trial,
    % assuming the specified target
    function extractors = getPredictorExtractors(allRR, rrKey)
        
        predNames = allRR.avg.(rrKey).predictorNames;
        extractors = {};
        
        for i = 1:length(predNames)
            switch(predNames{i})
                case 'const'
                    e = @(expData, trial, target)1;
                case 'decades'
                    e = @(expData, trial, target)floor(target/10)*10;
                case 'units'
                    e = @(expData, trial, target)mod(target,10);
                case 'log'
                    e = @(expData, trial, target)nlLog(target, expData.MaxTarget);
                case 'dlogtarget'
                    e = @(expData, trial, target)nlLog(target, expData.MaxTarget)-target;
                case 'ldrfix'
                    e = @(expData, trial, target)logDistanceRatio(target, expData.MaxTarget) - target;
                case 'prevtarget'
                    e = @(expData, trial, target)trial.PrevTarget;
                otherwise
                    error('Predictor "%s" is not supported', predNames{i});
            end
            extractors = [extractors {e}];
        end
        
    end

    %========================================================================
    %     Other stuff
    %========================================================================
    
    %----------------------------------------------------
    function doExport(result, exportFN, setNames, exportCondsAsColumns)
        
        fh = fopen(exportFN, 'w');
        if exportCondsAsColumns
            fprintf(fh, 'Subject,%s\n', join(',', setNames));
        else
            fprintf(fh, 'Cond,Subject,ConfRate\n');
        end
        
        for iSubj = 1:length(result(1).SubjIDs)
            if exportCondsAsColumns
                cr = arrayfun(@(iCond)result(iCond).confRate(iSubj), 1:length(result));
                fprintf(fh, '%s%s\n', result(1).SubjIDs{iSubj}, sprintf(',%f', cr));
            else
                for iCond = 1:length(result)
                    fprintf(fh, '%s,%s,%f\n', setNames{iCond}, result(iCond).SubjIDs{iSubj}, result(iCond).confRate(iSubj));
                end
            end
        end
        
        fclose(fh);
        
    end

    %----------------------------------------------------
    function [identifyPatternFunc, minTime, trialFilters, printResult, leftThreshold, rightThreshold, ...
            maxTarget, setNames, exportFN, exportCondsAsColumns, markConfusionsOnCustomAttr, compareConds] = parseArgs(args, allExpData)
        
        if ~iscell(allExpData)
            allExpData = {allExpData};
        end
        
        anyED = tt.util.structToArray(allExpData{1}, 'Any');
        maxTarget = allExpData{1}.general.MaxTarget;
        samplingRate = anyED.SamplingRate;
        minTime = 0.3;
        trialFilters = {};
        printResult = false;
        
        leftThreshold = floor(maxTarget*0.4);
        rightThreshold = ceil(maxTarget*0.6);
        
        confusionCalcMethod = 'startopposite';
        exportFN = '';
        exportCondsAsColumns = false;
        markConfusionsOnCustomAttr = false;
        
        setNames = arrayfun(@(ed){ed{1}.general.setName}, allExpData);
        
        allRR = [];
        rrKey = '';
        minErrRatio = 1;
        checkConfusionTime = [];
        compareConds = [];
        
        args = stripArgs(args);
        while ~isempty(args)
            switch(lower(args{1}))
                case 'method'
                    confusionCalcMethod = args{2};
                    args = args(2:end);
                    
                case 'mintime'
                    minTime = args{2};
                    args = args(2:end);
                    
                case 'trialfilter'
                    trialFilters = [trialFilters args(2)]; %#ok<*AGROW>
                    args = args(2:end);
                    
                case 'print'
                    printResult = true;
                    
                case 'description'
                    setNames = args{2};
                    args = args(2:end);
                    
                case 'export'
                    exportFN = args{2};
                    args = args(2:end);
                    
                case 'exportcond'
                    switch(lower(args{2}))
                        case 'cols'
                            exportCondsAsColumns = true;
                        case 'rows'
                            exportCondsAsColumns = false;
                        otherwise
                            error('Invalid "ExportCond" argument: %s', args{2});
                    end
                    args = args(2:end);
                    
                case 'mark'
                    markConfusionsOnCustomAttr = true;
                    
                case 'rr'
                    allRR = args{2};
                    args = args(2:end);
                    
                case 'rrkey'
                    rrKey = args{2};
                    args = args(2:end);
                    
                case 'minerrratio'
                    minErrRatio = args{2};
                    args = args(2:end);
                    
                case 'conftime'
                    checkConfusionTime = args{2};
                    args = args(2:end);
                    
                case 'compare'
                    compareConds = args{2};
                    args = args(2:end);
                    
                otherwise
                    error('Unsupported argument "%s"', args{1});
            end
            args = stripArgs(args(2:end));
        end
        
        
        switch(lower(confusionCalcMethod))
            case 'duconfusion'
                identifyPatternFunc = @isConfusionTrialLR;
                patternFilter = @(t)~digitsAreOnTheSameSide(t.Target);

            case 'startopposite'
                identifyPatternFunc = @startingToIncorrectSide;
                patternFilter = @(t)~digitsAreOnTheSameSide(t.Target);

            case 'badtogood'
                identifyPatternFunc = @isBadToGood;
                patternFilter = @(t)~digitsAreOnTheSameSide(t.Target);

            case 'duconfat'
                if isempty(checkConfusionTime)
                    error('With pattern="DUConfAt", you must the "ConfTime" parameter');
                end
                rowNum = round(checkConfusionTime/samplingRate);
                identifyPatternFunc = @(trial,~,~)pointingCloserToIncorrectDigitAt(trial, rowNum, maxTarget);
                patternFilter = [];

            case 'randomconfusion'
                identifyPatternFunc = @isConfusionTrialLR;
                patternFilter = @(t)digitsAreOnTheSameSide(t.Target);

            case 'goodtobad'
                identifyPatternFunc = @isGoodToBadTrial;
                patternFilter = @(t)~digitsAreOnTheSameSide(t.Target);

            case 'duconfreg'
                % Regression-based decade-unit confusions
                if isempty(allRR) || isempty(rrKey)
                    error('With pattern="DUConfReg", you must the "RR" and "RRKey" flags');
                end
                predictorExtractors = getPredictorExtractors(allRR{1}, rrKey);
                identifyPatternFunc = @(trial, expData, iCond)isConfusionTrialRegressionBased(iCond, expData, trial, allRR, rrKey, predictorExtractors, minErrRatio, checkConfusionTime);
                patternFilter = @(t)mod(t.Target/11, 0) ~= 0 && mod(t.Target, 10) ~= 0 && mod(t.Target, 10) ~= 9; % Exclude same-digit trials, whole-decade trials, and unit=9
                
            otherwise
                error('Unsupported method "%s"', confusionCalcMethod);
        end
        
        % Use only targets which are far enough from the middle
        notInMiddle = @(t)t.Target < leftThreshold || t.Target > rightThreshold;
        trialFilters = [{notInMiddle} trialFilters];
        if ~isempty(patternFilter), trialFilters = [{patternFilter} trialFilters]; end;
        
    end

end

