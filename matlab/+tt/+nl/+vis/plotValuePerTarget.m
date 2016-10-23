function [data, meanData, seData] = plotValuePerTarget(varargin)
% plotValuePerTarget(...) - plot some value per target number. The plotted value
% is the average of per-subject values.
% The function can plot one line per condition, and also plot the value
% with several smoothing levels (one line per smoothing).
% 
% Mandatory arguments:
% --------------------
% specify the data to plot. This can be done in 2 ways:
%
% (1) Prepare your data, then call this function:
% DataPerSubj <matrix> - the data to plot: subjects x targets x conditions
% MaxTarget <#> - the maximal target value (mandatory for this API)
% 
% (2) Let the function organize the data for you:
% ExpData <struct/cell> - struct with multi-subject data; or cell array with 
%                    one struct per condition.
% And specify one of the following:
% GetSubjValue @(subj,targets)->array: Get value per subject and target
% GetTrialValue @(trial,expData)->number: get value per trial
% TrialAttr <attr-name> - use trial.attr
% CustomAttr <attr-name> - use trial.Custom.attr
% 
% Optional arguments:
% -------------------
% TrialFilter <filter-function>: filter trials. See <a href="matlab:help tt.util.filterTrials">tt.util.filterTrials</a>
%                Ignored when using the "Data" or "GetSubjValue" arguments.
% GroupNTargets <N>: group each N adjacent targets together
% LRDiff: plot difference between the values in the left and right halves
%         of the number line (StdErr = mean)
% StdErr - plot error bars
% CondNames <cell-array> - specify condition names (for legend)
% Title <text> - title for graph
% YLabel <text> 
% YLim [min max]
% XTick <t>: delta for x ticks
% Smooth <factors>: plot data using each of the given smooth factors
% OnlySmoothed: don't plot the unsmoothed data
% Color <cell-array>: colors per line
% Linestyle <cell-array>
% ColorSrc Fixed|Cond|Smooth: how to determine the color per line - 
%           fixed color, color by condition, or by smoothing factor.
% LineSrc Fixed|Cond|Smooth: how to determine the line style.
    
    
    [data, allExpData, getSubjValueFunc, addPerCond, targets, transformMeansFunc, ...
        plotStdErr, condNames, chartLabels, yLim, xTick, yTickDelta, ...
        smoothFactors, colors, colorSrc, lineStyles, lineStyleSrc, winSize] = parseArgs(varargin);

    %-- Get data
    if isempty(data)
        data = getData(allExpData, getSubjValueFunc, targets);
    end
    
    nSubjects = size(data, 1);
    nConds = size(data, 3);
    
    %-- Get mean and SD over subjects
    
    meanData = NaN(length(targets), nConds);
    seData = NaN(length(targets), nConds);
    for iCond = 1:nConds
        meanData(:, iCond) = nanmean(data(:, :, iCond)) + addPerCond(iCond);
        seData(:, iCond) = nanstd(data(:, :, iCond)) / sqrt(nSubjects);
    end
    
    if ~isempty(transformMeansFunc)
        [meanData, seData, targets] = transformMeansFunc(meanData, seData, targets);
    end
    
    %-- Plot
    
    clf;
    hold on;
    
    iColor = 0;
    
    for iCond = 1:nConds
        iColor = iColor + 1;
        
        for iSmooth = 1:length(smoothFactors)
            smoothFactor = smoothFactors{iSmooth};
            
            if isempty(smoothFactor)
                valuePerTarget = meanData(:, iCond);
            else
                valuePerTarget = smoothg(meanData(:, iCond), smoothFactor);
            end

            switch(colorSrc)
                case 'cond'
                    color = colors{iCond};
                case 'smooth'
                    color = colors{iSmooth};
                case 'fixed'
                    color = colors{1};
            end
            
            switch(lineStyleSrc)
                case 'cond'
                    lineStyle = lineStyles{iCond};
                case 'smooth'
                    lineStyle = lineStyles{iSmooth};
                case 'fixed'
                    lineStyle = lineStyles{1};
            end
            
            plot(targets, valuePerTarget, 'Color', color, 'LineWidth', 4, 'LineStyle', lineStyle);
            if (plotStdErr)
                se = seData(:, iCond);
                h = area(targets, [valuePerTarget-se, se*2], 'EdgeAlpha', 0, 'HandleVisibility', 'off');
                h(1).FaceAlpha = 0;
                h(2).FaceAlpha = 0.15;
                h(2).FaceColor = color;
            end

        end
        
    end
    
    grid on;
    set(gca, 'FontSize', 40);
    set(gcf, 'color', 'white');
    
    if ~isempty(chartLabels.title), title(chartLabels.title); end
    if ~isempty(chartLabels.x), xlabel(chartLabels.x); end
    if ~isempty(chartLabels.y), ylabel(chartLabels.y, 'Rotation', 0, 'HorizontalAlignment', 'Left'); end
    
    xlim([-1 max(targets)+1]);
    if ~isempty(yLim), ylim(yLim); end
    
    set(gca, 'XTick', 0:xTick:max(targets));
    if ~isempty(yTickDelta), setTickDelta('y', yTickDelta); end
    
    if ~isempty(condNames), legend(condNames); end
    
    setFigWindowSize(winSize);
    
    %-------------------------------------------
    function data = getData(allExpData, getSubjValueFunc, targets)
        
        nConditions = length(allExpData);
        subjIDs = tt.inf.listInitials(allExpData{1});
        
        data = NaN(length(subjIDs), length(targets), nConditions);
        
        for ic = 1:nConditions
            for iSubj = 1:length(subjIDs)
                oneSubjData = getSubjValueFunc(allExpData{ic}.(subjIDs{iSubj}), targets);
                data(iSubj, :, ic) = reshape(oneSubjData, 1, length(targets));
            end
        end
        
    end

    %-------------------------------------------
    function dataPerTarget = getSubjValueFromTrials(expData, targets, getTrialValueFunc, trialFilters)
        
        trials = tt.util.filterTrials(expData, trialFilters);
        valuePerTrial = arrayfun(getTrialValueFunc, trials);
        targetPerTrial = arrayfun(@(t)t.Target, trials);
        
        dataPerTarget = arrayfun(@(target)nanmean(valuePerTrial(targetPerTrial==target)), targets);
        
    end
    
    %----------------------------------------------------------------
    function [meanData, seData, targets] = transformToLRDiff(meanData, seData, targets)
        
        nTargets = size(meanData, 1);
        if mod(nTargets, 2) == 0
            midInd = floor(nTargets/2);
            meanData = meanData((midInd+1):end) - meanData(midInd:-1:1);
            seData = (seData((midInd+1):end) + seData(midInd:-1:1)) / 2;
        else
            midInd = ceil(nTargets/2);
            meanData = meanData((midInd+1):end) - meanData((midInd-1):-1:1);
            seData = (seData((midInd+1):end) + seData((midInd-1):-1:1)) / 2;
        end
        
        targets = targets((midInd+1):end);
        
    end

    %----------------------------------------------------------------
    % Group some targets together
    function [meanDataNew, seDataNew, targetsNew] = transformGroupTargets(meanData, seData, targets, targetsPerGroup)
        
        nSubj = size(meanData, 2);
        
        meanDataNew = NaN(length(targetsPerGroup), nSubj);
        seDataNew = NaN(length(targetsPerGroup), nSubj);
        targetsNew = NaN(1, length(targetsPerGroup));
        
        for iGrp = 1:length(targetsPerGroup)
            grpTargets = targetsPerGroup{iGrp};
            grpTargetInds = arrayfun(@(t)find(targets==t), grpTargets);
            targetsNew(iGrp) = mean(targets(grpTargetInds));
            
            meanDataNew(iGrp, :) = mean(meanData(grpTargetInds, :));
            seDataNew(iGrp, :) = mean(seData(grpTargetInds, :));
        end
        
    end


    %-------------------------------------------
    function [data, allExpData, getSubjValueFunc, addPerCond, targets, transformMeansFunc, ...
        plotSE, condNames, chartLabels, yLim, xTick, yTickDelta, ...
        smoothFactors, colors, colorSrc, lineStyles, lineStyleSrc, winSize] = parseArgs(args)

        data = [];
        allExpData = [];
        getSubjValueFunc = [];
        trialFilters = {};
        addPerCond = []; % fix later
        
        transformMeansFunc = [];
        plotSE = false;
        condNames = {};
        chartLabels = struct('title', '', 'x', 'Target', 'y', '');
        yLim = [];
        xTick = 5;
        yTickDelta = [];
        smoothFactors = {};
        plotUnsmoothed = true;
        colors = {'black', 'blue', 'red', mycolors.darkgreen, mycolors.purple, 'cyan'};
        colorSrc = 'cond';
        lineStyles = {'-', '--'};
        lineStyleSrc = 'fixed';
        groupSize = [];
        targets = [];
        winSize = [];
        
        args = stripArgs(args);
        while ~isempty(args)
            switch(lower(args{1}))
                case 'data'
                    data = args{2};
                    args = args(2:end);

                case 'expdata'
                    allExpData = args{2};
                    args = args(2:end);
                    if isstruct(allExpData), allExpData = {allExpData};  end
                    
                case 'getsubjvalue'
                    getSubjValueFunc = args{2};
                    if nargin(getSubjValueFunc) ~= 2
                        error('Invalid "GetSubjValue" function: expecting @(expData, targets) -> value');
                    end
                    args = args(2:end);
                    
                case 'gettrialvalue'
                    getTrialValueFunc = args{2};
                    args = args(2:end);
                    
                case 'trialattr'
                    attrName = args{2};
                    args = args(2:end);
                    getTrialValueFunc = @(trial)trial.(attrName);
                    
                case 'customattr'
                    attrName = args{2};
                    args = args(2:end);
                    getTrialValueFunc = @(trial)trial.Custom.(attrName);
                    
                case 'trialfilter'
                    trialFilters = [trialFilters args(2)]; %#ok<AGROW>
                    args = args(2:end);
                    
                case 'addpercond'
                    addPerCond = args{2};
                    args = args(2:end);
                    
                case 'lrdiff'
                    if ~isempty(transformMeansFunc)
                        error('You cannot specify two transformation methods');
                    end
                    transformMeansFunc = @transformToLRDiff;
                    
                case 'groupntargets'
                    if ~isempty(transformMeansFunc)
                        error('You cannot specify two transformation methods');
                    end
                    transformMeansFunc = 1; % dummy value, so the double-definition error will work
                    groupSize = args{2};
                    args = args(2:end);
                    
                case 'stderr'
                    plotSE = true;
                    
                case 'condnames'
                    condNames = args{2};
                    args = args(2:end);
                    
                case 'title'
                    chartLabels.title = args{2};
                    args = args(2:end);
                    
                case 'xlabel'
                    chartLabels.x = args{2};
                    args = args(2:end);
                    
                case 'ylabel'
                    chartLabels.y = args{2};
                    args = args(2:end);
                    
                case 'nolabels'
                    chartLabels.x = '';
                    
                case 'ylim'
                    yLim = args{2};
                    args = args(2:end);
                    
                case 'xtick'
                    xTick = args{2};
                    args = args(2:end);
                    
                case 'ytick'
                    yTickDelta = args{2};
                    args = args(2:end);
                    
                case 'color'
                    colors = args{2};
                    args = args(2:end);
                    
                case 'linestyle'
                    lineStyles = args{2};
                    args = args(2:end);
                    
                case 'smooth'
                    smoothFactors = [smoothFactors args(2)]; %#ok<AGROW>
                    args = args(2:end);
                    
                case 'onlysmoothed'
                    plotUnsmoothed = false;
                    
                case 'colorsrc'
                    colorSrc = lower(args{2});
                    args = args(2:end);
                    if ~ismember(colorSrc, {'cond', 'smooth', 'fixed'})
                        error('Invalid "ColorSrc" (%s): specify Cond, Smooth, or fixed!', colorSrc);
                    end
                    
                case 'linesrc'
                    lineStyleSrc = lower(args{2});
                    args = args(2:end);
                    if ~ismember(lineStyleSrc, {'cond', 'smooth', 'fixed'})
                        error('Invalid "ColorSrc" (%s): specify Cond, Smooth, or fixed!', lineStyleSrc);
                    end
                    
                case 'winsize'
                    winSize = args{2};
                    args = args(2:end);
                    
                otherwise
                    error('Unsupported argument "%s"!', args{1});
            end
            args = stripArgs(args(2:end));
        end

        if isempty(targets)
            if isempty(data)
                anyED = tt.util.structToArray(allExpData{1}); 
                maxTarget = anyED(1).MaxTarget;
            else
                maxTarget = size(data, 2) - 1;
            end
            targets = 0:maxTarget;
        end
        
        %-- Group adjacent targets together
        if ~isempty(groupSize)
            % Get the first target number per group, separately for
            % left/right halves of the number line
            target1Left = 0:groupSize:(maxTarget/2 - groupSize);
            lastTargetRight = maxTarget - target1Left;
            lastTargetRight = lastTargetRight(length(lastTargetRight):-1:1); % reverse order
            target1Right = lastTargetRight-groupSize+1;

            %-- Find target numbers in each group
            targetsPerGroup = arrayfun(@(target1){target1 + (0:groupSize-1)}, [target1Left target1Right]);
            
            transformMeansFunc = @(a,b,c)transformGroupTargets(a,b,c,targetsPerGroup);
        end
        
        if isempty(addPerCond)
            nConditions = iif(isempty(data), length(allExpData), size(data, 3));
            addPerCond = zeros(1, nConditions);
        end
        
        if plotUnsmoothed, smoothFactors = [{[]}, smoothFactors]; end
        
        if isempty(data) && isempty(allExpData)
            error('You must specify either "Data" or "ExpData"');
        elseif ~isempty(data) && ~isempty(allExpData)
            error('You cannot specify both "Data" and "ExpData"');
        end
        
        if ~isempty(allExpData)
            if isempty(getSubjValueFunc) && isempty(getTrialValueFunc)
                error('You must specify either "GetSubjValue" or how to get a trial value');
            elseif ~isempty(getSubjValueFunc) && ~isempty(getTrialValueFunc)
                error('You cannot specify both "GetSubjValue" and how to get a trial value');
            end
            if isempty(getSubjValueFunc)
                getSubjValueFunc = @(expData, targets)getSubjValueFromTrials(expData, targets, getTrialValueFunc, trialFilters);
            elseif ~isempty(trialFilters)
                fprintf('plotPerTarget() WARNING: trial filters will be ignored\n');
            end
        end
        
    end

end

