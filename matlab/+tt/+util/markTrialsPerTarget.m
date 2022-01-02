function markTrialsPerTarget(allExpData, nTrials, trialToMark, customAttrName)
% markNTrialsPerTarget(dataset, n, first, attrName) -
% Find the first or last N trials per target, and mark them using a custom
% attribute.
% 
% dataset: struct of ExpData's
% n: number of trials to mark
% trialToMark: Indicates which trial to mark, out of all trials that have the same target number:
%      'first': the first N trials
%      'last': the last N trials
%      'random': N random trials
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
            if strcmpi(trialToMark, 'first')
                i = targetInds(1:n);
            elseif strcmpi(trialToMark, 'last')
                i = targetInds(end-n+1:end);
            elseif strcmpi(trialToMark, 'random')
                tmp = randperm(length(targetInds));
                i = targetInds(tmp(1:n));
            else
                error('Invalid "trialToMark" (%s)', trialToMark);
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

