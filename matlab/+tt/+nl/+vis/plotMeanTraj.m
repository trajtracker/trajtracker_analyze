function plotMeanTraj(expData, varargin)
%plotMeanTraj(expData, ...) - plot mean trajectory per target
%
% Optional arguments:
% -------------------
% Targets <array>: target numbers for which trajectories are plotted
% LabeledTargets <array>: target numbers to print on top
% Display <mode> : print formats - std/print/small
% Title <text> : title to show (for display mode = std)
% XTick : The delta between 2 subsequent x ticks
% HLines <type> : Determine how to show horizontal lines (connect identical times)
%       None : don't show
%       Abs  : connect identical absolute times
%       Norm : connect identical normalized times
% HTick : determine tick size for HLines (specified in seconds / % time)
% HColor : the color of HLines
% RescaleY: rescale the Y coordinates so that trajectories end exactly at
%           the top of the graph
% AxisFontSize: gca.FontSize
% WinSize [width height]: set figure window size

    DISPLAY_MODE_STANDARD = 0;
    DISPLAY_MODE_PRINT = 1;
    DISPLAY_MODE_PRINT_SMALL = 2;
    
    HLINES_NONE = 0;
    HLINES_ABS = 1;
    HLINES_NORM = 2;
    
    [createNormTraj, targetsToShow, titleText, xTickSize, hLinesType, hLinesTick, hLineColor, ...
        targetNumbersToPrint, stretchY, topY, textYCoord, textFontSize, axisFontSize, ...
        lineWidth, winSize, xLim] = parseArgs(varargin, expData);
    
    if isempty(expData.AvgTrialsNorm)
        if createNormTraj
            tt.preprocess.createAverageTrials(expData, 'Norm');
        else
            error('The given expData has no mean trajectories (expData.AvgTrialsNorm). Please create them or rerun the function with a "CreateNorm" flag if you want me to create them for you.');
        end
    end
    
    validTargets = arrayfun(@(t)~isempty(expData.AvgTrialsNorm(t+1).Trajectory), targetsToShow);
    targetsToShow = targetsToShow(validTargets);
    
    clf;
    hold on;

    drawTrajectories(expData, targetsToShow, targetNumbersToPrint, lineWidth, textYCoord, textFontSize);
    
    if (hLinesType ~= HLINES_NONE)
        drawHLines(expData, targetsToShow, hLinesType, hLinesTick, hLineColor);
    end

    % Title, axes, gridlines
    set(gca, 'YTick', 0:0.2:1);
    set(gca, 'YTickLabel', []);
    
    xTicks = 0:xTickSize:expData.MaxTarget;
    set(gca, 'XLim', xLim);
    set(gca, 'YLim', [0 topY]);
    set(gca, 'XTick', tt.nl.numberToX(xTicks, expData.MaxTarget));
    set(gca, 'XTickLabel', arrayfun(@(x){sprintf('%d', x)}, xTicks));
    set(gca, 'TickLength', [0 0]);
    set(gca, 'FontSize', axisFontSize);
    set(gca, 'FontName', 'Arial');
    set(gcf, 'Color', 'white');
    grid on;
    box on;

    if ~isempty(titleText), title(titleText, 'FontSize', 24, 'FontWeight', 'bold'); end
    setFigWindowSize(winSize);
    
    %------------------------------------------------
    function drawTrajectories(expData, targetsToShow, targetNumbersToPrint, lineWidth, textYCoord, textFontSize)
        
        colors = getColors(length(targetsToShow));
        targetXCoords = -tt.nl.MaxLogicalXValue : (tt.nl.MaxLogicalXValue*2/expData.MaxTarget) : tt.nl.MaxLogicalXValue;

        maximalExistingY = max(arrayfun(@(t)t.Trajectory(end,TrajCols.Y), expData.AvgTrialsNorm(targetsToShow+1)));
        yStretchFactor = iif(stretchY, 1/maximalExistingY, 1);
            
        colorInd = 0;
        for target = targetsToShow
            colorInd = colorInd+1;

            traj = expData.AvgTrialsNorm(target+1).Trajectory;
            % traj = expData.AvgTrialsAbs(target+1).NormalizedTrajectory;

            % Draw the trajectory
            if (target > 0 && target < expData.MaxTarget && mod(target,10)==0)
                h = plot(traj(:,TrajCols.X), traj(:,TrajCols.Y)*yStretchFactor, 'LineStyle', '--');
            else
                h = plot(traj(:,TrajCols.X), traj(:,TrajCols.Y)*yStretchFactor);
            end
            set(h, 'Tag', sprintf('target=%d', target), 'Color', colors{colorInd}, 'LineWidth', lineWidth);

            if ismember(target, targetNumbersToPrint)
                % Connect the end of trajectory with the target number, using
                % a dotted line
                connX = [traj(end,TrajCols.X), targetXCoords(target+1)];
                connY = [1 textYCoord-0.01];
                plot(connX, connY, 'Color', colors{colorInd}, 'LineStyle', ':', 'LineWidth', lineWidth);

                % Write target number
                text(targetXCoords(target+1), textYCoord, sprintf('%2d',target), 'Color', colors{colorInd}, 'HorizontalAlignment', 'center', 'FontSize', textFontSize, 'FontName', 'Arial');
            end

        end
    end
    
    

    %------------------------------------------------
    function drawHLines(expData, targetsToShow, hLinesType, hLinesTick, hLineColor)
        
        trials = expData.AvgTrialsNorm(targetsToShow+1);
        longestTrial = tt.util.getLongestTrial(trials);
        
        switch(hLinesType)
            case HLINES_ABS
                maxTime = longestTrial.Trajectory(end, TrajCols.AbsTime);
                hLines = arrayfun(@(t){getHLineCoordsAbs(t, trials, longestTrial)}, hLinesTick:hLinesTick:maxTime);
                hLineDesc = arrayfun(@(t){sprintf('%d', round(t*1000))}, hLinesTick:hLinesTick:maxTime);
                
            case HLINES_NORM
                hLines = arrayfun(@(t){getHLineCoordsNorm(t, trials, longestTrial)}, hLinesTick:hLinesTick:1 );
                hLineDesc = arrayfun(@(t){sprintf('%d%%', round(t*100))}, hLinesTick:hLinesTick:1);
                
            otherwise
                error('Unsupported HLines type');
        end
        
        for i = 1:length(hLines)
            
            % Line
            line = hLines{i};
            plot(line(:, 1), line(:, 2), 'color', hLineColor);
            
            % Text
            textCoord = line(1, :) - [.02 .02];
            plot([textCoord(1), line(1,1)], [textCoord(2), line(1,2)], 'color', mycolors.grey, 'LineStyle', ':');
            text('String', hLineDesc{i}, 'FontSize', textFontSize, 'Color', mycolors.grey, ...
                 'HorizontalAlignment', 'right', 'Position', textCoord);
            
        end
        
    end

    %------------------------------------------------
    % Get coordinates of a single horizontal line in one point
    % (absolute time)
    function coords = getHLineCoordsAbs(absTime, trials, longestTrial)
        
        row = find(longestTrial.Trajectory(:, TrajCols.AbsTime) >= absTime, 1);
        if isempty(row)
            error('Time %f not found!', absTime);
        end
        
        coords = getHLineCoords(row, trials);
        
    end
    
    
    %------------------------------------------------
    % Get coordinates of a single horizontal line in one point
    % (normalized time)
    function coords = getHLineCoordsNorm(normTime, trials, longestTrial)
        
        row = find(longestTrial.Trajectory(:, TrajCols.NormTime) >= normTime, 1);
        if isempty(row)
            error('Time %f not found!', absTime);
        end
        
        coords = getHLineCoords(row, trials);
        
    end
    
    
    %------------------------------------------------
    % Get coordinates of a single horizontal line in one point
    % (normalized time)
    function coords = getHLineCoords(row, trials)
        
        coords = NaN(length(trials), 2);
        for i = 1:length(trials)
            coords(i, 1) = trials(i).Trajectory(row, TrajCols.X);
            coords(i, 2) = trials(i).Trajectory(row, TrajCols.Y);
        end
        
        [~,i] = sort(coords(:,1));
        coords = coords(i, :);
        
    end
    
    
    %------------------------------------------------
    function colors = getColors(nTargets)
        
        if (nTargets == expData.MaxTarget+1)
            
            colors = tt.nl.vis.targetColorScale(nTargets-1);
            
        else
            
            tmp = varycolor(nTargets);
            colors = cell(1,nTargets);
            for i = 1:nTargets
                colors{i} = tmp(i,:);
            end
            
        end
        
    end

    %--------------------------------------------
    function [createNormTraj, targetsToShow, titleText, xTickSize, hLinesType, ...
              hLinesTick, hLineColor, targetNumbersToPrint, stretchY, topY, ...
              textYCoord, textFontSize, axisFontSize, lineWidth, windowSize, xLim] = parseArgs(args, expData)
        
        createNormTraj = false;
        targetsToShow = 0:expData.MaxTarget;
        targetsToShowChanged = false;
        displayMode = DISPLAY_MODE_STANDARD;
        titleText = '';
        xTickSize = 10;
        hLinesType = HLINES_NONE;
        hLinesTick = [];
        hLineColor = mycolors.grey;
        targetNumbersToPrint = [];
        stretchY = false;
        topY = 1.1;
        textFontSize = [];
        textYCoord = [];
        axisFontSize = [];
        lineWidth = [];
        windowSize = [];
        xLim = [-1 1] * tt.nl.MaxLogicalXValue * 1.05;
        
        args = stripArgs(args);
        
        while ~isempty(args)
            
            switch(lower(args{1}))
                case 'createtraj'
                    createNormTraj = true;
                    
                case 'targets'
                    targetsToShow = args{2};
                    args = args(2:end);
                    targetsToShowChanged = true;
                    
                case 'labeledtargets'
                    targetNumbersToPrint = args{2};
                    args = args(2:end);
                    
                case 'display'
                    switch(lower(args{2}))
                        case 'std'
                            displayMode = DISPLAY_MODE_STANDARD;

                        case 'print'
                            displayMode = DISPLAY_MODE_PRINT;

                        case 'small'
                            displayMode = DISPLAY_MODE_PRINT_SMALL;

                        otherwise
                            error('Invalid displayMode: %s', args{2});
                    end
                    args = args(2:end);
                    
                case 'title'
                    titleText = args{2};
                    args = args(2:end);
                    
                case 'xtick'
                    xTickSize = args{2};
                    args = args(2:end);
                    
                case 'hlines'
                    switch(lower(args{2}))
                        case 'none'
                            hLinesType = HLINES_NONE;
                        case 'abs'
                            hLinesType = HLINES_ABS;
                        case 'norm'
                            hLinesType = HLINES_NORM;
                        otherwise
                            error('Invalid "HLines" value: %s', args{2});
                    end
                    args = args(2:end);
                
                case 'htick'
                    hLinesTick = args{2};
                    args = args(2:end);
                    
                case 'hcolor'
                    hLineColor = args{2};
                    args = args(2:end);
                    
                case 'rescaley'
                    stretchY = true;
                    
                case 'axisfontsize'
                    axisFontSize = args{2};
                    args = args(2:end);
                    
                case 'winsize'
                    windowSize = args{2};
                    if ~isempty(windowSize)
                        if length(windowSize) ~= 2 || sum(windowSize<0) > 0 || sum(windowSize>1) > 0
                            error('Invalid "WinSize" argument! Specify [x,y] percentage of screen size');
                        end
                    end
                    args = args(2:end);
                    
                case 'xlim'
                    xLim = tt.nl.numberToX(args{2}, expData.MaxTarget);
                    args = args(2:end);
                    
                otherwise
                    args{1} %#ok<NOPRT>
                    error('Unknown argument');
            end
            
            args = stripArgs(args(2:end));
        
        end
        
        if isempty(hLinesTick)
            switch(hLinesType)
                case HLINES_ABS
                    hLinesTick = .2; % 200 ms
                case HLINES_NORM
                    hLinesTick = .1; % 10 percent
            end
        end
        
        if isempty(targetNumbersToPrint)
            if (displayMode == DISPLAY_MODE_STANDARD || targetsToShowChanged)
                targetNumbersToPrint = targetsToShow;
            else
                targetNumbersToPrint = targetsToShow(1:2:end);
            end
        elseif ischar(targetNumbersToPrint) && strcmp(targetNumbersToPrint, 'none')
            targetNumbersToPrint = [];
            topY = 1;
        end
        
        if isempty(textFontSize)
            textFontSize = choose(displayMode+1, 14, 32, 32);
        end
        if isempty(textYCoord)
            textYCoord = choose(displayMode+1, topY-.05, topY-.03, topY-.03);
        end
        if isempty(axisFontSize)
            axisFontSize = choose(displayMode+1, 16, 40, 40);
        end
        if isempty(lineWidth)
            lineWidth = choose(displayMode+1, 1, 2, 2);
        end
        
    end
    
end
