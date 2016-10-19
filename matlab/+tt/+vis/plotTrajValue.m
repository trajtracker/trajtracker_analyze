function plotTrajValue(inData, varargin)
%plotTrajValue(data, ...) - plot the time profile of a trajectory value.
% 
% data: expData, a dataset, or cell array of those
% In the plot, trials can be grouped in various ways.
% 
% Optional Arguments:
% ====================
% GrpDesc <cell-array>: one entry per group. Use as legend.
% NPerPlot <n> - split plot into several sub-plots. In each sub-plot, this
%             number of groups will be included.
%             Sub-plots appear one above the other.
% Colors <cell-array>: colors (one per group)
% YLim [min max]
% XLim [min max]
% YTick <delta>
% XTick <delta>
% FontSize <size>
% FigID <n> - set the figure ID
% WinSize [width height] - set size of the figure window
% - and any argument of <a href="tt.inf.getTrajectoryValues">tt.inf.getTrajectoryValues</a>

    [getValueArgs, colors, xLim, yLim, xTick, yTick, fontSize, grpDesc, figID, nGroupsPerSubPlot, winSize] = parseArgs(varargin);
    
    [dataToPlot, info] = tt.inf.getTrajectoryValues(inData, getValueArgs);
    nGroups = size(dataToPlot, 2);
    
    if isempty(colors)
        colors = varycolor(nGroups, true);
    end
    
    if ~isempty(figID), setFigure(figID); end;
    clf;
    
    if ~isempty(nGroupsPerSubPlot) && nGroupsPerSubPlot<nGroups
        nSP = ceil(nGroups/nGroupsPerSubPlot);
        spnum = 1;
        for ii = 1:nGroupsPerSubPlot:nGroups
            doPlot(dataToPlot, info, ii:min(nGroups, ii+nGroupsPerSubPlot-1), [nSP, 1, spnum]);
            spnum = spnum+1;
        end
    else
        doPlot(dataToPlot, info, 1:nGroups, []);
    end
    
    if ~isempty(grpDesc), legend(grpDesc); end
    
    set(gcf, 'color', 'white');
    if ~isempty(winSize), setFigWindowSize(winSize); end;
    

    %-------------------------------------------
    function doPlot(data, info, groupNums, subplotInf)
        
        if ~isempty(subplotInf)
            subplot(subplotInf(1), subplotInf(2), subplotInf(3));
        end
        
        hold on;
        
        for i = 1:length(groupNums)
            iGrp = groupNums(i);
            n = info.nTimePointsPerGroup(iGrp);
            y = data(:, iGrp);
            plot(info.times(1:n), y(1:n), 'Color', colors{i});
        end

        if ~isempty(xLim), xlim(xLim); end;
        if ~isempty(yLim), ylim(yLim); end;
        if ~isempty(xTick), setTickDelta('x', xTick); end;
        if ~isempty(yTick), setTickDelta('y', yTick); end;
        
        if ~isempty(subplotInf) && subplotInf(1) ~= subplotInf(3)
            set(gca, 'XTickLabel', {});
        end
        
        set(gca, 'FontSize', fontSize);
        grid on;
        
    end
    
    %-------------------------------------------
    function [getValueArgs, colors, xLim, yLim, xTick, yTick, fontSize, grpDesc, figID, ...
            nGroupsPerSubPlot, winSize] = parseArgs(args)

        getValueArgs = {};
        colors = [];
        xLim = [];
        yLim = [];
        xTick = [];
        yTick = [];
        fontSize = 30;
        figID = [];
        winSize = [];
        nGroupsPerSubPlot = [];
        grpDesc = {};
        
        args = stripArgs(args);
        while ~isempty(args)
            switch(lower(args{1}))
                case {'getvaluefunc', 'trajcol', 'trialfilter', 'grpfunc', 'smooth'}
                    getValueArgs = [getValueArgs args(1:2)]; %#ok<AGROW>
                    args = args(2:end);
                    
                case {'extrapolate'}
                    getValueArgs = [getValueArgs args(1)]; %#ok<AGROW>
                    
                case 'xlim'
                    xLim = args{2};
                    args = args(2:end);
                    
                case 'ylim'
                    yLim = args{2};
                    args = args(2:end);
                    
                case 'xtick'
                    xTick = args{2};
                    args = args(2:end);
                    
                case 'ytick'
                    yTick = args{2};
                    args = args(2:end);
                    
                case 'colors'
                    colors = args{2};
                    args = args(2:end);
                    
                case 'figid'
                    figID = args{2};
                    args = args(2:end);
                    
                case 'grpdesc'
                    grpDesc = args{2};
                    args = args(2:end);
                    
                case 'winsize'
                    winSize = args{2};
                    args = args(2:end);
                    
                case 'fontsize'
                    fontSize = args{2};
                    args = args(2:end);
                    
                case 'nperplot'
                    nGroupsPerSubPlot= args{2};
                    args = args(2:end);
                    
                otherwise
                    error('Unsupported argument "%s"!', args{1});
            end
            args = stripArgs(args(2:end));
        end
        
        if ~isempty(nGroupsPerSubPlot) && length(figID) > 1
            error('You asked to divide figure into sub-plots, so you cannot use "FigID" to specify a specific subplot');
        end
        
    end


end

