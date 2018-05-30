function [thresholdCrossTimes, moreInfo] = findReachThresholdTime(allRR, rrKey, paramName, varargin)
%result = findReachThresholdTime(allRR, rrKey, paramName, ...) -
% Find the first time when the regression b value crosses a certain threshold
% 
% Optional arguments:
% MinB <b> - fixed threshold for b
% MinBPcnt <p> - threshold for b as percentage of asymptote
% AsympTimeRange [from to] - the asymptote value is the average over this
%                        time range
% TimeRange [from to] - look for b threshold only in this time window
% SubjIDs <cell-array> - work on these subject ID's
% IgnoreNotFound - if threshold was not crossed for one subject, ignore it
%                  and set it to none (default behavior: error)
% Last - instead of finding first high-enough b, find the last too-low b
%        (relevant in case of several peaks)

    [subjIDs, getThresholdFunc, timeRange, bType, findLast, ignoreIfNotFound] = parseArgs(varargin, allRR);

    thresholdCrossTimes = [];
    thresholdPerSubj = [];
    
    for iSubj = 1:length(subjIDs)
        subjRR = allRR.(subjIDs{iSubj}).(rrKey);
        threshold = getThresholdFunc(subjRR, paramName);
        
        % Get b values, spline them to 1-ms granularity
        times0 = subjRR.times;
        bVals0 = subjRR.getPredResult(paramName).(bType);
        
        times = times0(1):.0001:times0(end);
        bVals = spline(times0, bVals0, times);
        
        highB = times >= timeRange(1) & times <= timeRange(2) & bVals >= threshold;
        if findLast
            crossInd = find(~highB, 1, 'last');
        else
            crossInd = find(highB, 1);
        end
        if isempty(crossInd)
            if ignoreIfNotFound
                crossInd = NaN;
            else
                error('Threshold %.3f was not crossed the time range %.3f - %3.f (subj=%s)', threshold, timeRange(1), timeRange(2), subjIDs{iSubj});
            end
        end
        
        thresholdPerSubj = [thresholdPerSubj threshold]; %#ok<*AGROW>
        thresholdCrossTimes = [thresholdCrossTimes times(crossInd)]; 
        
    end
    
    moreInfo = struct;
    moreInfo.subjIDs = subjIDs;
    moreInfo.thresholdPerSubj = thresholdPerSubj;
    
    %---------------------------------------------------------------------
    function threshold = getThresholdPercentage(subjRR, paramName, bType, percent, asymptoteTimeRange)
        
        b = subjRR.getPredResult(paramName).(bType);
        
        if isempty(asymptoteTimeRange)
            asymp = b(end);
        else
            goodTimes = subjRR.times >= asymptoteTimeRange(1) & subjRR.times <= asymptoteTimeRange(2);
            if sum(goodTimes) == 0
                error('There are no regressions in the time range %.3f - %3.f', asymptoteTimeRange(1), asymptoteTimeRange(2));
            end
            asymp = mean(b(goodTimes));
        end
        
        threshold = asymp * percent;
        
    end

    %---------------------------------------------------------------------
    function [subjIDs, getThresholdFunc, timeRange, bType, findLast, ignoreIfNotFound] = parseArgs(args, allRR)
        
        subjIDs = tt.reg.listInitials(allRR);
        timeRange = [0 999];
        minB = [];
        minBPercent = [];
        asymptoteTimeRange = [];
        thresholdMethod = '';
        bType = 'b';
        findLast = false;
        ignoreIfNotFound = false;
        
        args = stripArgs(args);
        while ~isempty(args)
            switch(lower(args{1}))
                case 'timerange'
                    timeRange = args{2};
                    args = args(2:end);
                    
                case 'minb'
                    thresholdMethod = 'fixed';
                    minB = args{2};
                    args = args(2:end);
                    
                case 'minbpcnt'
                    thresholdMethod = 'percentage';
                    minBPercent = args{2};
                    args = args(2:end);
                    
                case 'asymptimerange'
                    asymptoteTimeRange = args{2};
                    args = args(2:end);
                    
                case 'subjids'
                    subjIDs = args{2};
                    if ischar(subjIDs)
                        subjIDs = {subjIDs};
                    end
                    args = args(2:end);
                    
                case 'beta'
                    bType = 'beta';
                    
                case 'last'
                    findLast = true;
                    
                case 'ignorenotfound'
                    ignoreIfNotFound = true;
                    
                otherwise
                    error('Unsupported arguement "%s"', args{1})
            end
            
            args = stripArgs(args(2:end));
        end
        
        
        switch(thresholdMethod)
            case 'fixed'
                getThresholdFunc = @(~,~)minB;
                
            case 'percentage'
                getThresholdFunc = @(subjRR, paramName)getThresholdPercentage(subjRR, paramName, bType, minBPercent, asymptoteTimeRange);
                
            case ''
                error('Please specify threshold!');
                
            otherwise
                error('Unknown threshold method (%s)', thresholdMethod);
        end
        
    end

end

