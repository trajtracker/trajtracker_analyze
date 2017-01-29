function meanOverSubjs = plotRecentTrialsEffects(allRR, regName, varargin)
% meanOverSubjs = plotRecentTrialsEffects(allRR, regName, ...) -
% Plot the effects of several recent trials: N-1, N-2, N-3, ...
% Each distance N-x is plotted as one point. The point value is the average
% of b[N-x] over a certain time window.
% 
% Arguments:
% allRR - cell array with one RR struct (all subjects) per condition
% regName - Name of regression to show
% 
% Optional arguments:
% Time [min max] - time range to use for the b values
% NPrev - number of previous trials to plot (from N-1 until N-nprev)
% Colors <cell array> - one color per entry in allRR
% YLim [min max] - 
% StdErr - plot error bars
% NoTitle - don't plot a title

    [plotStdErr, nPrevTrg, timeRange, showTitle, showLabels, seriesColors, yLim, yTickDelta, winSize] = parseArgs(varargin);
    if isstruct(allRR)
        allRR = {allRR};
    end
    
    clf;
    hold on;
    
    for iRR = 1:length(allRR)

        [~, meanVals] = tt.reg.internal.calcPrevTargetEffect(allRR{iRR}, regName, 'nprevtargets', nPrevTrg, 'TimeRange', timeRange);
        meanOverSubjs = mean(meanVals);

        xInds = 1:nPrevTrg;
        if (plotStdErr)
            se = std(meanVals) / sqrt(size(meanVals, 1));
            errorbar(xInds, meanOverSubjs, se, se, 'Color', seriesColors{iRR}, 'LineWidth', 2, 'HandleVisibility', 'off', 'Marker', 'o', 'MarkerSize', 20, 'Color', seriesColors{iRR});
        else
            plot(xInds, meanOverSubjs, 'Color', seriesColors{iRR}, 'LineWidth', 2, 'HandleVisibility', 'off', 'Marker', 'o', 'MarkerSize', 20, 'Color', seriesColors{iRR});
        end

        pGt0 = isGT0(meanVals);
        gt0 = pGt0 <= .05;
        if sum(gt0) > 0
            plot(xInds(gt0), meanOverSubjs(gt0), 'LineStyle', 'None', 'Marker', 'o', 'MarkerSize', 20, 'Color', seriesColors{iRR}, 'MarkerFace', seriesColors{iRR});
        end
%         if (sum(gt0) > 0)
%             plot(xInds(~gt0), meanOverSubjs(~gt0), 'LineStyle', 'None', 'Marker', 'o', 'MarkerSize', 20, 'Color', COLORS{iRR});
%         end

    end
    
    grid on;
    ts = round(1000*timeRange);
    if showTitle
        title(sprintf('Effect of previous target (%d-%d ms)', ts(1), ts(2)), 'FontSize', 24);
    end
    if showLabels
        xlabel('Trial N-x', 'FontSize', 40);
        ylabel('b', 'FontSize', 40, 'Rotation', 0);
    end
    set(gcf, 'Color', 'white');
    set(gca, 'FontSize', 40);
    set(gca, 'XLim', [.8 nPrevTrg+0.5]);
    set(gca, 'XTick', 1:nPrevTrg);
    if ~isempty(yLim), set(gca, 'YLim', yLim); end
    if ~isempty(yTickDelta), setTickDelta('y', yTickDelta); end
    if ~isempty(winSize), setFigWindowSize(winSize); end
    
    %---------------------------------------------------------------
    function pGt0 = isGT0(meanVals)
        
        nVars = size(meanVals, 2);
        pGt0 = ones(1, nVars);
        for i = 1:nVars
            [~,p] = ttest(meanVals(:, i));
            if (mean(meanVals(:, i)) > 0)
                pGt0(i) = p / 2;
            end
        end

    end

    %---------------------------------------------------------------
    function [plotStdErr, nPrevTrg, timeRange, showTitle, showLabels, colors, yLim, yTickDelta, winSize] = parseArgs(args)
        
        timeRange = [0 .3];
        plotStdErr = 0;
        nPrevTrg = 15;
        showTitle = true;
        showLabels = true;
        colors = {'blue', 'red', mycolors.darkgreen, mycolors.purple};
        yLim = [];
        yTickDelta = [];
        winSize = [];

        args = stripArgs(args);
        
        while ~isempty(args)
            switch(lower(args{1}))
                case 'stderr'
                    plotStdErr = 1;
                    
                case 'nprev'
                    nPrevTrg = args{2};
                    args = args(2:end);
                    
                case 'time'
                    timeRange = args{2};
                    args = args(2:end);
                    
                case 'notitle'
                    showTitle = false;

                case 'nolabel'
                    showLabels = false;
                    
                case 'colors'
                    colors = args{2};
                    args = args(2:end);
                    
                case 'ylim'
                    yLim = args{2};
                    args = args(2:end);
                    
                case 'ytick'
                    yTickDelta = args{2};
                    args = args(2:end);
                    
                case 'winsize'
                    winSize = args{2};
                    args = args(2:end);
                    
                otherwise
                    error('Unknown argument: %s', args{1});
            end
            
            args = stripArgs(args(2:end));
        end
        
    end
    
end

