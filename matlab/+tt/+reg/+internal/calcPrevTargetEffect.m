function [allRR, meanVals] = calcPrevTargetEffect(allRR, regName, varargin)
%allRR = calcPrevTargetEffect(allRR, regName, ...) -
% Calculate the previous-target effect, over time

    [varNames, timeRange, createSeparateOutVars, singleOutputVarName] = parseArgs(varargin);

    meanOutVar = sprintf('mean_%s', singleOutputVarName);
    stdOutVar = sprintf('sd_%s', singleOutputVarName);
    
    % Calcualte average values
    allSubjIDs = tt.reg.listInitials(allRR);
    
    meanVals = zeros(length(allSubjIDs), length(varNames));
    
    for iSubj = 1:length(allSubjIDs)
        s = allSubjIDs{iSubj};
        
        for iVar = 1:length(varNames)
            v = varNames{iVar};
            mv = sprintf('mean_%s', v);
            
            times = allRR.(s).(regName).times;
            vals = allRR.(s).(regName).getPredResult(v).b;
            
            meanVals(iSubj, iVar) = mean(vals(times >= timeRange(1) & times <= timeRange(2)));
            
            if (createSeparateOutVars)
                allRR.(s).(regName).Custom.(mv) = meanVals(iSubj, iVar);
            end
        end
        
        if ~ isempty(singleOutputVarName)
            allRR.(s).(regName).Custom.(meanOutVar) = meanVals(iSubj, :);
        end
        
    end
    
    % Average over subjects
    if ~ isempty(singleOutputVarName)
        allRR.avg.(meanOutVar) = mean(meanVals);
        allRR.avg.(stdOutVar) = std(meanVals);
    end
    
    %---------------------------------------------------------------
    function [varNames, timeRange, createSeparateOutVars, singleOutputVarName] = parseArgs(args)
        
        singleOutputVarName = '';
        timeRange = [0 .3];
        createSeparateOutVars = 1;
        
        args = stripArgs(args);
        
        while ~isempty(args)
            switch(lower(args{1}))
                case 'timerange'
                    timeRange = args{2};
                    args = args(2:end);
                    
                case 'vars'
                    varNames = args{2};
                    args = args(2:end);
                    
                case 'nprevtargets'
                    nPrevTargets = args{2};
                    varNames = [{'prevtarget'} arrayfun(@(i){sprintf('PrevTarget%d', i)}, 2:nPrevTargets)];
                    args = args(2:end);
                    
                case 'out1'
                    createSeparateOutVars = 0;
                    singleOutputVarName = args{2};
                    args = args(2:end);
                    
                otherwise
                    error('Unknown argument: %s', args{1});
            end
            
            args = stripArgs(args(2:end));
        end
        
    end

end

