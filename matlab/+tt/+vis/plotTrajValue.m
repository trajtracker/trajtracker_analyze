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
% NoCLF: don't clear the figure before plotting
% - and any argument of <a href="matlab:help tt.inf.getTrajectoryValues">tt.inf.getTrajectoryValues</a>

    [getValueArgs, colors, displayArgs, grpDesc, nGroupsPerSubPlot, subPlotArgs, doCLF] = parseArgs(varargin);
    
    [dataToPlot, info] = tt.inf.getTrajectoryValues(inData, getValueArgs);
    nGroups = size(dataToPlot, 2);
    
    if isempty(colors)
        colors = varycolor(nGroups, true);
    end
    
    if ~isempty(displayArgs.figid), setFigure(displayArgs.figid); end;
    if doCLF, clf; end
    
    if ~isempty(nGroupsPerSubPlot) && nGroupsPerSubPlot<nGroups
        nSP = ceil(nGroups/nGroupsPerSubPlot);
        spnum = 1;
        for ii = 1:nGroupsPerSubPlot:nGroups
            doPlot(dataToPlot, info, ii:min(nGroups, ii+nGroupsPerSubPlot-1), [nSP, 1, spnum], subPlotArgs);
            spnum = spnum+1;
        end
    else
        doPlot(dataToPlot, info, 1:nGroups, [], []);
    end
    
    if ~isempty(grpDesc), legend(grpDesc); end
    
    set(gcf, 'color', 'white');
    if ~isempty(displayArgs.winsize), setFigWindowSize(displayArgs.winsize); end;
    

    %-------------------------------------------
    function doPlot(data, info, groupNums, subplotInf, subPlotArgs)
        
        if ~isempty(subplotInf)
            
            h = subplot(subplotInf(1), subplotInf(2), subplotInf(3));
            
            %-- Fix the way the sub-plot is displayed
            nSubPlots = subplotInf(1);
            currSubPlot = subplotInf(3);
            spHeight = subPlotArgs.UsedHeight / nSubPlots;
            spY = subPlotArgs.XAxisHeight + ((nSubPlots-currSubPlot)/nSubPlots) * (1 - subPlotArgs.XAxisHeight);
            spPos = get(h, 'pos');
            set(h, 'Pos', [spPos(1), spY, spPos(3), spHeight]);
            
        end
        
        hold on;
        
        for i = 1:length(groupNums)
            iGrp = groupNums(i);
            n = info.nTimePointsPerGroup(iGrp);
            y = data(:, iGrp);
            plot(info.times(1:n), y(1:n), 'Color', colors{i}, 'LineWidth', displayArgs.linewidth);
        end

        if ~isempty(displayArgs.xlim), xlim(displayArgs.xlim); end;
        if ~isempty(displayArgs.ylim), ylim(displayArgs.ylim); end;
        if ~isempty(displayArgs.xtick), setTickDelta('x', displayArgs.xtick); end;
        if ~isempty(displayArgs.ytick), setTickDelta('y', displayArgs.ytick); end;
        
        if ~isempty(subplotInf) && subplotInf(1) ~= subplotInf(3)
            set(gca, 'XTickLabel', {});
        end
        
        set(gca, 'FontSize', displayArgs.fontsize);
        grid on;
        
    end
    
    %-------------------------------------------
    function [getValueArgs, colors, displayArgs, grpDesc, nGroupsPerSubPlot, subPlotArgs, doCLF] = parseArgs(args)

        getValueArgs = {};
        colors = [];
        
        displayArgs = struct('linewidth', 1, 'xlim', [], 'ylim', [], 'xtick', [], 'ytick', [], 'fontsize', 30, 'figid', [], 'winsize', []);
        
        nGroupsPerSubPlot = [];
        grpDesc = {};
        subPlotArgs = struct('UsedHeight', 0.85, 'XAxisHeight', .07);
        doCLF = true;
        
        args = stripArgs(args);
        while ~isempty(args)
            switch(lower(args{1}))
                case {'getvaluefunc', 'trajcol', 'trialfilter', 'grpfunc', 'smooth', 'maxtime'}
                    getValueArgs = [getValueArgs args(1:2)]; %#ok<AGROW>
                    args = args(2:end);
                    
                case {'extrapolate', 'grpall'}
                    getValueArgs = [getValueArgs args(1)]; %#ok<AGROW>
                    
                case {'linewidth', 'xlim', 'ylim', 'xtick', 'ytick', 'fontsize', 'figid', 'winsize'}
                    displayArgs.(lower(args{1})) = args{2};
                    args = args(2:end);
                    
                case 'colors'
                    colors = args{2};
                    args = args(2:end);
                    
                case 'grpdesc'
                    grpDesc = args{2};
                    args = args(2:end);
                    
                case 'nperplot'
                    nGroupsPerSubPlot= args{2};
                    args = args(2:end);
                    
                case 'noclf'
                    doCLF = false;
                    
                otherwise
                    error('Unsupported argument "%s"!', args{1});
            end
            args = stripArgs(args(2:end));
        end
        
        if ~isempty(nGroupsPerSubPlot) && length(displayArgs.figid) > 1
            error('You asked to divide figure into sub-plots, so you cannot use "FigID" to specify a specific subplot');
        end
        
    end


end

