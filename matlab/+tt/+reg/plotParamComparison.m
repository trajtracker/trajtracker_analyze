function figHandle = plotParamComparison(cmpData, varargin)
%handle = plotParamComparison(cmpData, ...) - 
%
%   plot a graph that shows one or more regression b values (or other 
%   parameters). Returns the figure handle.
%   The plot shows the average b value per time point, over all subjects.
%   It also shows, per time point, whether each parameter is significantly 
%   larger than zero (over all subjects), and can optionally show the 
%   comparison results of two parametere.
%
%   cmpData: the output of tt.reg.compareParams()
%   Flags:
%   Print <basic|details|raw> - set printing format
%   Fill none|trapped|box - If cmpData contains the
%                    comparison results of two parameters, this flag
%                    indicates how to print significance values.
%   Description <cell-array> - Legend description of each parameter. \n = newline
%   LegendNames - Print series names as legend. If not specified - they are
%           printed as floating text which you should reposition (the script
%           output tells you the name of each series)
%   DotStyle <style> - Style can be: "full", "hollow", or "Compare0" to
%           plot based on the significance of comparison vs. 0
%   StdErr - Show standard errors of comparisons
%   CI <ci-size> - show confidence intervals of the given size (0 < size < 1)
%   ShadeVar [alpha] - plot variance as shading (rather than as error bars)
%                  The optional 'alpha' parameter is the shading transparency.
%   Params <#,#,#> - plot only the given parameters (specify their number)
%   ConstAxis - Set the main Y axis to match printing CONST rather than B value
%   t0 <t> - mark this time point as t=0 (other time points will be aligned
%            accordingly).
%            Times are aligned by t0 BEFORE applying the MinTime/MaxTime filters
%   MinTime <t> - show results from the given time (default = 0)
%   MaxTime <t> - show results until the given time (default = 1.5 seconds)
%   Times <array> - show results for these specific times (overrides MinTime, MaxTime)
%   Title <text> - set the chart title
%   YLabel <text> - set the label of the Y axis
%   YLim [min,max] - set the range of the Y-axis
%   XTick <value> - set the delta between X ticks
%   XTickSkip <value> - Show X labels only every value+1 ticks (0 = show all labels)
%   YTick <value> - set the delta between Y ticks
%   MCompare - show marginal significance (p < .1) in pair comparison
%   Marker <markers> - set marker shape. Specify a cell array with a ROW of marker
%                  shapes. If the cell array has 2 rows, the first row is used 
%                  for significant points and the 2nd for nonsignificant
%                  points.
%   MarkerSize <size> - set marker size. The size is either a scalar or an
%                       array that is at least as long as the number of
%                       series to plot.
%   LineStyle <styles> - Specify a cell array with line styles per
%                  plotted parameter.
%   LegendSrc <source> - cell array or a single string. Determine whether the shape
%                       of the legend of each parameter is set by the
%                       (M)arker or by the (L)ine style
%   Color <colors> - cell array of colors (one per series)
%   TPMarker <cell array> - override marker formatting for specific time
%                   points. The cell array contains one struct per time
%                   point, with the following fields:
%                   - TimePoint (the only mandatory field) 
%                   - Predictor (index) - limit the definition to a specific predictor
%                   - Marker - marker symbol to use
%                   - MarkerSize
%                   - Color
%   HighlightTimes <t>: mark (with black dots) specific time windows. The
%               argument 't' is a struct with one matrix per parameter name.
%               The matrix is Nx2 and contains start-end time pairs.
%               This feature doesn't go well with the 'DotStyle' argument.
%   NoMaxWindow - don't maximize the figure window
%   WinSize [width height] - set the figure window size (in pixels)
%   MultBy <array> - multiply each plotted series by a constant values. The
%               array specifies these values (its size = numbers of series
%               to plot).
%   ConstY2 - Use the second axis (on the right side) for the b_const parameter
%   Y2 <cell-array> - Use the second axis for the specified parameters
%   YLabel2 <text> - the label for the right-side axis

    FILL_FORMAT_NONE = 0;
    FILL_FORMAT_BETWEEN_LINES = 1;
    FILL_FORMAT_BOX = 2;
    
    PRINT_MODE_BASIC = 1;
    PRINT_MODE_DETAILED = 2;
    PRINT_MODE_RAW = 3;
    
    DOT_STYLE_FULL = 1;
    DOT_STYLE_HOLLOW = 2;
    DOT_STYLE_COMPARE_0 = 3;
    DOT_STYLE_HIGHLIGHT_EXPLICIT = 4;
    
    ERR_BAR_NONE = 0;
    ERR_BAR_STDERR = 1;
    ERR_BAR_CI = 2; % Confidence interval
    
    if ~exist('cmpData', 'var')
        help tt.reg.plotParamComparison;
        return;
    end
    
    [printMode, fillFormat, seriesNamesLocation, timeIndsToPrint, t0, dotStyle, fontSize, lineWidth, ...
        regDescriptions, errBarLength, varianceAsArea, shadeAlpha, confIntervalSize, labels, usingDefaultMarkers, seriesToPlot, axesForConst, ...
        explicitXLim, explicitYLim, xTickDelta, yTickDelta, showTickLabels, xTickLabelSkip, comparePairMarginally, seriesFormat, tpMarkerOverride, ...
        highlightTimeWindows, windowSize, seriesMultiplyFactor, bgColor, textColor, ...
        y2SeriesInds, ax2Format, figID, doCLF] = parseArgs(varargin, cmpData);
    
    if ~ isfield(cmpData, 'comparedIndices') || isempty(cmpData.comparedIndices)
        fillFormat = FILL_FORMAT_NONE;
    end
    
    yRange = getYRange(cmpData, seriesToPlot);
    
    if ~isempty(figID), setFigure(figID); end
    if doCLF
        figHandle = clf;
    else
        figHandle = gcf;
    end
    hold on;
    
    if (fillFormat ~= FILL_FORMAT_NONE)
        fillSeriesDescriptions = plotFilledArea(cmpData, fillFormat, yRange);
    end
    
    ax2 = plotValues(cmpData, yRange, seriesNamesLocation, regDescriptions, ...
                timeIndsToPrint, t0, dotStyle, ...
                seriesToPlot, seriesFormat, labels, tpMarkerOverride);
    
    if (seriesNamesLocation.Legend)
        if exist('fillSeriesDescriptions', 'var')
            regDescriptions = [fillSeriesDescriptions, regDescriptions];
            seriesToPlot = [1:length(fillSeriesDescriptions), seriesToPlot+length(fillSeriesDescriptions)];
        end
        legend(regDescriptions(seriesToPlot), 'Location', seriesNamesLocation.LegendLocation);
    elseif (~isempty(regDescriptions) && exist('fillSeriesDescriptions', 'var'))
        legend(fillSeriesDescriptions, 'Location', seriesNamesLocation.LegendLocation);
    end
    set(legend, 'Color', bgColor, 'EdgeColor', textColor, 'TextColor', textColor);
    
    if ~isempty(windowSize), setFigWindowSize(windowSize); end
    
    set(gcf, 'Color', bgColor);
    set(gca, 'Color', bgColor)
    set(gca, 'XColor', textColor);
    set(gca, 'YColor', textColor);
    
    if ~isempty(ax2)
        % set focus to secondary Y axis, or the line won't appear
        axes(ax2);
    end
    
    %---------------------------------------------------------
    function lineSeriesDescriptions = plotFilledArea(cmpData, fillFormat, yRange)
        
        if (fillFormat == FILL_FORMAT_BETWEEN_LINES)
            ind = cmpData.comparedIndices;
            values1 = cmpData.cmpParam(ind(1)).values;
            values2 = cmpData.cmpParam(ind(2)).values;
        else
            values1 = ones(size(cmpData.cmpParam(1).values)) * yRange(1);
            values2 = ones(size(cmpData.cmpParam(1).values)) * yRange(2);
        end
        
        
        ALL_LEVEL_DESC = {'p <= .1', 'p <= .05', 'p <= .01', 'p <= .001'};
        if (comparePairMarginally)
            COLORS = {[.75 .75 .75], [.65 .65 .65], [.4 .4 .4], [.2 .2 .2]};
        else
            COLORS = {[.7 .7 .7], [.55 .55 .55], [.4 .4 .4]};
            ALL_LEVEL_DESC = ALL_LEVEL_DESC(2:end);
        end
        lineSeriesDescriptions = {};
        
        significanceLevels = getSignificanceLevel(cmpData.comparePair.pPred)';
        times = cmpData.times;
        
        for significanceLevel = 1:max(significanceLevels)
            
            relevantInds = find(significanceLevels == significanceLevel);
            if (isempty(relevantInds))
                continue;
            end
            
            lineSeriesDescriptions = [lineSeriesDescriptions  ALL_LEVEL_DESC(significanceLevel)]; %#ok<AGROW>
            
            isFirst = 1;
            
            for ind = relevantInds

                [polX, polY] = createPolygon(values1, values2, times, ind);
                if (isempty(polX))
                    continue;
                end
                h = fill(polX, polY, COLORS{significanceLevels(ind)}, 'LineStyle', 'none');
                if (~ isFirst)
                    set(h, 'HandleVisibility', 'off');
                end
                
                isFirst = 0;

            end
            
        end
        
    end
    
    %---------------------------------------------------------
    function [polX, polY] = createPolygon(values1, values2, times, ind)
        
        if (ind == 1 || ind == length(values1))
            disp('ERROR: Fill at extreme values is not supported yet');
            polX = [];
            polY = [];
            return;
        end
        
        dt = times(2)-times(1);
        
        midX = times(ind);
        leftX = max(midX-dt/2, times(1));
        rightX = min(midX+dt/2, times(end));
        
        leftY1 = mean(values1([ind, ind-1]));
        midY1 = values1(ind);
        rightY1 = mean(values1([ind, ind+1]));
        leftY2 = mean(values2([ind, ind-1]));
        midY2 = values2(ind);
        rightY2 = mean(values2([ind, ind+1]));
        
        polX = [leftX midX rightX rightX midX leftX];
        polY = [leftY1 midY1 rightY1 rightY2 midY2 leftY2];
        
    end

    %---------------------------------------------------------
    function [level, isFirstTimeLevelAppeared] = getSignificanceLevel(p)
        
        level = (p <= .001           ) * 3 + ...
                (p <= .01  & p > .001) * 2 + ...
                (p <= .05  & p > .01 ) * 1;
            
        if (comparePairMarginally)
            level = (level + 1) .* (level ~= 0) + (p <= .1  & p > .05 );
        end
            
        isFirstTimeLevelAppeared = zeros(1, length(p));
        for i = 1:max(level)
            isFirstTimeLevelAppeared(find(level == i, 1)) = 1;
        end
        
    end


    %---------------------------------------------------------
    function ax2 = plotValues(cmpData, yRange, seriesNamesLocation, ...
                        regDescriptions, timeIndsToPrint, t0, dotStyle, ...
                        seriesToPlot, seriesFormat, labels, tpMarkerOverride)
                    
        times = cmpData.times - t0;
        
        if (seriesNamesLocation.Legend)
            handleVisibility = 'on';
        else
            handleVisibility = 'off';
        end
        
        ax1 = gca;
        if isempty(y2SeriesInds)
            ax2 = [];
        else
            ax2 = axes('Position', ax1.Position, 'XAxisLocation', 'top', 'YAxisLocation', 'right', 'Color', 'none');
            ax2.XTickLabel = [];
            ax2.FontSize = ax2Format.FontSize;
            ax2.YColor = ax2Format.Color;
            ylabel(ax2, labels.y2);
            axes(ax1);
        end

        

        for i = 1:length(seriesToPlot)
            
            currSeriesInf = struct;
            currSeriesInf.desc = regDescriptions{i};
            
            seriesNum = seriesToPlot(i);
            currSeriesFormat = seriesFormat{i};
            currSeriesInf.paramName = cmpData.paramNames{seriesNum};
            
            currSeriesInf.relevantMarkerOverrides = tpMarkerOverride(arrayfun(@(o)ismember(i, o{1}.Predictor), tpMarkerOverride));
            currSeriesInf.markerOverrideInds = arrayfun(@(o)find(times >= o{1}.TimePoint, 1), currSeriesInf.relevantMarkerOverrides);
            
            currSeriesFormat.lineHandleVisibility = 'off';
            currSeriesFormat.markerHandleVisibility = 'off';
            switch(lower(currSeriesFormat.LegendSource))
                case {'m', 'marker'}
                    currSeriesFormat.markerHandleVisibility = handleVisibility;
                    
                case {'l', 'line'}
                    currSeriesFormat.lineHandleVisibility = handleVisibility;
                    
                otherwise
                    error('Unsupported "LegendSrc" value: %s', currSeriesFormat.LegendSource);
            end
            
            values = cmpData.cmpParam(seriesNum).values;
            if ~isempty(seriesMultiplyFactor)
                values = values * seriesMultiplyFactor(seriesNum);
            end
            
            plotx = times(timeIndsToPrint);
            ploty = values(timeIndsToPrint);
            
            %-- prepare info about variance
            if (errBarLength ~= ERR_BAR_NONE)
                
                stdevs = cmpData.cmpParam(seriesNum).sd_values;
                if ~isempty(seriesMultiplyFactor)
                    stdevs = stdevs * seriesMultiplyFactor(seriesNum);
                end
                
                nSubjects = cmpData.NSubjects;
                
                stderrs = stdevs / sqrt(nSubjects);
                if (errBarLength == ERR_BAR_STDERR)
                    % error bars show standard error
                    errBars = stderrs;
                elseif (errBarLength == ERR_BAR_CI)
                    d = (1-confIntervalSize)/2;
                    errBars = stderrs * abs(tinv(d, nSubjects-1));
                else
                    error('Invalid error bar metrics');
                end

                plotsd = errBars(timeIndsToPrint);
                
            else
                plotsd = [];
            end
            
            
            % Plot series
            if ismember(seriesNum, y2SeriesInds)
                plotSeriesOnSecondaryYAxis(ax2, seriesNum, times, values, plotx, ploty, plotsd, currSeriesFormat, currSeriesInf);
            else
                plotSeriesOnMainYAxis(ax1, seriesNum, times, values, plotx, ploty, plotsd, currSeriesFormat, currSeriesInf, dotStyle);
            end

        end
        
        if (length(seriesToPlot) > 4 && usingDefaultMarkers)
            fprintf('WARNING: I suspect some markers are not very clear.\n         Consider modifying them using the "Marker" flag.\n');
        end

        
        % Find the first "round" time: x ticks will be aligned by this one
        
        dt = times(2) - times(1);
        xTickSpacing = round(xTickDelta / dt) * dt;
        tick0 = floor((times(timeIndsToPrint(1))+.001) / xTickSpacing) * xTickSpacing;
        xTicks = tick0 : xTickSpacing : times(timeIndsToPrint(end));
        
        if isempty(explicitXLim)
            xlim([tick0 times(timeIndsToPrint(end))+.001]);
        else
            xlim(explicitXLim);
        end
        ax1.XTick = xTicks;
        if showTickLabels
            precision = findPrecision(xTickDelta, 6);
            xlabels = arrayfun(@(t){sprintf('%.*f', precision, t)}, xTicks);
            if xTickLabelSkip > 0
                xlabels(mod(0:length(xlabels)-1, xTickLabelSkip+1) ~= 0) = {''};
            end
            ax1.XTickLabel = xlabels;
        else
            ax1.XTickLabel = {};
        end
        
        if isempty(explicitYLim)
            if (axesForConst)
                yLim = yRange + [-1 1];
            else
                yLim = yRange + [-.05 .05];
            end
        else
            yRange = explicitYLim;
            yLim = explicitYLim;
        end
        
        ylim(yLim);
        set(gca, 'FontSize', fontSize, 'FontName', 'Arial');
        
        if (axesForConst)
            startTicks = ceil(yRange(1)/5)*5;
            yTicks = startTicks:yTickDelta:yLim(2);
            ax1.YTick = yTicks;
            ax1.YTickLabel = iif(showTickLabels, arrayfun(@(y){sprintf('%d', y)}, yTicks), {});
        else
            setTickDelta('Y', yTickDelta);
            if ~showTickLabels
                ax1.YTickLabel = {};
            end
        end
        
        grid on;

        if (printMode == PRINT_MODE_RAW)
            title(sprintf('Compare regression %s values over all subjects', ...
                getParamDesc(cmpData.paramNames{1})), ...
                'FontSize', 22);
        end
        
        xlabel(labels.x);
        
        if strcmp(labels.y, 'DEFAULT')
            if (axesForConst)
                labels.y = 'const';
            elseif isbetaRegression(cmpData)
                labels.y = 'beta';
            else
                labels.y = 'b';
            end
        end
        
        
        text('String', labels.y, 'FontSize', fontSize+4, 'Position', [-.12, .58], 'Units', 'Normalized', 'Color', textColor);
        
        if ~isempty(labels.figure)
            title(labels.figure, 'FontSize', 30);
        end
        
    end
    
    %-------------------------------------------------------------
    function plotSeriesOnMainYAxis(ax, seriesNum, times, values, plotx, ploty, plotsd, currSeriesFormat, currSeriesInf, dotStyle)
        
        if (errBarLength ~= ERR_BAR_NONE && varianceAsArea)

            h = area(ax, plotx', [ploty-plotsd, plotsd*2], 'EdgeAlpha', 0, 'HandleVisibility', 'off');
            h(1).FaceAlpha = 0;
            h(2).FaceAlpha = shadeAlpha;
            h(2).FaceColor = currSeriesFormat.Color;

        end

        if (errBarLength == ERR_BAR_NONE || varianceAsArea)

            % plot data lines with error bars
            plot(ax, plotx, ploty, 'Color', currSeriesFormat.Color, 'Marker', 'none', ...
                'LineStyle', currSeriesFormat.LineStyle, 'LineWidth', lineWidth, 'HandleVisibility', currSeriesFormat.lineHandleVisibility);

        elseif ~varianceAsArea

            % plot lines with error bars
            errorbar(ax, plotx, ploty, plotsd, 'Color', currSeriesFormat.Color, 'Marker', 'none', 'LineStyle', currSeriesFormat.LineStyle, 'LineWidth', lineWidth, 'HandleVisibility', currSeriesFormat.lineHandleVisibility);

        end

        % Find time indices of significant and non-significant results.
        switch(dotStyle)
            case DOT_STYLE_FULL
                fullDotTimeInds = timeIndsToPrint;
                hollowDotTimeInds = [];

            case DOT_STYLE_HOLLOW
                hollowDotTimeInds = timeIndsToPrint;
                fullDotTimeInds = [];

            case DOT_STYLE_COMPARE_0
                isSignificantTimeInd = cmpData.cmpParam(seriesNum).pPred <= .05;
                fullDotTimeInds = find(isSignificantTimeInd);
                fullDotTimeInds = fullDotTimeInds(arrayfun(@(i)ismember(i, timeIndsToPrint), fullDotTimeInds));
                hollowDotTimeInds = find(~isSignificantTimeInd);
                hollowDotTimeInds = hollowDotTimeInds(arrayfun(@(i)ismember(i, timeIndsToPrint), hollowDotTimeInds));

            case DOT_STYLE_HIGHLIGHT_EXPLICIT
                if isfield(highlightTimeWindows, currSeriesInf.paramName)
                    highlightTimeInds = timeWindowToTimeFlags(times(timeIndsToPrint), highlightTimeWindows.(currSeriesInf.paramName));
                else
                    highlightTimeInds = false(size(timeIndsToPrint));
                end
                fullDotTimeInds = find(highlightTimeInds);
                hollowDotTimeInds = find(~highlightTimeInds);
                
            otherwise
                error('Unsupported dot style: %d', dotStyle);
        end

        allSignificantTimeInds = fullDotTimeInds;

        % Ignore overriden time points
        fullDotTimeInds = fullDotTimeInds(arrayfun(@(i)~ismember(i, currSeriesInf.markerOverrideInds), fullDotTimeInds));
        hollowDotTimeInds = hollowDotTimeInds(arrayfun(@(i)~ismember(i, currSeriesInf.markerOverrideInds), hollowDotTimeInds));

        % Make sure there's at least 1 full plotted point, for legend
        if (strcmpi(currSeriesFormat.markerHandleVisibility, 'on') && isempty(fullDotTimeInds))
            ttt = times(end) + 100;
            vvv = 0;
        else
            ttt = times(fullDotTimeInds);
            vvv = values(fullDotTimeInds);
        end

        % Significant
        plot(ax, ttt, vvv, 'Color', currSeriesFormat.Color, 'Marker', currSeriesFormat.MarkerSig, 'MarkerSize', currSeriesFormat.MarkerSize, ...
            'MarkerFace', currSeriesFormat.Color, 'LineStyle', 'none', 'HandleVisibility', currSeriesFormat.markerHandleVisibility);

        % Nonsignificant
        plot(ax, times(hollowDotTimeInds), values(hollowDotTimeInds), 'Color', currSeriesFormat.Color, ...
                'Marker', currSeriesFormat.MarkerNonSig, 'MarkerSize', currSeriesFormat.MarkerSize, 'LineStyle', 'none', 'HandleVisibility', 'off');

        % Plot overriden time points
        for iTP = 1:length(currSeriesInf.relevantMarkerOverrides)
            markerFmt = currSeriesInf.relevantMarkerOverrides{iTP};
            for fieldName = {'Color', 'MarkerSize', 'MarkerSig', 'MarkerNonSig'}
                if ~isfield(markerFmt, fieldName{1})
                    markerFmt.(fieldName{1}) = currSeriesFormat.(fieldName{1});
                end
            end

            if ismember(markerOverrideInds(iTP), allSignificantTimeInds) || dotStyle == DOT_STYLE_FULL
                % Plot this time point as full
                marker = markerFmt.MarkerSig;
                markerFace = markerFmt.Color;
            else
                marker = markerFmt.MarkerNonSig;
                markerFace = 'none';
            end

            plot(ax, times(markerOverrideInds(iTP)), values(markerOverrideInds(iTP)), 'Color', markerFmt.Color, ...
                    'Marker', marker, 'MarkerSize', markerFmt.MarkerSize, 'MarkerFace', markerFace, 'LineStyle', 'none', 'HandleVisibility', 'off');
        end

        if seriesNamesLocation.Floating
            text('String', regexp(regDescriptions{seriesNum}, '\\n', 'split'), ...
                 'HorizontalAlignment', 'center', ...
                 'FontSize', fontSize, ...
                 'Color', currSeriesFormat.Color);
        end
        
        if ~seriesNamesLocation.Legend
            fprintf('%s  %s(%d): %s\n', currSeriesFormat.LineStyle, currSeriesFormat.MarkerSig, currSeriesFormat.MarkerSize, regDescriptions{seriesNum});
        end
        
    end

    %-------------------------------------------------------------
    function plotSeriesOnSecondaryYAxis(ax2, seriesNum, times, values, plotx, ploty, plotsd, currSeriesFormat, currSeriesInf)
        
        line(plotx, ploty, 'Parent', ax2, 'Color', currSeriesFormat.Color, 'LineWidth', lineWidth)
        
    end

    %-------------------------------------------------------------
    function beta = isbetaRegression(cmpData)
        c = arrayfun(@(i)~ startsWith(cmpData.paramNames{i}, 'beta'), 1:length(cmpData.paramNames));
        beta = sum(c) == 0;
    end

    %-------------------------------------------------------------
    function d = getParamDesc(param)
        switch(param(1:2))
            case 'RS'
                d = 'R-square';
            case 'b_'
                d = 'b';
            case 'beta_'
                d = 'Beta';
            otherwise
                d = param;
        end
    end

    %-----------------------------------------------------------
    % times: an array
    % timewindows: Nx2 matrix with start-end time pairs
    function tf = timeWindowToTimeFlags(times, timeWindows)

        tf = false(length(times), 1);

        for i = 1:size(timeWindows,1)
            tf(times >= timeWindows(i,1)-.0001 & times <= timeWindows(i,2)+.0001) = true;
        end

    end

    %-----------------------------------------------------------
    % Return the overall min/max Y values - among all parameters, in all times slots
    function yRange = getYRange(cmpData, seriesToPlot)
        nParams = length(seriesToPlot);
        
        minVals = NaN(nParams, 1);
        maxVals = NaN(nParams, 1);
        
        for i = 1:nParams
            values = cmpData.cmpParam(seriesToPlot(i)).values;
            minVals(i) = min(values);
            maxVals(i) = max(values);
        end
        
        yRange = [min(minVals), max(maxVals)];
    end

    %-----------------------------------------------------------
    function [printMode, fillFormat, seriesNamesLocation, timeIndsToPrint, t0, dotStyle, fontSize, lineWidth, ...
                regDescriptions, errBarLength, varianceAsArea, shadeAlpha, confIntervalSize, labels, usingDefaultMarkers, seriesToPlot, axesForConst, ...
                explicitXLim, explicitYLim, xTickDelta, yTickDelta, showTickLabels, xTickLabelSkip, comparePairMarginally, seriesFormat, tpMarkerOverride, ...
                highlightTimeWindows, windowSize, seriesMultiplyFactor, bgColor, textColor, ax2SeriesInds, ax2Format, figID, doCLF] = ...
                    parseArgs(args, cmpData)
        
        printMode = PRINT_MODE_BASIC;
        fillFormat = FILL_FORMAT_BETWEEN_LINES;
        dotStyle = DOT_STYLE_COMPARE_0;
        varianceAsArea = false;
        shadeAlpha = 0.15;
        errBarLength = ERR_BAR_NONE;
        confIntervalSize = .95;
        t0 = 0;
        fontSize = 40;
        lineWidth = 2;
        
        timeIndsToPrint = [];
        minTimeToPrint = 0;
        maxTimeToPrint = 1.5;
        
        seriesNamesLocation = struct('Floating', 1, 'Legend', 0, 'LegendLocation', 'NorthWest');
        
        labels = struct('x', 'Time', 'y', 'DEFAULT', 'y2', 'DEFAULT', 'figure', '');
        
        nSeries = length(cmpData.paramNames);
        seriesToPlot = 1:nSeries;
        axesForConst = 0;
        explicitXLim = [];
        explicitYLim = [];
        xTickDelta = .25;
        yTickDelta = [];
        showTickLabels = true;
        xTickLabelSkip = 0;
        comparePairMarginally = 0;
        
        DEFAULT_MARKERS_NS  = {'o', 's', 'd', 'h', '+', '^'};
        DEFAULT_MARKERS_SIG = {'o', 's', 'd', 'h', '*', 'x'};
        
        usingDefaultMarkers = 1;
        useDefaultColors = 1;
        
        highlightTimeWindows = [];
        windowSize = get(0,'Screensize'); windowSize = windowSize(3:4);
        seriesMultiplyFactor = [];
        bgColor = 'White';
        textColor = 'Black';
        ax2SeriesInds = [];
        ax2Format = struct('Color', [.6 .6 .6], 'FontSize', 20);
        figID = [];
        doCLF = true;
        
        % Per-series formatting
        seriesFormat = arrayfun(@(i){struct}, 1:nSeries);
        for i = 1:nSeries
            seriesFormat{i}.LineStyle = '-';
            seriesFormat{i}.LegendSource = 'M';
            if (i <= length(DEFAULT_MARKERS_NS))
                seriesFormat{i}.MarkerSig = DEFAULT_MARKERS_SIG{i};
                seriesFormat{i}.MarkerNonSig = DEFAULT_MARKERS_NS{i};
            end
        end
        
        tpMarkerOverride = {}; % Override of formatting per time point
        
        args = stripArgs(args);
        
        while ~isempty(args)
            
            switch(lower(args{1}))
                case 'print'
                    switch(lower(args{2}))
                        case 'basic'
                            printMode = PRINT_MODE_BASIC;
                        case 'detail'
                            printMode = PRINT_MODE_DETAILED;
                        case 'raw'
                            printMode = PRINT_MODE_RAW;
                        otherwise
                            error('Invalid print mode');
                    end
                    args = args(2:end);
                    
                case 'fill'
                    switch(lower(args{2}))
                        case 'none'
                            fillFormat = FILL_FORMAT_NONE;
                        case 'trapped'
                            fillFormat = FILL_FORMAT_BETWEEN_LINES;
                        case 'box'
                            fillFormat = FILL_FORMAT_BOX;
                        otherwise
                            error('Invalid fill format');
                    end
                    args = args(2:end);
                    
                case 'legend'
                    switch(lower(args{2}))
                        case 'floating'
                            seriesNamesLocation.Legend = 0;
                            seriesNamesLocation.Floating = 1;
                        case 'legend'
                            seriesNamesLocation.Legend = 1;
                            seriesNamesLocation.Floating = 0;
                        case 'both'
                            seriesNamesLocation.Legend = 1;
                            seriesNamesLocation.Floating = 1;
                        case 'none'
                            seriesNamesLocation.Legend = 0;
                            seriesNamesLocation.Floating = 0;
                        otherwise
                            error('Invalid "Legend" arg!');
                    end
                    args = args(2:end);
                    
                case 'legendloc'
                    seriesNamesLocation.LegendLocation = args{2};
                    args = args(2:end);
                    
                case 'description'
                    regDescriptions = args{2};
                    args = args(2:end);
                    
                case 'fontsize'
                    fontSize = args{2};
                    args = args(2:end);
                    
                case 'linewidth'
                    lineWidth = args{2};
                    args = args(2:end);
                    
                case 'times'
                    timesToPrint = args{2};
                    args = args(2:end);
                    timeIndsToPrint = arrayfun(@(t)find(cmpData.times >= t-0.001, 1), timesToPrint);
                    
                case 'maxtime'
                    maxTimeToPrint = args{2};
                    args = args(2:end);
                    
                case 'mintime'
                    minTimeToPrint = args{2};
                    args = args(2:end);
                    
                case 't0'
                    t0 = args{2};
                    args = args(2:end);
                    
                case 'dotstyle'
                    switch(lower(args{2}))
                        case 'full'
                            dotStyle = DOT_STYLE_FULL;
                        case 'hollow'
                            dotStyle = DOT_STYLE_HOLLOW;
                        case {'0', 0, 'compare0'}
                            dotStyle = DOT_STYLE_COMPARE_0;
                        otherwise
                            error('Invalid "DotStyle" argument');
                    end
                    args = args(2:end);
                    
                case 'stderr'
                    errBarLength = ERR_BAR_STDERR;
                    
                case 'ci'
                    errBarLength = ERR_BAR_CI;
                    confIntervalSize = args{2};
                    args = args(2:end);
                    
                case 'shadevar'
                    varianceAsArea = true;
                    if length(args) > 1 && isnumeric(args{2})
                        shadeAlpha = args{2};
                        args = args(2:end);
                    end
                    
                case 'title'
                    labels.figure = args{2};
                    args = args(2:end);
                    
                case 'xlabel'
                    labels.x = args{2};
                    args = args(2:end);
                    
                case 'ylabel'
                    labels.y = args{2};
                    args = args(2:end);
                    
                case 'ylabel2'
                    labels.y2 = args{2};
                    args = args(2:end);
                    
                case 'nolabels'
                    labels.x = '';
                    labels.y = '';
                    
                case 'params'
                    seriesToPlot = args{2};
                    args = args(2:end);
                    
                case 'xlim'
                    explicitXLim = args{2};
                    args = args(2:end);
                    
                case 'ylim'
                    explicitYLim = args{2};
                    args = args(2:end);
                    
                case 'ytick'
                    yTickDelta = args{2};
                    args = args(2:end);
                    if (numel(yTickDelta) ~= 1)
                        error('The "YTick" argument should be a single value specifying the tick delta');
                    end
                    
                case 'xtick'
                    xTickDelta = args{2};
                    args = args(2:end);
                    if (numel(xTickDelta) ~= 1)
                        error('The "XTick" argument should be a single value specifying the tick delta');
                    end
                    
                case 'xtickskip'
                    xTickLabelSkip = args{2};
                    args = args(2:end);

                case 'noticklabels'
                    showTickLabels = false;
                    
                case 'marker'
                    usingDefaultMarkers = 0;
                    significantMarkers = args{2};
                    if length(args) > 2 && iscell(args{3})
                        % an additional list of non-significant markers
                        nonSignificantMarkers = args{3};
                        args = args(3:end);
                    else
                        % Use same markers for significant and non-significant
                        nonSignificantMarkers = significantMarkers;
                        args = args(2:end);
                    end
                    
                    if ischar(significantMarkers)
                        significantMarkers = {significantMarkers};
                    end
                    if ischar(nonSignificantMarkers)
                        nonSignificantMarkers = {nonSignificantMarkers};
                    end
                    if length(significantMarkers) == 1
                        significantMarkers = arrayfun(@(i)significantMarkers, 1:nSeries);
                    end
                    if length(nonSignificantMarkers) == 1
                        nonSignificantMarkers = arrayfun(@(i)nonSignificantMarkers, 1:nSeries);
                    end
                    for i = 1:length(significantMarkers)
                        seriesFormat{i}.MarkerSig = significantMarkers{i};
                        seriesFormat{i}.MarkerNonSig = nonSignificantMarkers{i};
                    end
                    
                case 'nonsmarker'
                    for i = 1:length(significantMarkers)
                        seriesFormat{i}.MarkerNonSig = 'None';
                    end
                    
                case 'markersize'
                    markerSize = args{2};
                    args = args(2:end);
                    if numel(markerSize) == 1
                        markerSize = arrayfun(@(x)markerSize, 1:nSeries);
                    end
                    for i = 1:nSeries
                        seriesFormat{i}.MarkerSize = markerSize(i);
                    end
                    
                case 'linestyle'
                    lineStyle = args{2};
                    args = args(2:end);
                    if ischar(lineStyle)
                        lineStyle = arrayfun(@(x){lineStyle}, 1:nSeries);
                    end
                    for i = 1:nSeries
                        seriesFormat{i}.LineStyle = lineStyle{i};
                    end
                    
                case 'legendsrc'
                    legendSource = args{2};
                    args = args(2:end);
                    if ischar(legendSource)
                        legendSource = arrayfun(@(x){legendSource}, 1:nSeries);
                    end
                    for i = 1:nSeries
                        seriesFormat{i}.LegendSource = legendSource{i};
                    end
                    
                case 'mcompare'
                    comparePairMarginally = 1;
                    
                case {'color', 'colors'}
                    useDefaultColors = 0;
                    colors = args{2};
                    args = args(2:end);
                    if ischar(colors)
                        colors = arrayfun(@(i){colors}, 1:nSeries);
                    end
                    for i = 1:length(colors)
                        seriesFormat{i}.Color = colors{i};
                    end
                    
                case 'tpmarker'
                    tpMarkerOverride = args{2};
                    args = args(2:end);
                    if ~iscell(tpMarkerOverride)
                        error('TPMarker expects a cell array!');
                    end
                    for i = 1:length(tpMarkerOverride)
                        if ~isfield(tpMarkerOverride{i}, 'TimePoint')
                            error('TPMarker should be followed by a cell array of structs, each specifying TimePoint and possible additional override info');
                        end
                        if ~isfield(tpMarkerOverride{i}, 'Predictor')
                            tpMarkerOverride{i}.Predictor = 1:nSeries; % apply to all
                        end
                    end
                        
                case 'highlighttimes'
                    dotStyle = DOT_STYLE_HIGHLIGHT_EXPLICIT;
                    highlightTimeWindows = args{2};
                    args = args(2:end);
                    
                case 'nomaxwindow'
                    windowSize = [];
                    
                case 'winsize'
                    windowSize = args{2};
                    args = args(2:end);
                    
                case 'figid'
                    figID = args{2};
                    args = args(2:end);
                    
                case 'multby'
                    seriesMultiplyFactor = args{2};
                    args = args(2:end);
                    
                case 'invert'
                    bgColor = 'Black';
                    textColor = 'White';
                    
                case 'constaxis'
                    axesForConst = true;
                    
                case 'y2'
                    paramsForAx2 = iif(ischar(args{2}), args(2), args{2});
                    args = args(2:end);
                    ax2SeriesInds = NaN(length(paramsForAxis2));
                    for i = 1:length(ax2SeriesInds)
                        ax2SeriesInds(i) = find(arrayfun(@(p)strcmp(p{1}, paramsForAx2{i}), cmpData.paramNames), 1);
                        if isempty(ax2SeriesInds)
                            error('You asked to plot %s on the secondary Y axis, but this parameter was not found', paramsForAx2{i});
                        end
                    end
                    
                case 'consty2'
                    ax2SeriesInds = find(arrayfun(@(p)strcmp(p{1}, 'b_const'), cmpData.paramNames), 1);
                    if isempty(ax2SeriesInds)
                        error('You specified "ConstY2" but parameter b_const was not found');
                    end
                    if strcmp(labels.y2, 'DEFAULT')
                        labels.y2 = 'Constant';
                    end
                    
                case 'noclf'
                    doCLF = false;
                    
                otherwise
                    error('Unknown argument "%s"', args{1});
            end
            
            args = stripArgs(args(2:end));
        end
        
        % Apply defaults
        
        if ~exist('regDescriptions', 'var')
            if isfield(cmpData, 'Description')
                regDescriptions = cmpData.Description;
            else
                regDescriptions = arrayfun(@(cmp){cmp.ParamDesc}, cmpData.cmpParam);
            end
        end
        
        if isempty(yTickDelta)
            if (axesForConst)
                yTickDelta = 5;
            else
                yTickDelta = .25;
            end
        end
        
        
        if (printMode == PRINT_MODE_RAW)
            DEFAULT_MARKER_SIZE = 1;
        else
            DEFAULT_MARKER_SIZE = 14;
        end
        for i = 1:nSeries
            if ~isfield(seriesFormat{i} , 'MarkerSize')
                seriesFormat{i}.MarkerSize = DEFAULT_MARKER_SIZE;
            end
        end
        
        if useDefaultColors
            if (printMode < PRINT_MODE_RAW)
                DEFAULT_COLORS = repmat({'black'}, 1, nSeries);
            else
                DEFAULT_COLORS = {'blue', 'cyan', 'red'};
            end
            for i = 1:nSeries
                seriesFormat{i}.Color = DEFAULT_COLORS{i};
            end
        end
        
        if isempty(timeIndsToPrint)
            timeIndsToPrint = find(cmpData.times >= minTimeToPrint & cmpData.times <= maxTimeToPrint);
            if isempty(timeIndsToPrint)
                error('Invalid time range: there are no time points between %g and %g', minTimeToPrint, maxTimeToPrint);
            end
        end
        
        if length(seriesMultiplyFactor) == 1
            seriesMultiplyFactor = repmat(seriesMultiplyFactor, 1, nSeries);
        end
        
    end

end
