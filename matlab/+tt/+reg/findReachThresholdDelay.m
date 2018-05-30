function delays = findReachThresholdDelay(allRR, rrKey, paramName, condNames, varargin)
% delays = findReachThresholdDelay(allRR, rrKey, paramName, condNames, ...) -
% Find the first time when the b value crosses a certain threshold, and
% calculate the delay between two conditions
% 
% Optional arguments: see <a href="matlab:help tt.reg.findReachThresholdTime">findReachThresholdTime</a>
% 
% See also <a href="matlab:help tt.reg.findBuildupDelay">tt.reg.findBuildupDelay</a> - another method for finding delay between
% regression parameter pairs.

    n1 = iif(iscell(allRR), length(allRR), 1);
    n2 = iif(iscell(rrKey), length(rrKey), 1);
    n3 = iif(iscell(paramName), length(paramName), 1);
    n = max([n1, n2, n3]);
    if ~iscell(allRR)
        allRR = repmat({allRR}, 1, n);
    end
    if ~iscell(condNames)
        condNames = repmat({condNames}, 1, n);
    end
    if ~iscell(rrKey)
        rrKey = repmat({rrKey}, 1, n);
    end
    if ~iscell(paramName)
        paramName = repmat({paramName}, 1, n);
    end
    
    thresholdTimes = arrayfun(@(i)tt.reg.findReachThresholdTime(allRR{i}, rrKey{i}, paramName{i}, 'SubjIDs', {'avg'}, varargin), 1:n);
    delays = thresholdTimes-thresholdTimes(1);

    for i = 2:length(delays)
        fprintf('[%s] = [%s] %s %d ms\n', condNames{i}, condNames{1}, iif(delays(i) >= 0, '+', '-'), abs(round(1000*delays(i))));
    end
    
end

