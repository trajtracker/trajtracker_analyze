function [trialList, includedTrials] = filterTrialList(trialList, filterFuncs, filterFuncArg)
%[trialList, filterInds] = filterTrialList(trialList, filterFuncs[, filterFuncArg])
% Apply filtering functions to a list of trials
%
% trialList: array of trials
% filterFuncs: cell array of functions. Each function returns boolean, and
%              gets a trial and optionally a second argument, which is "filterFuncArg".
% filterFuncArg: 2nd argument to add to the filtering function (e.g., ExpData)

    supportExtraArgs = exist('filterFuncArg', 'var');
    
    trialList = reshape(trialList, 1, numel(trialList));
    includedTrials = true(1, length(trialList));

    for i = 1:length(filterFuncs)

        filter = filterFuncs{i};
        
        switch nargin(filter)
            case 1
                %-- Filter function expects only a trial
                includedTrials(includedTrials) = logical(arrayfun(filter, trialList(includedTrials)));
                
            case 2
                %-- Filter function expects a trial+expData
                if ~supportExtraArgs
                    error('filterTrialList() was called without extra arguments, but they are expected by the filtering function %s', char(filter));
                else
                    includedTrials(includedTrials) = logical(arrayfun(@(trial)filter(trial, filterFuncArg), trialList(includedTrials)));
                end

            otherwise
                error('Invalid filtering function: %s\nOnly functions with 1 or 2 arguments can be used', char(filter));
        end
    end

    trialList = trialList(includedTrials);
    
end

