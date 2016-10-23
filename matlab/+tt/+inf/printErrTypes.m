function [nErrsPerTarget, targets, errTargets] = printErrTypes(allExpData)
%[nErrsPerTarget, targets, errTargets] = printErrTypes(allExpData) - 
% print error types and return the no. of errors per target

    allInitials = tt.inf.listInitials(allExpData);

    errTrials = [];
    for ini = allInitials
        expData = allExpData.(ini{1});
        isErr = arrayfun(@(t)t.ErrCode ~= TrialErrCodes.OK && t.ErrCode ~= TrialErrCodes.Outlier, expData.Trials);
        errTrials = [errTrials expData.Trials(isErr)]; %#ok<AGROW>
    end
    
    trialErrCodes = arrayfun(@(t)t.ErrCode, errTrials);
    errCodes = unique(trialErrCodes);
    
    allErrs = TrialErrCodes.getAllErrCodes();
    for code = errCodes
        errName = allErrs.(sprintf('e%d', code));
        fprintf('Error #%d (%s): %d trials (%.1f%%)\n', code, errName, sum(trialErrCodes==code), sum(trialErrCodes==code)/length(trialErrCodes)*100);
    end
    
    fprintf('\nTotal of %d errors for %d subjects\n', length(trialErrCodes), length(allInitials));
    
    targets = 0:allExpData.(allInitials{1}).MaxTarget;
    errTargets = arrayfun(@(t)t.Target, errTrials);
    nErrsPerTarget = arrayfun(@(target)sum(errTargets==target), targets);

end

