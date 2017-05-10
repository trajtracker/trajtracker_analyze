function c = trialFileMandatoryColumns(platform)
% cols = trialFileMandatoryColumns(platform) - return the mandatory columns
% in the trials file

    c = {'trialNum' 'status' 'target' 'MovementTime' 'TimeInSession' 'TimeUntilFingerMoved' 'TimeUntilTarget'};

    if ismember(upper(platform), {'NL', 'ALL'})
        c = [c {'EndPoint'}];
    end
    
    if ismember(upper(platform), {'DC', 'ALL'})
        c = [c {'UserResponse'}];
    end
    
end

