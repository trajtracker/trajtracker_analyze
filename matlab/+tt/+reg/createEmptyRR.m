function rr = createEmptyRR(platform, setName, varargin)
% rr = createEmptyRR(platform, setName[, maxTarget]) - 
% Create an empty regression-results object for multiple subjects

    rr = struct('general', struct);
    rr.general.setName = setName;
    rr.general.TimeExecuted = datestr(now);
    
    rr.general.Platform = platform;
    switch(platform)
        case 'NL'
            rr.general.MaxTarget = varargin{1};
            
        case 'DC'
            % nothing
            
        otherwise
            error('Unsupported platform "%s"', platform);
    end

end

