function [values, times, subjIDs] = getRRCoeffs(allRR, regressionKey, paramName, varargin)
% [values, times, subjIDs] = getRRCoeffs(allRR, regressionKey, paramName, ...)
% Extract one parameter from results of one regression, for all subjects, in
% all timeslots.
%
% The returned "values" var is a timepoints x subjects matrix. NaN values
% indicate situations where a subject doens't have that many time points.
% 
% Optional arguments:
% Times <t> : times to extract
% NoExpand: Do not expand first/last trajectory values to extend before/after 
%           its ends
% SubjIDs <cell-array>: use these subject ID's

    [doExpand, subjIDs, timesToExtract] = parseArgs(varargin, allRR);
    
    regArray = myarrayfun(@(s){allRR.(s{1})}, subjIDs);
    if ~isfield(regArray{1}, regressionKey)
        error('Regression "%s" was not found', regressionKey);
    end
        
    longestRR = getLongestRegression(regArray, regressionKey);
    times = longestRR.times;

    if isempty(timesToExtract)
        timeInds = 1:length(times);
    else
        timeInds = arrayfun(@(t)find(times >= timesToExtract-0.0001, 1), timesToExtract);
    end
    
    values = NaN(length(timeInds), length(subjIDs));
    for i = 1:length(regArray)
        paramVal = regArray{i}.(regressionKey).getParamValue(paramName);
        relevantInds = timeInds(timeInds <= length(paramVal));
        values(1:length(relevantInds),i) = paramVal(relevantInds);
        if (doExpand && ~isempty(timeInds(timeInds > length(paramVal))))
            values( (length(relevantInds)+1):end, i) = paramVal(end);
        end
    end
    
    %---------------------------------------------------------------------
    function longestRR = getLongestRegression(regArray, regressionKey)
        [~,ind] = max(arrayfun(@(rr)length(rr{1}.(regressionKey).times), regArray));
        longestRR = regArray{ind}.(regressionKey);
    end

    %------------------------------------------------------------------------
    function [doExpand, subjIDs, timesToExtract] = parseArgs(args, allRR)
        
        doExpand = 1;
        subjIDs = {};
        timesToExtract = [];
        
        args = stripArgs(args);
        
        while ~isempty(args)
            switch(lower(args{1}))
                case 'noexpand'
                    doExpand = 0;
                    
                case 'subjids'
                    subjIDs = args{2};
                    args = args(2:end);
                    
                case 'times'
                    timesToExtract = args{2};
                    args = args(2:end);
                    
                case 'void'
                    % ignore this flag
                    
                otherwise
                    error('Unknown flag "%s"', args{1});
            end
            
            args = stripArgs(args(2:end));
            
        end
        
        if isempty(subjIDs)
            subjIDs = tt.reg.getSubjInitials(allRR);
        end
        
    end

end
