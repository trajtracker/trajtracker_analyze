function c = trialFileMandatoryColumns(platform)
% cols = trialFileMandatoryColumns(platform) - return the mandatory columns
% in the trials file

    c = {'SubSession' 'trialNum' 'status' 'target' 'MovementTime' 'TimeInSession' ...
        'TimeUntilFingerMoved' 'TimeUntilTarget' 'TrajectoryLength'};

    if ismember(upper(platform), {'NL', 'ALL'})
        c = [c {'EndPoint'}];
    end
    
    if ismember(upper(platform), {'DC', 'ALL'})
        c = [c {'UserResponse'}];
    end
    
end

