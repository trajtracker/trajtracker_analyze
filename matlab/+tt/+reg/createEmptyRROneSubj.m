function rr = createEmptyRROneSubj(varargin)
% createEmptyRROneSubj - Create a struct that keeps results of several 
% regressions for one subject
% 
% Usage formats:
% rr = createEmptyRROneSubj(subjInitials, subjName, samplingRate[, timeExecuted])
% rr = createEmptyRROneSubj(existingRR)

    rr = struct;
    
    switch length(varargin)
        case 1
            x = varargin{1};
            rr.SubjectInitials = x.SubjectInitials;
            rr.SubjectName = x.SubjectName;
            rr.SamplingRate = x.SamplingRate;
            rr.TimeExecuted = x.TimeExecuted;
            for fld = {'MaxMovementTime', 'MaxTarget'}
                if isfield(x, fld{1})
                    rr.(fld{1}) = x.(fld{1});
                end
            end

        case 3
            rr.SubjectInitials = varargin{1};
            rr.SubjectName = varargin{2};
            rr.SamplingRate = varargin{3};
            rr.TimeExecuted = datestr(now);

        case 4
            rr.SubjectInitials = varargin{1};
            rr.SubjectName = varargin{2};
            rr.SamplingRate = varargin{3};
            rr.TimeExecuted = varargin{4};

        otherwise

    end
    
end

