function result = filterTrials(inObj, filterFuncs)
% [trials, filterInds] = filterTrials(data, filter/s) - get subset of trials
% Returns a list of trials matching the filters
% 
% data: list of trilas, expData, or struct of expData's
% filter: either a filtering function or a cell array of function.
%         Valid signature: BOOLEAN filter_func(trial)
%                          BOOLEAN filter_func(trial, expData)
%         Signature#2 cannot be used if "filterTrials" is provided with a
%         list of trials and no ExperimentData

    if isa(filterFuncs, 'function_handle')
        filterFuncs = {filterFuncs};
    elseif ~iscell(filterFuncs)
        error('Invalid argument - expecting a cell array with filtering functions!');
    end
    
    
    result = [];

    if isstruct(inObj)
        processStruct(inObj);
    elseif iscell(inObj)
        % cell array of expData's
        processCellArray(inObj);
    elseif isa(inObj, 'ExperimentData')
        result = tt.util.filterTrialList(inObj.Trials, filterFuncs, inObj);
    elseif isa(inObj(1), 'OneTrialData')
        result = tt.util.filterTrialList(inObj, filterFuncs);
    else
        error('Invalid input');
    end
    
    
    %-------------------------------------------------------
    function processCellArray(allExpData)
        for i = 1:length(allExpData)
            ed = allExpData{i};
            if isstruct(ed)
                processStruct(ed);
            elseif isa(ed, 'ExperimentData')
                ttt = tt.util.filterTrialList(ed.Trials, filterFuncs, ed);
                result = [result ttt];
            else
                error('Invalid element in cell array');
            end
        end
    end
    
    %-------------------------------------------------------
    function processStruct(allExpData)
        ini = tt.inf.listInitials(allExpData);
        for iSubj = 1:length(ini)
            expData = allExpData.(ini{iSubj});
            ttt = tt.util.filterTrialList(expData.Trials, filterFuncs, expData);
            result = [result ttt];
        end
    end
    
end

