function [result, subjIDs] = getTrialValue(inObj, varargin)
%result = getTrialValue(obj, ...) - Get the mean value of a per-trial value
%
% obj: An ExperimentData or a struct of ExperimentData's
% 
% Optional arguments:
% -------------------
% Trials <x>: Which trials to use -
%     All (default) - all trials
%     AvgAbs - average trials, abs x
%     AvgClean - average trials, clean x
%     AvgNorm - average trials, norm
% PerSubj: If multiple subjects were provided, return an array with values
%     of all subjects (if this flag is not specified: return mean of
%     means).
% SubjIDs: use only these subjects, in this order.
% PerTarget: Return mean value per target number
% AggFuncWithin <mean (default) / median / std>: choose function by which
%     values are aggregated within-subject.
% AggFuncBetween <mean (default) / median / std>: choose function by which
%     values are aggregated beteen subjects.
% NoNAN: remove NaN values before aggregating
% TrialFilter @(trial)->BOOL: filter some trials
% 
% The following arguments specify the value to get. You must provide
% exactly one of them:
% Prop <property-name>: the value is trial.(property)
% CustomProp <custom-property-name>: the value is trial.Custom.(property)
% Getter @(trial)->number: a function that extracts value from a trial
% 
% Return values:
% --------------
% result - the mean values
% subjIDs - the list of subject IDs corresponding with a per-subject
%           return value

    [getPropertyFunc, trialSetProperty, perSubject, perTarget, withinSubjAggFunc, ...
        betweenSubjAggFunc, removeNANs, subjIDs, trialFilter] = parseArgs(varargin);
    
    if isa(inObj, 'ExperimentData')
        result = getMeanTrialPropertyOneSubj(inObj, trialSetProperty, getPropertyFunc, withinSubjAggFunc, perTarget, removeNANs, trialFilter);
        subjIDs = {inObj.SubjectInitials};
    elseif isstruct(inObj)
        [result, subjIDs] = getMeanTrialPropertyMultiSubj(inObj, trialSetProperty, getPropertyFunc, withinSubjAggFunc, betweenSubjAggFunc, perSubject, perTarget, removeNANs, subjIDs, trialFilter);
    end
    
    
    %---------------------------------------------------------------
    function [result, subjIDs] = getMeanTrialPropertyMultiSubj(allExpData, trialSetProperty, getPropertyFunc, withinSubjAggFunc, betweenSubjAggFunc, perSubject, perTarget, removeNANs, subjIDs, trialFilter)
        
        if isempty(subjIDs)
            subjIDs = tt.inf.listInitials(allExpData);
        end
        
        allED = tt.util.structToArray(allExpData, 0, subjIDs);
        if isempty(allED)
            error('No subjects were found in the input argument!');
        end
        
        if (perTarget)
            
            vals = [];
            for ed = allED
                v = getMeanTrialPropertyOneSubj(ed, trialSetProperty, getPropertyFunc, withinSubjAggFunc, perTarget, removeNANs, trialFilter);
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
            
            result = arrayfun(@(ed)getMeanTrialPropertyOneSubj(ed, trialSetProperty, getPropertyFunc, withinSubjAggFunc, perTarget, removeNANs, trialFilter), allED)';
            if (~ perSubject)
                result = betweenSubjAggFunc(result);
            end
            
        end
        
    end
    
    %---------------------------------------------------------------
    function result = getMeanTrialPropertyOneSubj(expData, trialSetProperty, getPropertyFunc, withinSubjAggFunc, perTarget, removeNANs, trialFilter)
        
        allTrials = expData.(trialSetProperty);
        allTrials = allTrials(arrayfun(trialFilter, allTrials));
        
        if (perTarget)
            if ~isa(expData, 'NLExperimentData')
                error('"PerTarget" mode is currently supported only for number-to-line experiments!');
            end
            
            trialTargets = arrayfun(@(t)t.Target, allTrials);
            
            result = NaN(1, length(expData.MaxTarget+1));
            for target = 0:expData.MaxTarget
                vals = arrayfun(getPropertyFunc, allTrials(trialTargets == target));
                if (removeNANs)
                    vals = vals(~isnan(vals));
                end
                result(target+1) = withinSubjAggFunc(vals);
            end
            
        else
            
            vals = arrayfun(getPropertyFunc, allTrials);
            if (removeNANs)
                vals = vals(~isnan(vals));
            end
            result = withinSubjAggFunc(vals);
        end
        
    end
    
    %---------------------------------------------------------------
    function [getPropertyFunc, trialSetProperty, perSubject, perTarget, withinSubjAggFunc, betweenSubjAggFunc, ...
              removeNANs, subjIDs, trialFilter] = parseArgs(args)
        
        removeNANs = 0;
        trialSetProperty = 'Trials';
        perSubject = 0;
        perTarget = 0;
        subjIDs = [];
        trialFilter = @(trial)true;
        getPropertyFunc = [];
        
        AGG_FUNCS = struct('mean', @(x)mean(x), 'median', @(x)median(x), 'std', @(x)std(x));
        
        withinSubjAggFunc = AGG_FUNCS.mean;
        betweenSubjAggFunc = AGG_FUNCS.mean;
        
        args = stripArgs(args);
        
        while ~isempty(args)
            switch(lower(args{1}))
                case 'trials'
                    switch(lower(args{2}))
                        case 'trials'
                            trialSetProperty = 'Trials';
                            
                        case 'avgabs'
                            trialSetProperty = 'AvgTrialsAbs';
                            
                        case 'avgnorm'
                            trialSetProperty = 'AvgTrialsNorm';
                            
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
                    
                case 'nonan'
                    removeNANs = 1;
                    
                case 'subjids'
                    subjIDs = args{2};
                    args = args(2:end);
                    
                case 'trialfilter'
                    trialFilter = args{2};
                    args = args(2:end);
                    
                case 'prop'
                    propName = args{2};
                    args = args(2:end);
                    getPropertyFunc = @(t)t.(propName);
                    
                case 'customprop'
                    propName = args{2};
                    args = args(2:end);
                    getPropertyFunc = @(t)t.Custom.(propName);
                    
                case 'getter'
                    getPropertyFunc = args{2};
                    args = args(2:end);
                    
                otherwise
                    UnknownArgument = args{1} %#ok<NASGU,NOPRT>
                    error('Unknown argument');
            end
            
            args = stripArgs(args(2:end));
        end
        
        if isempty(getPropertyFunc)
            error('Specify the property to get!');
        end
        
    end

end
