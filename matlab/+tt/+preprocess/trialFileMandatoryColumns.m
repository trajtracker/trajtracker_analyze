function [mandatoryCols, defaultCols] = trialFileMandatoryColumns(platform)
% cols = trialFileMandatoryColumns(platform) - return the mandatory columns
% in the trials file

    mandatoryCols = {'trialNum' 'status' 'target' 'MovementTime' 'TimeInSession' 'TimeUntilFingerMoved' 'TimeUntilTarget'};
    defaultCols = {'PresentedTarget', 'Tag', 'nl_position_x'};
    
    if ismember(upper(platform), {'NL', 'ALL'})
        mandatoryCols = [mandatoryCols {'EndPoint'}];
    end
    
    if ismember(upper(platform), {'DC', 'ALL'})
        mandatoryCols = [mandatoryCols {'UserResponse'}];
    end
    
end

