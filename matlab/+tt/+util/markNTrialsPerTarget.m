function markNTrialsPerTarget(allExpData, nTrials, markFirst, customAttrName)
% markNTrialsPerTarget(dataset, n, first, attrName) -
% Find the first or last N trials per target, and mark them using a custom
% attribute.
% 
% dataset: struct of ExpData's
% n: number of trials
% first: boolean flag indicating whether to mark n first or last trials per
%        target.
% attrName: name of custom attribute. It will be updated with true/false values.

    for expData = tt.util.structToArray(allExpData)
        process(expData);
    end
    
    
    %-----------------------------------
    function process(expData)
        
        targets = arrayfun(@(t)t.Target, expData.Trials);
        
        % Find indices of trials that match the condition
        markInds = [];
        for target = targets
            targetInds = find(targets == target);
            n = min(nTrials, length(targetInds));
            if markFirst
                i = targetInds(1:n);
            else
                i = targetInds(end-n+1:end);
            end
            markInds = [markInds i];
        end
        
        %-- Mark each trial with TRUE or FALSE
        flagValue = false(1, length(expData.Trials));
        flagValue(markInds) = true;
        for i = 1:length(expData.Trials)
            expData.Trials(i).Custom.(customAttrName) = flagValue(i);
        end
        
    end
    
end

