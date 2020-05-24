function [result,subjIDs] = printBasicStats(allED, varargin)
%result - printBasicStats(allED) - Print some basic statistics per dataset:
%success, endpoint bias/error, movement time, error types, etc.
% 
% allED: cell array with one dataset per condition. Each entry should be a
%        struct with 'raw' and 'd' in it.
% 
% Optional arguments:
% Errs: print detailed distribution of all error types.
% Custom <char / cell-array>: print info about each of these custom attributes
%             (they should be numeric scalars)

    if isstruct(allED)
        allED = {allED};
    end
    
    anyED = tt.util.structToArray(allED{1}.raw, 'Any');
    isNL = isa(anyED, 'NLExperimentData');
    
    [customAttrNames, plotDetailedErrs] = parseArgs(varargin);
    
    result = cell(1, length(allED));
    subjIDs = tt.inf.listInitials(allED{1}.raw);
    
    allRaw = [];
    allClean = [];
    
    for iCond = 1:length(allED)
        
        fprintf('\nCondition #%d (%d subjects): %s\n', iCond, length(tt.inf.listInitials(allED{iCond})), allED{iCond}.raw.general.CondName);
        
        currRaw = tt.util.structToArray(allED{iCond}.raw, 'SubjIDs', subjIDs);
        currClean = tt.util.structToArray(allED{iCond}.d, 'SubjIDs', subjIDs);
        result{iCond} = process(currRaw, currClean);
        
        allRaw = [allRaw currRaw];
        allClean = [allClean currClean]; %#ok<*AGROW>
        
    end
    
    if length(allED) > 1
        
        fprintf('\n\nAll conditions:\n');
        process(allRaw, allClean);

        fprintf('\n\n');
        compareConds(result, 'MovementTime');
        if isNL
            compareConds(result, 'EndpointBias');
            compareConds(result, 'EndpointErr');
        end
        compareConds(result, 'FailedTrialRate');
    
    end
    
    %---------------------------------------------------
    % Compare conditions
    function compareConds(result, resultAttr)
        
        anovaData = [];
        
        for i = 1:length(result)
            anovaData = [anovaData result{i}.(resultAttr)'];
        end
        
        [~,anovaTab] = anova_rm(anovaData, 'off');
        
        df = anovaTab{2,3};
        dfe = anovaTab{4,3};
        F = anovaTab{2,5};
        p = anovaTab{2,6};
        
        fprintf('%s: F(%d,%d) = %.2f, p=%.3f\n', resultAttr, df, dfe, F, p);
        
    end
    
    %---------------------------------------------------
    function r = process(rawExpData, cleanExpData)
        
        r = struct;
        
        nTrials = sum(arrayfun(@(ed)length(ed.Trials), rawExpData));
        nBadTrials = sum(arrayfun(@(ed)sum(arrayfun(@(t)t.ErrCode > 0, ed.Trials)), rawExpData));
        errRate = arrayfun(@(ed)sum(arrayfun(@(t)t.ErrCode > 0, ed.Trials)) / length(ed.Trials), rawExpData);
        fprintf('  Error trials: %d/%d (%.1f%% +/- %.1f%%)\n', nBadTrials, nTrials, 100*mean(errRate), 100*std(errRate));
        
        r.MovementTime = arrayfun(@(ed)ed.MeanMovementTime, cleanExpData);
        fprintf('  Movement time: %.3f +/- %.3f\n', mean(r.MovementTime), std(r.MovementTime));
        
        r.EPOutlierRate = arrayfun(@(ed)getEndpointOutlierRate(ed), rawExpData);
        fprintf('  Endpoint outliers: %.2f%% +/- %.2f%%\n', 100*mean(r.EPOutlierRate), 100*std(r.EPOutlierRate));
        
        if isNL
            r.EndpointBias = arrayfun(@(ed)ed.MeanEndpointBias, cleanExpData);
            fprintf('  Endpoint bias: %.2f +/- %.2f\n', mean(r.EndpointBias), std(r.EndpointBias));

            r.EndpointErr = arrayfun(@(ed)ed.MeanEndpointError, cleanExpData);
            fprintf('  Endpoint error: %.2f +/- %.2f\n', mean(r.EndpointErr), std(r.EndpointErr));
        end
        
        for iAttr = 1:length(customAttrNames)
            attr = customAttrNames{iAttr};
            value = arrayfun(@(ed)tt.inf.getTrialValue(ed, 'CustomAttr', attr, 'Safe'), cleanExpData);
            fprintf('  %s: %.3f +/- %.3f\n', attr, mean(value), std(value));
            r.(attr) = value;
        end
        
        r.FailedTrialRate = arrayfun(@(ed)ed.FailedTrialRate, rawExpData);
        fprintf('  Failed trials: %.2f%% +/- %.2f%%\n', 100*mean(r.FailedTrialRate), 100*std(r.FailedTrialRate));
        
        if plotDetailedErrs
            
            r.NamingErrRate = arrayfun(@(ed)getAllNamingErrorRate(ed), rawExpData);
            fprintf('      Naming errors: %.2f%% +/- %.2f%%\n', 100*mean(r.NamingErrRate), 100*std(r.NamingErrRate));

            r.NamingContentErrRate = arrayfun(@(ed)getNamingContentErrorRate(ed), rawExpData);
            fprintf('          Contents: %.2f%% +/- %.2f%%\n', 100*mean(r.NamingContentErrRate), 100*std(r.NamingContentErrRate));

            r.NamingStructuralErrRate = arrayfun(@(ed)getNamingStructuralErrorRate(ed), rawExpData);
            fprintf('          Structural: %.2f%% +/- %.2f%%\n', 100*mean(r.NamingStructuralErrRate), 100*std(r.NamingStructuralErrRate));

            r.VelocityErrRate = arrayfun(@(ed)getVelocityErrorRate(ed), rawExpData);
            fprintf('      Velocity errors: %.2f%% +/- %.2f%%\n', 100*mean(r.VelocityErrRate), 100*std(r.VelocityErrRate));

            r.OtherErrRate = arrayfun(@(ed)getOtherErrorRate(ed), rawExpData);
            fprintf('      Other errors: %.2f%% +/- %.2f%%\n', 100*mean(r.OtherErrRate), 100*std(r.OtherErrRate));

            [nameByCode, ~, errCodes] = TrialErrCodes.getAllErrCodes();
            fprintf('      Per error code:\n');
            for ec = errCodes
                rate = arrayfun(@(ed)getErrorRate(ed, ec), rawExpData);
                fprintf('          %s: %.2f%% +/- %.2f%%\n', nameByCode.(sprintf('e%d', ec)), 100*mean(rate), 100*std(rate));
            end
            
        end
        
    end

    %---------------------------------------------------
    function rate = getVelocityErrorRate(expData)
        
        nErrs = sum(arrayfun(@(t)ismember(t.ErrCode, [TrialErrCodes.TooSlowGlobal, TrialErrCodes.TooSlowInstantaneous]), expData.Trials));
        nTrials = length(expData.Trials);
        rate = nErrs / nTrials;
        
    end

    %---------------------------------------------------
    function rate = getAllNamingErrorRate(expData)
        nErrs = sum(arrayfun(@(t)TrialErrCodes.isAnySpeechError(t.ErrCode), expData.Trials));
        nTrials = length(expData.Trials);
        rate = nErrs / nTrials;
    end

    %---------------------------------------------------
    function rate = getNamingContentErrorRate(expData)
        nErrs = sum(arrayfun(@(t)TrialErrCodes.isSpeechContentsError(t.ErrCode), expData.Trials));
        nTrials = length(expData.Trials);
        rate = nErrs / nTrials;
    end

    %---------------------------------------------------
    function rate = getNamingStructuralErrorRate(expData)
        nErrs = sum(arrayfun(@(t)TrialErrCodes.isStructuralSpeechError(t.ErrCode), expData.Trials));
        nTrials = length(expData.Trials);
        rate = nErrs / nTrials;
    end

    %---------------------------------------------------
    function rate = getOtherErrorRate(expData)
        
        nErrs = sum(arrayfun(@(t)~ismember(t.ErrCode, [TrialErrCodes.OK TrialErrCodes.Outlier TrialErrCodes.TooSlowGlobal TrialErrCodes.TooSlowInstantaneous]) & ~ TrialErrCodes.isStructuralSpeechError(t.ErrCode) & ~ TrialErrCodes.isSpeechContentsError(t.ErrCode), expData.Trials));
        nTrials = length(expData.Trials);
        rate = nErrs / nTrials;
        
    end

    %---------------------------------------------------
    function rate = getErrorRate(expData, errCode)
        
        nErrs = sum(arrayfun(@(t)t.ErrCode == errCode, expData.Trials));
        nTrials = length(expData.Trials);
        rate = nErrs / nTrials;
        
    end

    %---------------------------------------------------
    function outlierRate = getEndpointOutlierRate(rawExpData)
        t = rawExpData.filterTrialsWithErrCode([TrialErrCodes.Outlier]);
        nOutliers = length(t.Trials);
        nTrials = length(rawExpData.OKTrials) + nOutliers;
        outlierRate = nOutliers / nTrials;
    end

    %---------------------------------------------------
    function [customAttrNames, plotDetailedErrs] = parseArgs(args)
        
        customAttrNames = {};
        plotDetailedErrs = false;
        
        args = stripArgs(args);
        
        while ~isempty(args)
            
            switch(lower(args{1}))
                case 'custom'
                    customAttrNames = args{2};
                    if ischar(customAttrNames)
                        customAttrNames = {customAttrNames};
                    end
                    args = args(2:end);
                    
                case 'errs'
                    plotDetailedErrs = true;
                    
                otherwise
                    error('Invalid argument: %s', args{1});
            end
            
            args = stripArgs(args(2:end));
            
        end
        
    end

end

