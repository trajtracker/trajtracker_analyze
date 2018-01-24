function exportRR(allRR, rrKey, outFN, varargin)
%exportRR(allRR, rrKey, outFN, ...) -
% Export regression results
% 
% allRR - regression results or cell array of such
% 
% Optional arguments:
% Desc <cell-array> - names of conditions
% Params <cell-array>/string - export only these parameter/s
% Format Rows / ColPerParam - output format
% MinTime <t>
% MaxTime <t>

    FORMAT_ROWS = 1;
    FORMAT_COL_PER_PARAM = 2;
    
    if ~iscell(allRR)
        allRR = {allRR};
    end
    
    printCondName = length(allRR) > 1;
    
    [paramNames, paramDesc, condNames, timeFilters, outputFormat, subjIDs] = parseArgs(varargin, allRR, rrKey);
    [predNames, predParams] = parseParamName(paramNames);
    
    nSubjs = length(subjIDs);
    
    nTimes = max(arrayfun(@(iCond)max(arrayfun(@(iSubj)length(allRR{iCond}.(subjIDs{iSubj}).(rrKey).times), 1:nSubjs)), 1:length(allRR)));
    if length(allRR{1}.(subjIDs{1}).(rrKey).times) > 1
        samplingRate = diff(allRR{1}.(subjIDs{1}).(rrKey).times(1:2));
    else
        samplingRate = 1;
    end
    times = allRR{1}.(subjIDs{1}).(rrKey).times(1) + samplingRate*(0:(nTimes-1));
    
    fh = fopen(outFN, 'w');
    if fh <= 0
        error('The output file cannot be opened: %s', outFN);
    end
    
    if printCondName
        fprintf(fh, 'Condition,');
    end
    
    switch(outputFormat)
        case FORMAT_ROWS
            fprintf(fh, 'Subject,Parameter,Time,b\n');
        case FORMAT_COL_PER_PARAM
            fprintf(fh, 'Subject,Time,%s\n', join(',', paramDesc));
        otherwise
            error('Unsupported format');
    end
    
    for iCond = 1:length(allRR)
        
        condRR = allRR{iCond};
        if printCondName
            currCondName = strcat(condNames{iCond}, ',');
        else
            currCondName = '';
        end
        
        for iSubj = 1:nSubjs
            
            subjID = subjIDs{iSubj};
            rr = condRR.(subjID).(rrKey);
            maxTimeInd = length(rr.times);
            
            timeInds = 1:length(rr.times);
            for i = 1:length(timeFilters)
                timeInds = timeInds(arrayfun(@(t)timeFilters{i}(rr.times(t)), 1:length(timeInds)));
            end
            
            timeInds = 1:nTimes;
            timeInds(timeInds > maxTimeInd) = maxTimeInd; % Keep using the last time point as long as needed
            for i = 1:length(timeFilters)
                timeInds = timeInds(arrayfun(@(t)timeFilters{i}(rr.times(timeInds(t))), 1:length(timeInds)));
            end
            
            for iTime = 1:length(timeInds)
                
                switch(outputFormat)
                    case FORMAT_ROWS
                        for iParam = 1:length(paramNames)
                            data = rr.getPredResult(predNames{iParam}).(predParams{iParam});
                            fprintf(fh, '%s%s,%s,%f,%f\n', currCondName, subjID, paramDesc{iParam}, times(iTime), data(timeInds(iTime)));
                        end
                    case FORMAT_COL_PER_PARAM
                        values = arrayfun(@(iParam){sprintf('%f', rr.getPredResult(predNames{iParam}).(predParams{iParam})(timeInds(iTime)))}, 1:length(paramNames));
                        fprintf(fh, '%s%s,%f,%s\n', currCondName, subjID, times(iTime), join(',', values));
                end
                
            end
            
        end
        
    end
    
    fclose(fh);
    
    
    
    %---------------------------------------
    function [predNames, predParams] = parseParamName(paramNames)
        predNames = cell(size(paramNames));
        predParams = cell(size(paramNames));
        for ii = 1:length(paramNames)
            ind = find(paramNames{ii}=='.', 1);
            predNames{ii} = paramNames{ii}(1:ind-1);
            predParams{ii} = paramNames{ii}(ind+1:end);
        end
    end

    %---------------------------------------
    function [paramNames, paramDesc, condNames, timeFilters, outFormat, subjIDs] = parseArgs(args, allRR, rrKey)
        
        origSIDs = tt.reg.listInitials(allRR{1});
        subjIDs = origSIDs;
        anyRR = allRR{1}.(subjIDs{1}).(rrKey);
        
        paramNames = arrayfun(@(n){strcat(n{1}, '.b')}, anyRR.predictorNames);
        condNames = arrayfun(@(i){sprintf('cond%d',i)}, 1:length(allRR));
        paramDesc = {};
        
        timeFilters = {};
        outFormat = FORMAT_ROWS;
        
        args = stripArgs(args);
        while ~isempty(args)
            switch(lower(args{1}))
                case 'desc'
                    condNames = args{2};
                    args = args(2:end);
                    
                case 'params'
                    paramNames = args{2};
                    args = args(2:end);
                    if ischar(paramNames)
                        paramNames = {paramNames};
                    end
                    
                case 'paramdesc'
                    paramDesc = args{2};
                    args = args(2:end);
                    
                case 'mintime'
                    minTime = args{2};
                    args = args(2:end);
                    filter = @(t)t>=minTime;
                    timeFilters = [timeFilters {filter}];
                    
                case 'maxtime'
                    maxTime = args{2};
                    args = args(2:end);
                    filter = @(t)t<=maxTime;
                    timeFilters = [timeFilters {filter}];
                    
                case 'format'
                    switch(lower(args{2}))
                        case 'rows'
                            outFormat = FORMAT_ROWS;
                        case 'colperparam'
                            outFormat = FORMAT_COL_PER_PARAM;
                        otherwise
                            error('Unknown output format "%s"', args{2});
                    end
                    args = args(2:end);
                    
                case 'subjids'
                    subjIDs = args{2};
                    args = args(2:end);
                    
                case 'excludesubjids'
                    exsid = args{2};
                    args = args(2:end);
                    subjIDs = origSIDs(~ismember(origSIDs, exsid));
                    
                otherwise
                    error('unsupported argument "%s"', args{1});
            end
            
            args = stripArgs(args(2:end));
        end
        
        if isempty(paramDesc)
            paramDesc = paramNames;
        end
        
    end

end

