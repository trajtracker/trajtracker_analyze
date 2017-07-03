function [data, extraInf] = getTrajectoryValues(inData, varargin)
% [data, extraInf] = getTrajectoryValues(inData, ...) - 
% Extract data from trial trajectories and return it as matrix.
% The function can also average values of trial groups.
% 
% Input arguments:
% ================
% inData: expData or dataset
% 
% Returns:
% ========
% data - data matrix with one row per time point, one column per trial or
%        trial group.
% extraInf - a struct with these fields:
%   times - the time points (one per row in 'data')
%   groupNums - the group numbers (one per column in 'data')
%   nTimePointsPerGroup - the number of valid time points per group
% 
% Optional Arguments:
% ===================
% TrajCol <name> : Trajectory column to plot
% GetValueFunc @(trial, expData, times, rowNums)->number : Get the values
%        to plot. Function should return a column vector.
% TrajCol TrajCols.###: Instead of 'GetValueFunc', use a value from the
%        trajectory matrix.
% GrpFunc <func>: a function that groups trials. Trials with the same 
%        group number are grouped together, the average value 
%        per group will be returned.
%        Possible function signatures:
%        - @(trial)->integer
%        - @(trial,expData)->integer
%        - @(trial,expData,datasetNum)->integer - this is relevant
%          when "inData" is a cell array (e.g., multiple conditions).
%          The 3rd argument is the index in the cell array.
%        Instead of a function, you can also specify a string, which refers
%        to one of several predefined grouping functions:
%        - 'Target': group by trial.Target
%        - 'Dataset': when "inData" is cell array, group by entry
% GrpAll: group all trials together (return an average of all of them)
% TrialFilter @(trial[, expData])->BOOL : trial filtering function

    [trials, ~, edPerTrial, ~, dsNumPerTrial] = tt.util.getAllTrials(inData);
    
    [getValueFunc, groupingFunc, extrapolate, trialFilters, minTime, maxTime, dt, smoothSD] = parseArgs(varargin, edPerTrial(1).SamplingRate);

    extraInf = struct;
    
    %-- Get trials
    if maxTime < 0
        trialFilters = [trialFilters {@(t)t.MovementTime > -maxTime}];
    end
    [trials, inds] = tt.util.filterTrialList(trials, trialFilters);
    edPerTrial = edPerTrial(inds);

    %-- Group trials
    if isempty(groupingFunc)
        grpPerTrial = 1:length(trials);
    elseif nargin(groupingFunc) == 1
        grpPerTrial = arrayfun(groupingFunc, trials);
    elseif nargin(groupingFunc) == 2
        grpPerTrial = arrayfun(@(i)groupingFunc(trials(i), edPerTrial(i)), 1:length(trials));
    elseif nargin(groupingFunc) == 3
        grpPerTrial = arrayfun(@(i)groupingFunc(trials(i), edPerTrial(i), dsNumPerTrial(i)), 1:length(trials));
    else
        error('Invalid grouping function: %s\n', char(groupingFunc));
    end
    groups = unique(grpPerTrial);

    %-- Find row numbers
    longestTrial = tt.util.getLongestTrial(trials);
    if maxTime >= 0

        maxTime = min(maxTime, longestTrial.Trajectory(end, TrajCols.AbsTime));

        if isempty(dt)
            rows = 1:longestTrial.NTrajSamples;
            times = minTime:edPerTrial(1).SamplingRate:maxTime;
        else
            times = minTime:dt:maxTime;
            rows = arrayfun(@(t)find(longestTrial.Trajectory(:, TrajCols.AbsTime) >= t, 1), times-0.0001); % The "0.0001" term is to cope with small numeric inaccuracies
        end

        maxNRowsFromEnd = 0;
        
    else
        
        absMaxTime = longestTrial.Trajectory(end, TrajCols.AbsTime) + maxTime;
        
        if isempty(dt)
            rows = 1:longestTrial.NTrajSamples;
            times = minTime:edPerTrial(1).SamplingRate:absMaxTime;
        else
            times = minTime:dt:absMaxTime;
            rows = arrayfun(@(t)find(longestTrial.Trajectory(:, TrajCols.AbsTime) >= t, 1), times-0.0001); % The "0.0001" term is to cope with small numeric inaccuracies
        end
        maxNRowsFromEnd = ceil((-maxTime)/edPerTrial(1).SamplingRate);

    end
    
    data = NaN(length(times), length(groups));
    nTimePointsPerGroup = NaN(1, length(groups));
    
    %-- Process one group at a time
    for iGroup = 1:length(groups)
        currGroupTrialInds = find(grpPerTrial == groups(iGroup));
        currGroupData = NaN(length(times), length(currGroupTrialInds));
        
        % Per trial, find the last row to consider. This is the end of the
        % trajectory, and possibly even earlier (if maxTime<0).
        lastValidTP = arrayfun(@(t)find([0 rows] <= t.NTrajSamples-maxNRowsFromEnd, 1, 'last') - 1, trials(currGroupTrialInds));
        
        for i = 1:length(currGroupTrialInds)
            trial = trials(currGroupTrialInds(i));
            v = getValueFunc(trial, edPerTrial(currGroupTrialInds(i)), times(1:lastValidTP(i)), rows(1:lastValidTP(i)));
            currGroupData(1:lastValidTP(i), i) = v;
            if extrapolate
                currGroupData(lastValidTP(i):end, i) = v(end);
            end
        end
        v = nanmean(currGroupData, 2);
        nTimePointsPerGroup(iGroup) = max(lastValidTP);
        extraInf.lastGrpData = currGroupData;
        
        if ~isempty(smoothSD)
            v(1:nTimePointsPerGroup(iGroup)) = smoothg(v(1:nTimePointsPerGroup(iGroup)), smoothSD);
        end
        data(:, iGroup) = v;
        
    end
    
    extraInf.times = times;
    extraInf.groups = groups;
    extraInf.nTimePointsPerGroup = nTimePointsPerGroup;
    

    %-------------------------------------------
    function [getValueFunc, groupingFunc, extrapolate, trialFilters, minTime, maxTime, dt, smoothSD] = parseArgs(args, samplingRate)

        getValueFunc = [];
        groupingFunc = [];
        trialFilters = {};
        minTime = 0;
        maxTime = 99999;
        dt = samplingRate;
        smoothSD = [];
        extrapolate = false;
        
        args = stripArgs(args);
        while ~isempty(args)
            switch(lower(args{1}))
                case 'getvaluefunc'
                    getValueFunc = args{2};
                    args = args(2:end);
                    
                case 'trajcol'
                    colNum = args{2};
                    getValueFunc = @(trial, expData, ~, rowNums)trial.Trajectory(min(rowNums, size(trial.Trajectory, 1)), colNum);
                    args = args(2:end);

                case 'trialfilter'
                    trialFilters = [trialFilters args(2)]; %#ok<AGROW>
                    args = args(2:end);
                    
                case 'grpfunc'
                    groupingFunc = args{2};
                    switch(char(lower(groupingFunc)))
                        case 'target'
                            groupingFunc = @(trial)trial.Target;
                            
                        case 'dataset'
                            groupingFunc = @(~,~,ds)ds;
                            
                        case {'1', 1}
                            groupingFunc = @(~)1;
                    end
                    args = args(2:end);
                    
                case 'grpall'
                    groupingFunc = @(~)1;
                    
                case 'mintime'
                    minTime = args{2};
                    args = args(2:end);
                    
                case 'maxtime'
                    maxTime = args{2};
                    args = args(2:end);
                    
                case 'dt'
                    dt = args{2};
                    args = args(2:end);
                    
                case 'smooth'
                    smoothSD = args{2};
                    args = args(2:end);
                    
                case 'extrapolate'
                    extrapolate = true;
                    
                otherwise
                    error('Unsupported argument "%s"!', args{1});
            end
            args = stripArgs(args(2:end));
        end
        
        if isempty(getValueFunc)
            error('Please specify the value to plot');
        end
        
        if ~isempty(smoothSD)
            smoothSD = smoothSD/dt;
        end

    end

end

