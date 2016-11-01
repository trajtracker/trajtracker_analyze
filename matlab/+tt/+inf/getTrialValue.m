function [result, subjIDs] = getTrialValue(inObj, varargin)
%result = getTrialValue(obj, ...) - Get the mean value of a per-trial value
%
% obj: An ExperimentData or a struct of ExperimentData's
% 
% Optional arguments:
% -------------------
% Trials <x>: Which trials to use -
%     All (default) - expData.Trials
%     AvgAbs - expData.AvgTrialsAbs
%     AvgNorm - expData.AvgTrialsNorm
% PerSubj: If multiple subjects were provided, return an array with values
%     of all subjects (if this flag is not specified: return mean of
%     means).
% PerTarget: Return mean value per target number
% AggFuncWithin <mean (default) / median / std>: choose function by which
%     values are aggregated within-subject.
% AggFuncBetween <mean (default) / median / std>: choose function by which
%     values are aggregated beteen subjects.
% TrialFilter @(trial)->BOOL: filter some trials
% SubjFilter @(expData)->BOOL: filter subjects
% SubjIDs: use only these subjects, in this order.
% 
% The following arguments specify the value to get. You must provide
% exactly one of them:
% Attr <attr-name>: the value is trial.(attr)
% CustomAttr <custom-attribute-name>: the value is trial.Custom.(attr)
% Getter @(trial)->number: a function that extracts value from a trial
% Safe: Ignore missing/NaN values (by default, these may cause error or a NaN result)
% 
% Return values:
% --------------
% result - the mean values
% subjIDs - the list of subject IDs corresponding with a per-subject
%           return value

    [getTrialValueFunc, trialSet, perSubject, perTarget, withinSubjAggFunc, ...
        betweenSubjAggFunc, safeGet, subjIDs, subjFilters, trialFilters] = parseArgs(varargin);
    
    if isa(inObj, 'ExperimentData')
        result = getMeanTrialValueOneSubj(inObj, trialSet, getTrialValueFunc, withinSubjAggFunc, perTarget, safeGet, trialFilters);
        subjIDs = {inObj.SubjectInitials};
    elseif isstruct(inObj)
        [result, subjIDs] = getMeanTrialValueMultiSubj(inObj, trialSet, getTrialValueFunc, withinSubjAggFunc, betweenSubjAggFunc, perSubject, perTarget, safeGet, subjIDs, trialFilters);
    end
    
    
    %---------------------------------------------------------------
    function [result, subjIDs] = getMeanTrialValueMultiSubj(allExpData, trialSet, getTrialValueFunc, withinSubjAggFunc, betweenSubjAggFunc, perSubject, perTarget, safeGet, subjIDs, trialFilters)
        
        if ~isempty(subjIDs)
            allED = tt.util.structToArray(allExpData, 'SubjIDs', subjIDs);
        else
            allED = tt.util.structToArray(allExpData);
        end
        
        for filter = subjFilters
            allED = allED(logical(arrayfun(filter{1}, allED)));
        end
        subjIDs = arrayfun(@(ed){ed.SubjectInitials}, allED);
        
        if isempty(allED)
            error('No subjects were found in the input argument!');
        end
        
        if (perTarget)
            
            vals = [];
            for ed = allED
                v = getMeanTrialValueOneSubj(ed, trialSet, getTrialValueFunc, withinSubjAggFunc, perTarget, safeGet, trialFilters);
                vals = [vals; v]; %#ok<AGROW>
            end
            
            if (perSubject)
                result = vals;
            else
                result = NaN(1, size(vals,2));
                for i = 1:size(vals,2)
                    tmp = vals(:,i);
                    result(i) = betweenSubjAggFunc(tmp(~isnan(tmp)));
                end
            end
            
        else
            
            result = arrayfun(@(ed)getMeanTrialValueOneSubj(ed, trialSet, getTrialValueFunc, withinSubjAggFunc, perTarget, safeGet, trialFilters), allED)';
            if (~ perSubject)
                result = betweenSubjAggFunc(result);
            end
            
        end
        
    end
    
    %---------------------------------------------------------------
    function result = getMeanTrialValueOneSubj(expData, trialSet, getTrialValueFunc, withinSubjAggFunc, perTarget, safeGet, trialFilters)
        
        allTrials = tt.util.filterTrialList(expData.(trialSet), trialFilters);
        
        if (perTarget)
            if ~isa(expData, 'NLExperimentData')
                error('"PerTarget" mode is currently supported only for number-to-line experiments!');
            end
            
            trialTargets = arrayfun(@(t)t.Target, allTrials);
            
            result = NaN(1, length(expData.MaxTarget+1));
            for target = 0:expData.MaxTarget
                if (safeGet)
                    vals = myarrayfun(getTrialValueFunc, allTrials(trialTargets == target));
                    vals = vals(~isnan(vals));
                else
                    vals = arrayfun(getTrialValueFunc, allTrials(trialTargets == target));
                end
                result(target+1) = withinSubjAggFunc(vals);
            end
            
        else
            
            if (safeGet)
                vals = myarrayfun(getTrialValueFunc, allTrials);
                vals = vals(~isnan(vals));
            else
                vals = arrayfun(getTrialValueFunc, allTrials);
            end
            result = withinSubjAggFunc(vals);
        end
        
    end
    
    %---------------------------------------------------------------
    function [getTrialValueFunc, trialSet, perSubject, perTarget, withinSubjAggFunc, betweenSubjAggFunc, ...
              safeGet, subjIDs, subjFilters, trialFilters] = parseArgs(args)
        
        safeGet = false;
        trialSet = 'Trials';
        perSubject = 0;
        perTarget = 0;
        subjIDs = [];
        trialFilters = {};
        subjFilters = {};
        getTrialValueFunc = [];
        customAttrName = '';
        
        AGG_FUNCS = struct('mean', @(x)mean(x), 'median', @(x)median(x), 'std', @(x)std(x));
        
        withinSubjAggFunc = AGG_FUNCS.mean;
        betweenSubjAggFunc = AGG_FUNCS.mean;
        
        args = stripArgs(args);
        
        while ~isempty(args)
            switch(lower(args{1}))
                case 'trials'
                    switch(lower(args{2}))
                        case 'trials'
                            trialSet = 'Trials';
                            
                        case 'avgabs'
                            trialSet = 'AvgTrialsAbs';
                            
                        case 'avgnorm'
                            trialSet = 'AvgTrialsNorm';
                            
                        otherwise
                            error('Unknown trial set: %s', args{2});
                    end
                    
                case 'persubj'
                    perSubject = 1;
                    
                case 'pertarget'
                    perTarget = 1;
                    
                case 'aggfuncwithin'
                    withinSubjAggFunc = AGG_FUNCS.(lower(args{2}));
                    args = args(2:end);
                    
                case 'aggfuncbetween'
                    betweenSubjAggFunc = AGG_FUNCS.(lower(args{2}));
                    args = args(2:end);
                    
                case 'subjids'
                    subjIDs = args{2};
                    args = args(2:end);
                    
                case 'trialfilter'
                    trialFilters = [trialFilters args(2)]; %#ok<AGROW>
                    args = args(2:end);
                    
                case 'subjfilter'
                    subjFilters = [subjFilters args(2)]; %#ok<AGROW>
                    args = args(2:end);
                    
                case 'attr'
                    attrName = args{2};
                    args = args(2:end);
                    getTrialValueFunc = @(t)t.(attrName);
                    
                case 'customattr'
                    customAttrName = args{2};
                    args = args(2:end);
                    getTrialValueFunc = @(t)t.Custom.(customAttrName);
                    
                case 'safe'
                    safeGet = true;
                    
                case 'getter'
                    getTrialValueFunc = args{2};
                    args = args(2:end);
                    
                otherwise
                    UnknownArgument = args{1} %#ok<NASGU,NOPRT>
                    error('Unknown argument');
            end
            
            args = stripArgs(args(2:end));
        end
        
        if isempty(getTrialValueFunc)
            error('Specify the value to get!');
        end
        
        if safeGet && ~isempty(customAttrName)
            filter = @(trial)isfield(trial.Custom, customAttrName);
            trialFilters = [trialFilters {filter}];
        end
        
        if ~isempty(subjIDs) && ~isempty(subjFilters)
            error('You cannot specify both "SubjIDs" and "SubjFilter"');
        end
        
    end

end
