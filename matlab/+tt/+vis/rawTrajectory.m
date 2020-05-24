function rawTrajectory(expData, varargin)
% rawTrajectory(data, ...) - draw single-trial trajectories
%
% data: either an ExperimentData object or a dataset struct (xxx.d or xxx.raw).
% 
% 
% Optional arguments:
% -------------------
% 
% >>> Which trials to plot:
% 
% Targets <targets>: plot only trials with these targets. <targets> is an
%                    array of numeric targets, or cell array.
% TrialNum <numbers>: lot only trials with these TrialNum. 
% TrialFilter @(trial)->BOOL: specify custom filtering function.
% Sort @(trial)->number: this function determines how to sort trials when
%          plotting. Trials with higher sort index are plotted on top of
%          smaller-index trials.
%          By default, sorting by order of trials in the experiment. If
%          several subjects are plotted, sorting is done first by subjects.
%          To sort in reverse order you can, instead of writing a function,
%          write 'Reverse'.
% 
% 
% >>> Which info to plot per trial:
% 
% X TrajCols.###: Column from trajectory matrix to use for the x axis
% Y TrajCols.###: Column from trajectory matrix to use for the y axis
% YTime: Use TrajCols.AbsTime for the Y axis
% 
% The following arguments are intended for plotting sections within each
% trajectory. After identifying sub-sections in a trajectory, you can
% define the start/end of each section using two custom attributes that
% specify the traj-matrix row numbers of each section's start and end
% 
% TrajSectionAttrPrefix <pref>: The row numbers are expected on custom
%            attributes <pref>StartRows and <pref>EndRows
% TrajSectionAttrs <start-rows-attr-name> <end-rows-attr-name>: Explicitly
%            specify the attribute names.
% 
% 
% >>> Determining the color of each trial
% 
% ColorFunc
% ColorByAttr
% ColorByCustomattr
% ColorIDFunc
% Colors
% 
% >>> Setting the figure's look
% 
% Grid: show a grid
% Title <text>: figure title
% XLabel <text>: Label for X axis
% YLabel <text>: Label for Y axis
% XLim [min max]: 
% YLim [min max]: 
% XTick <delta>: Delta between x ticks
% YTick <delta>: Delta between y ticks
% WinSize [width height]: Set the figure window size (in pixels)
% FigID <#>: Matlab figure ID
% FontSize <#>
% LineWidth <#>
% 
% >>> Adding more info on the figure
% 
% NoCLF: Don't do clf before starting to plot. This is useful if you plot
%        something beforehand.
% ShowTargets: Show the target numbers (in a number-to-position task) or
%        the response buttons (in a decision task).
% RespButtonColor: relevant for decision task
% PlotBgndFunc <func>: use this function (instead of the default) to plot
%           the background. Function signature: @(expData, trials, colors, args)
%           where 'colors' is a color per trial, 'args' is some arguments
%           (see the code for details)

    if isa(expData, 'ExperimentData')
        anyED = expData;
    elseif isstruct(expData) && isfield(expData, 'general') && isstruct(expData.general)
        anyED = tt.util.structToArray(expData, 'Any');
    else
        error('Invalid input to function: the first arg should be either the experiment data of a single subject or the struct with experiment data of all subjects!');
    end
    isNL = isa(anyED, 'NLExperimentData');

    [xCol, yCol, convertXToNumber, trialFilters, sortTrialsFunc, trajSectionAttrs, getColorPerTrialFunc, ...
        getLineStyleFunc, plotBackgroundFunc, args, showElements] = parseArgs(varargin, anyED);
    
    trials = getTrials(expData, trialFilters, sortTrialsFunc);
    colorPerTrial = getColorPerTrialFunc(trials);
    
    if isfield(args, 'figid'), setFigure(args.figid, 0); end
    if showElements.CLF, clf; end
    hold on;
    
    if showElements.Targets
        plotBackgroundFunc(anyED, trials, colorPerTrial, args);
    end
    
    for iTrial = 1:length(trials)
        
        trial = trials(iTrial);
        color = colorPerTrial{iTrial};
        lineStyle = getLineStyleFunc(trial);
        
        x = trial.Trajectory(:,xCol);
        if convertXToNumber
            x = anyED.xToNumber(x); % todo: is this OK that we do it with any expData rather with the trial's specific one?
        end
        y = trial.Trajectory(:,yCol);
        
        tag = sprintf('ind=%d;trg=%d;subj=%s', trial.TrialIndex, trial.Target ,trial.Subject);
        
        plot(x, y, 'Color', color, 'LineStyle', lineStyle, 'LineWidth', args.linewidth, 'Tag', tag);
        
        %-- highlight trajectory sections
        if ~isempty(trajSectionAttrs)
            startRows = trial.Custom.(trajSectionAttrs.start);
            endRows = trial.Custom.(trajSectionAttrs.end);
            for iSection = 1:length(startRows)
                rows = startRows(iSection) : endRows(iSection);
                plot(x(rows), y(rows), 'Color', color, 'LineStyle', lineStyle, 'LineWidth', lineWidth*2);
            end
        end
        
    end
    
    %-- Set graph appearance
    xlim(args.xlim);
    ylim(args.ylim);
    
    if showElements.Grid, grid on; end
    
    if isfield(args, 'xticks')
        set(gca, 'XTick', args.xticks);
    elseif isfield(args, 'xtick')
        setTickDelta('x', args.xtick);
    end
    if isfield(args, 'ytick'), setTickDelta('y', args.ytick); end
    set(gca, 'TickLength', [0 0]);
    set(gca, 'FontSize', args.fontsize);
    
    if isfield(args, 'title'),  title(args.title, 'FontSize', 30); end
    if isfield(args, 'xlabel'), xlabel(args.xlabel); end
    if isfield(args, 'ylabel'), ylabel(args.ylabel, 'Rotation', 0); end
    
    if ~showElements.TickLabels
        set(gca, 'XTickLabel', {});
        set(gca, 'YTickLabel', {});
    end
        
    set(gcf, 'Color', 'white');
    if isfield(args, 'winsize'), setFigWindowSize(args.winsize); end
    
    
    %---------------------------------------------------------------
    %-- Get trials to plot
    function trials = getTrials(expData, trialFilters, sortTrialsFunc)
        
        trials = tt.util.getAllTrials(expData);
        trials = tt.util.filterTrials(trials, trialFilters);

        if isempty(sortTrialsFunc)
            return;
        elseif strcmp(sortTrialsFunc, 'reverse')
            trials = trials(end:-1:1);
        elseif isa(sortTrialsFunc, 'function_handle')
            sortID = arrayfun(sortTrialsFunc, trials);
            [~,iii] = sort(sortID);
            trials = trials(iii);
        else
            error('Invalid trial sorting method: %s', sortTrialsFunc);
        end
        
    end


    %---------------------------------------------------------------
    function plotBackground(anyED, trials, colorPerTrial, args)
        
        if isNL
            
            %-- Plot the relevant target numbers
            targetPerTrial = arrayfun(@(t)t.Target, trials);
            for target = unique(targetPerTrial)
                clr = colorPerTrial{find(targetPerTrial==target, 1)}; % Get color of 1st trial with this target
                text(target, 1.05, sprintf('%2d',target), 'Color', clr, 'FontSize', args.fontsize, 'HorizontalAlignment', 'Center');
            end
            
        else
            
            %-- Plot the response buttons
            
            ppu = anyED.PixelsPerUnit;
            
            button_h = anyED.Custom.ResponseButtonHeight / ppu;
            button_w = anyED.Custom.ResponseButtonWidth / ppu;
            win_h = anyED.Custom.TrajZeroCoordY / ppu;
            win_w = anyED.Custom.WindowWidth / ppu;
            lbutton_x = - win_w/2;
            rbutton_x = win_w/2 - button_w;
            button_y = win_h - button_h;
            
            rectangle('Position', [lbutton_x, button_y, button_w, button_h], 'FaceColor', args.respbuttoncolor, 'EdgeColor', 'none');
            rectangle('Position', [rbutton_x, button_y, button_w, button_h], 'FaceColor', args.respbuttoncolor, 'EdgeColor', 'none');
            
            if ~isfield(args, 'ylim')
                args.ylim = [0 win_h];
            end
        end
        
    end

    %---------------------------------------------------------------
    function colorPerTrial = getColorPerTrial(trials, getColorFunc)
        colorPerTrial = arrayfun(getColorFunc, trials);
    end

    %---------------------------------------------------------------
    function colorPerTrial = getColorPerTrialByGroups(trials, getColorIDFunc, colors)
        colorIDs = arrayfun(getColorIDFunc, trials);
        [~,~,colorInds] = unique(colorIDs);
        if isempty(colors)
            colors = varycolor(max(colorInds), true);
        end
        colorPerTrial = colors(colorInds);
    end

    %--------------------------------------------------------------------
    function yLim = getDefaultYLimForDecisionExp(expData)
        if isfield(expData.Custom, 'TrajZeroCoordY')
            yLim = [0 (expData.Custom.TrajZeroCoordY / expData.PixelsPerUnit)];
        else
            yLim = [];
        end
    end

    %---------------------------------------------------------------
    function [xCol, yCol, convertXToNumber, trialFilters, sortTrialsFunc, trajSectionAttrs, getColorPerTrialFunc, ...
        getLineStyleFunc, plotBackgroundFunc, generalArgs, showElements] = parseArgs(args, anyED)
        
        generalArgs = struct;
    
        generalArgs.fontsize = 40;
        generalArgs.linewidth = 1.5;
        generalArgs.respbuttoncolor = [1 1 1] * .8;
        generalArgs.ShowTickLabels = true;
        
        if isNL
            generalArgs.ylim = [0 1];
            generalArgs.xticks = 0 : (anyED.MaxTarget/4) : anyED.MaxTarget;
        else
            generalArgs.ylim = getDefaultYLimForDecisionExp(anyED);
        end
        
        yCol = TrajCols.Y;
        xCol = TrajCols.X;
        trialFilters = {};
        sortTrialsFunc = [];
        getLineStyleFunc = @(trial)'-';
        
        trajSectionAttrs = [];
        
        getColorPerTrialFunc = [];
        getColorIDFunc = [];
        getColorFunc = [];
        colors = {};
        
        plotBackgroundFunc = @plotBackground;
        
        showElements = struct('Grid', false, 'CLF', true, 'Targets', false, 'TickLabels', true);
        
        args = stripArgs(args);
        while ~isempty(args)
            switch(lower(args{1}))
                %-- What to plot
                
                case 'x'
                    xCol = args{2};
                    args = args(2:end);
                    
                case 'y'
                    yCol = args{2};
                    args = args(2:end);
                    
                case 'ytime'
                    yCol = TrajCols.AbsTime;
                    
                %-- Filtering trials
                
                case 'targets'
                    targetNums = args{2};
                    args = args(2:end);
                    filter = { @(trial)ismember(trial.Target, targetNums) };
                    trialFilters = [trialFilters filter]; %#ok<AGROW>
                    
                case 'trialnum'
                    targetNums = args{2};
                    args = args(2:end);
                    filter = { @(trial)ismember(trial.TrialNum, targetNums) };
                    trialFilters = [trialFilters filter]; %#ok<AGROW>
                    
                case 'trialfilter'
                    filter = args(2);
                    args = args(2:end);
                    trialFilters = [trialFilters filter]; %#ok<AGROW>
                    
                %-- Mark portions within trials
                
                case 'trajsectionattrprefix'
                    attrPref = args{2};
                    args = args(2:end);
                    trajSectionAttrs = struct('start', [attrPref 'StartRows'], 'end', [attrPref 'EndRows']);
                    
                case 'trajsectionattrs'
                    trajSectionAttrs = struct('start', args{2}, 'end', args{3});
                    args = args(3:end);
                    
                %-- Order of plotting
                
                case 'sort'
                    sortTrialsFunc = args{2};
                    args = args(2:end);
                    
                %-- Colors/sorting
                
                case 'colors'
                    colors = args{2};
                    args = args(2:end);

                case 'colorbyattr'
                    attrName = args{2};
                    args = args(2:end);
                    getColorIDFunc = @(trial)trial.(attrName);
                    
                case 'colorbycustomattr'
                    attrName = args{2};
                    args = args(2:end);
                    getColorIDFunc = @(trial)trial.Custom.(attrName);
                    
                case 'coloridfunc'
                    getColorIDFunc = args{2};
                    args = args(2:end);
                    
                case 'colorfunc'
                    getColorFunc = args{2};
                    args = args(2:end);
                    
                case 'randcolors'
                    getColorPerTrialFunc = @(trials)varycolor(length(trials), true);
                    
                %-- misc.
                    
                case 'showtargets'
                    showElements.Targets = true;
                    
                case 'noclf'
                    showElements.CLF = false;
                    
                case 'grid'
                    showElements.Grid = true;
                    
                case 'noticklabels'
                    showElements.TickLabels = false;
                    
                case 'plotbgndfunc'
                    plotBackgroundFunc = args{2};
                    args = args(2:end);
                    
                %-- Standard args - copy their value
                case {'title', 'xlabel', 'ylabel', 'xlim', 'ylim', 'xtick', 'ytick', 'xticks', 'winsize', 'figid', 'fontsize', 'linewidth', 'respbuttoncolor'}
                    generalArgs.(lower(args{1})) = args{2};
                    args = args(2:end);
                    
                otherwise
                    error('Unknown flag %s', args{1});
            end
            args = stripArgs(args(2:end));
        end

        if ~isempty(getColorPerTrialFunc)
            % We already have the function
        elseif ~isempty(getColorFunc)
            % We have a simple function that returns a color per trial
            getColorPerTrialFunc = @(trials)getColorPerTrial(trials, getColorFunc);
        elseif ~isempty(getColorIDFunc)
            % We have a simple function that returns a color per trial
            getColorPerTrialFunc = @(trials)getColorPerTrialByGroups(trials, getColorIDFunc, colors);
        else
            getColorPerTrialFunc = @(trials)repmat({'Black'}, 1, length(trials));
        end
        
        convertXToNumber = isNL && xCol ~= TrajCols.ImpliedEP;
        
        if ~isfield(generalArgs, 'xlim')
            if isNL 
                generalArgs.xlim = [0 anyED.MaxTarget];
            else
                generalArgs.xlim = [-1 1];
            end
        end
        
    end
    
end
