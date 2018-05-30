function [result, moreInfo] = findBuildupDelay(allRR, rrKey, paramName, timeRange, varargin)
%result = findBuildupDelay(allRR, rrKey, paramName, ...) -
% Find the delay between two regression lines. The idea is to look at a
% time window when the two regression lines are changing (building up) and
% to find the delay that would minimize the area between the two lines.
% 
% Mandatory arguments:
% allRR, rrKey, paramName - each of these can be either a single value or
%              a cell array with several entries. All entries are compared
%              vs. the first.
% 
% Optional arguments:
% Offset [from to] - the offsets to test
% ScaleByTime [from to] - the asymptote value is the average over this
%                        time range
% TimeRange [from to] - look for b threshold only in this time window
% SubjIDs <cell-array> - work on these subject ID's
% CondName <cell-array> - name of each condition (for printing)
% Print - print results
% 
% See also <a href="matlab:help tt.reg.findReachThresholdDelay">tt.reg.findReachThresholdDelay</a> - another method for finding delay between
% regression parameter pairs.

    INTERPOLATED_DT = 0.001;
    
    [allRR, rrKey, paramName] = fixArgs(allRR, rrKey, paramName);
    [subjIDs, bType, bScalingTimeRange, testedOffsets, condNames, doPrint] = parseArgs(varargin, allRR{1}, length(allRR));

    result = 0;
    
    for i = 2:length(allRR)
        
        d = findDelayBetween(allRR{1}, rrKey{1}, paramName{1}, allRR{i}, rrKey{i}, paramName{i});
        result = [result d];
        
    end
    
    moreInfo = struct;
    moreInfo.subjIDs = subjIDs;
    moreInfo.rrKeys = rrKey;
    moreInfo.paramNames = paramName;
    
    if doPrint
        for i = 2:length(allRR)
            fprintf('[%s] = [%s] %s %d ms\n', condNames{i}, condNames{1}, iif(result(i) >= 0, '+', '-'), abs(round(1000*result(i))));
        end
    end
    
    %---------------------------------------------------------------------
    function delayPerSubj = findDelayBetween(allRR1, rr1Key, param1, allRR2, rr2Key, param2)
        
        delayPerSubj = [];
        
        for iSubj = 1:length(subjIDs)
            rr1 = allRR1.(subjIDs{iSubj}).(rr1Key);
            rr2 = allRR2.(subjIDs{iSubj}).(rr2Key);
            
            times = iif(length(rr1.times) < length(rr2.times), rr1.times, rr2.times);
            b1 = rr1.getPredResult(param1).(bType);
            b2 = rr2.getPredResult(param2).(bType);
            
            % Scale b values
            if ~isempty(bScalingTimeRange)
                b1 = scaleB(b1, rr1.times, bScalingTimeRange);
                b2 = scaleB(b2, rr2.times, bScalingTimeRange);
            end

            % Get the delay
            dd = calcBDelay(times, b1(1:length(times)), b2(1:length(times)), timeRange);
            delayPerSubj = [delayPerSubj dd]; 

        end
        
    end

    %------------------------------------------------
    function b = scaleB(b, t, asymptoteTimeRange)
        
        dt = diff(t(1:2));
        scaleInds = round(asymptoteTimeRange/dt);
        
        if scaleInds(1)<0
            
            asymptote = mean(b(end+scaleInds(1):end+scaleInds(2)));
            
        else
            
            scaleInds = min(scaleInds, length(b));
            asymptote = mean(b(scaleInds(1):scaleInds(2)));
            
        end
        
        b = b / asymptote;
        
    end

    %------------------------------------------------
    function delay = calcBDelay(times0, b1, b2, timeRange)
        
        % Spline b values and times to 1-ms granularity
        times = times0(1):INTERPOLATED_DT:times0(end);
        b1 = spline(times0, b1, times);
        b2 = spline(times0, b2, times);

        % Limit to given time range
        b1Inds = [find(times >= timeRange(1),1) find(times <= timeRange(2), 1, 'last')];
        
        % Find offset that minimizes delta-b
        min_deltaB = 99999999;
        best_offset = [];
        
        for offset = testedOffsets
            deltaB = calc_deltaB(b1, b2, b1Inds, offset);
            if (deltaB < min_deltaB)
                min_deltaB = deltaB;
                best_offset = offset;
            end
        end
        
        delay = best_offset * INTERPOLATED_DT;
        
    end

    %---------------------------------------------------------------------
    function deltaB = calc_deltaB(b1, b2, b1Inds, offset)
        
        b2Inds = b1Inds+offset;
        if b2Inds(1) < 1 || b2Inds(2) > length(b2)
            error('Tested offset is too large');
        end
        
        deltaB = sum(( b1(b1Inds(1):b1Inds(2)) - b2(b2Inds(1):b2Inds(2)) ) .^ 2);
        
    end

    %---------------------------------------------------------------------
    % Make sure that allRR, rrKey, and paramName are all cell arrays of the
    % same length
    function [allRR, rrKey, paramName] = fixArgs(allRR, rrKey, paramName)
        
        if ~iscell(allRR)
            allRR = {allRR};
        end
        if ~iscell(rrKey)
            rrKey = {rrKey};
        end
        if ~iscell(paramName)
            paramName = {paramName};
        end
        
        if length(allRR) == 1 && length(rrKey) == 1 && length(paramName) == 1
            error('You specified only a single regression, regression key, and parameter name');
        end
        
        nEntries = max([length(allRR), length(rrKey), length(paramName)]);
        
        if length(allRR) == 1
            allRR = repmat(allRR, 1, nEntries);
        elseif length(allRR) ~= nEntries
            error('Mismatching lengths of regression, regression keys, and/or param names');
        end
        
        if length(rrKey) == 1
            rrKey = repmat(rrKey, 1, nEntries);
        elseif length(rrKey) ~= nEntries
            error('Mismatching lengths of regression, regression keys, and/or param names');
        end
        
        if length(paramName) == 1
            paramName = repmat(paramName, 1, nEntries);
        elseif length(paramName) ~= nEntries
            error('Mismatching lengths of regression, regression keys, and/or param names');
        end
        
    end

    %---------------------------------------------------------------------
    function [subjIDs, bType, bScalingTimeRange, testedOffsets, condNames, doPrint] = parseArgs(args, allRR, nConds)
        
        subjIDs = tt.reg.listInitials(allRR);
        bType = 'b';
        bScalingTimeRange = [];
        testedOffsets = [];
        condNames = arrayfun(@(i){sprintf('Cond %d',i)}, 1:nConds);
        doPrint = false;
        
        args = stripArgs(args);
        while ~isempty(args)
            switch(lower(args{1}))
                case 'scalebytime'
                    bScalingTimeRange = args{2};
                    args = args(2:end);
                    
                case 'subjids'
                    subjIDs = args{2};
                    if ischar(subjIDs)
                        subjIDs = {subjIDs};
                    end
                    args = args(2:end);
                    
                case 'avg'
                    subjIDs = {'avg'};
                    
                case 'offset'
                    offset_t = args{2};
                    args = args(2:end);
                    if length(offset_t) ~= 2
                        error('Invalid "Offset" argument. Please specify "Offset [<from> <to>]"');
                    end
                    testedOffsets = round(offset_t / INTERPOLATED_DT);
                    testedOffsets = testedOffsets(1) : testedOffsets(2);
                    
                case 'condnames'
                    condNames = args{2};
                    args = args(2:end);
                    
                case 'print'
                    doPrint = true;
                    
                case 'beta'
                    bType = 'beta';
                    
                otherwise
                    error('Unsupported arguement "%s"', args{1})
            end
            
            args = stripArgs(args(2:end));
        end
        
        if isempty(testedOffsets)
            error('You must specify offsets to test');
        end
        
        testedOffsets = round(testedOffsets);
        
    end

end

