function plotVelocityProfile(expData, varargin)
%plotVelocityProfile(expData, ...) - 
% plot the trial velocity graph per trial, with the velocity onset/s and
% peaks/s.
% To update velocity information, call findVelocityOnset()
% 
% expData: one subject data, or struct with several subjects.
% 
% Optional args:
% TrialInd <#> : index of first trial to show
% TrialNum <#> : plot trial with this TrialNum
% Target <num/s>: show this target number(s)
% SmoothArgs <cell-array>: smoothing parameters for tt.vel.getTrialVelocity
% SmoothSD <stdev>: Gaussian smoothing parameter for tt.vel.getTrialVelocity
% ThreshAttr <...>: a custom attribute that contains the peak velocity
%                   threshold. Specify "e.attr" or "t.attr" for 
%                   experiment / trial attributes, or "None".
% AttrPrefix <...>: The prefix of the per-trial custom attributes that contain
%                 onset/peak information.
% CustomOutFile <filename>: filename where manually-encoded velocity+peak
%                will be written
% CustomBtn <label> <callback-func>
% Interactive : use the mouse to mark velocity onset, the keyboard accept/reject and proceed
% YLim <ylim>
% MaxTime <time>
% Acc           : Plot acceleration
% AccBursts     : Plot time windows of acceleration bursts
% NoOnset       : Don't plot onset and peak times
% VelocitySource trial/recalc: whether to plot the velocity/acceleration
%               from the trajectory matrix, or recalculate it (which is the default).
% IsRightSideFunc func(trial,expData)->Boolean : check whether the trial's
%               target is on the right half of the screen
% GetTargetFunc func(trial)->String : get the trial's target (show on top)

    ONSET_ATTR_COLORS = {'red', 'blue', mycolors.orange, mycolors.purple};
    
    customOnset = [];
    customPeak = [];
    customSaveBtn = [];
    selectedXPlotHandle = [];
    selectedXCoord = [];
    nTrialsProcessed = 0;
    
    [trialInd, trialsToPlot, smoothArgs, onsetsAttr, peakTimesAttr, plotThresholdBothSides, peakVelocitiesAttr, ...
        showRefValue, getRefValueFunc, condName, customOutFilename, onFinishedCallback, customButtonCallback, ...
        onKeyCallback, customButtonLabel, interactive, showTargetNumber, plotOnsetsAndPeaks, plotAcceleration, ...
        plotAccelerationBursts, yLim, maxX, recalcVelocity, startAtTrial, isTargetOnRightSideFunc, getTargetFunc, ...
        velocityAxes, flipXDirTrialFilter] = parseArgs(varargin, expData);
    
    if plotAcceleration
        disp('NOTE: the acceleration plotted is 1/10 of the real acceleration value');
    end
    
    if isempty(trialsToPlot)
        if ~isempty(onFinishedCallback)
            onFinishedCallback();
        end
        return;
    end
    
    if isempty(yLim)
        yLim = getYLim(expData);
    end
    
    
    if ~isempty(customOutFilename) && ~exist(customOutFilename, 'file')
        fh = fopen(customOutFilename, 'a');
        fprintf(fh, 'Condition,Subject,TrialNum,Onset,Peak,Override,WrongDir,ChangeOfMind\n');
        fclose(fh);
    end
    
    if (startAtTrial > 0)
        trialInd = startAtTrial;
    end
    
    plotTrial();
    
    %------------------------------------------------
    function onClickPrev(hObj,event,ax) %#ok<INUSD>
        clearKeyPressListener();
        trialInd = max(trialInd-1, 1);
        plotTrial();
    end

    function onClickNext(hObj,event,ax) %#ok<INUSD>
        clearKeyPressListener();
        if (trialInd >= length(trialsToPlot) && ~isempty(onFinishedCallback))
            onFinishedCallback();
            return;
        end
        trialInd = min(trialInd+1, length(trialsToPlot));
        plotTrial();
    end

    function onCustomButton(hObj,event,ax) %#ok<INUSD>
        customButtonCallback();
    end

    %------------------------------------------------
    function saveCustomData(wrongDir,changeOfMind)
        trial = trialsToPlot(trialInd);
        fh = fopen(customOutFilename, 'a');
        hasOnset = ~isempty(trial.Custom.XVelocityOnsetTime);
        fprintf(fh, '%s,%s,%d,%s,%s,%d,%d,%d\n', condName, expData.SubjectInitials, trial.TrialNum, get(customOnset, 'String'), get(customPeak, 'String'), hasOnset, wrongDir, changeOfMind);
        fclose(fh);
        delete(customSaveBtn);
    end
    

    %------------------------------------------------
    function yLim = getYLim(expData)
        yLim = [999999,-999999];
        for trial = expData.Trials
            if recalcVelocity
                velInfo = tt.vel.getTrialVelocity(trial, smoothArgs);
                yLim(1) = min([yLim(1); velInfo.velocity]);
                yLim(2) = max([yLim(2); velInfo.velocity]);
            else
                yLim(1) = min([yLim(1); trial.Trajectory(:, TrajCols.XVelocity)]);
                yLim(2) = max([yLim(2); trial.Trajectory(:, TrajCols.XVelocity)]);
            end
        end
    end

    %------------------------------------------------
    function plotTrial
        
        nTrialsProcessed  = nTrialsProcessed  + 1;
        trial = trialsToPlot(trialInd);
        
        clf;
        hold on;
        
        if plotOnsetsAndPeaks
            plotMaxVelocityStaticInfo(trial);
        end
        
        selectedXPlotHandle = [];
        
        
        VEL_COLORS = {'black', 'red', 'blue', 'cyan'};
        iColor = 1;
        legendEntries = {};
        
        for iAxis = 1:length(velocityAxes)
            
            if (recalcVelocity)
                velInfo = tt.vel.getTrialVelocity(trial, 'Axis', velocityAxes{iAxis}, 'Acc', smoothArgs);
                times = velInfo.times;
                velocity = velInfo.velocity;
                acceleration = velInfo.acceleration / 10;
            else
                times = trial.Trajectory(:, TrajCols.AbsTime);
                velocity = trial.Trajectory(:, TrajCols.XVelocity);
                acceleration = trial.Trajectory(:, TrajCols.XAcceleration) / 10;
            end

            if flipXDirTrialFilter(trial) && strcmp(velocityAxes{iAxis}, 'x')
                velocity = -velocity;
                acceleration = -acceleration;
            end
            
            % Plot the velocity
            plot(times, velocity, 'color', VEL_COLORS{iColor});
            iColor = iColor+1;
            legendEntries = [legendEntries {strcat(velocityAxes{iAxis}, ' velocity')}]; %#ok<AGROW>
            
            if plotAcceleration
                plot(times, acceleration, 'color', VEL_COLORS{iColor});
                legendEntries = [legendEntries {strcat(velocityAxes{iAxis}, ' acceleration')}]; %#ok<AGROW>
            end
            iColor = iColor+1;
            
        end
        
        legend(legendEntries, 'Location', 'NorthEast');
        
        if plotAccelerationBursts
            accBurstStartTimes = trial.Trajectory(trial.Custom.XAccelBurstsStartRows, TrajCols.AbsTime);
            accBurstEndTimes = trial.Trajectory(trial.Custom.XAccelBurstsEndRows, TrajCols.AbsTime);
            
            % Plot each burst in one color
            for i = 1:length(accBurstStartTimes)
                if (i > length(ONSET_ATTR_COLORS))
                    break;
                end

                plot([accBurstStartTimes(i) accBurstStartTimes(i)], yLim, 'color', ONSET_ATTR_COLORS{i}, 'HandleVisibility', 'off');
                plot([accBurstEndTimes(i) accBurstEndTimes(i)], yLim, 'color', ONSET_ATTR_COLORS{i}, 'HandleVisibility', 'off');
            end
            
        end
        
        if plotOnsetsAndPeaks
            
            onsetTimes = trial.Custom.(onsetsAttr);
            if isfield(trial.Custom, peakTimesAttr)
                peakTimes = trial.Custom.(peakTimesAttr);
                peakVels = trial.Custom.(peakVelocitiesAttr);
            else
                peakTimes = [];
                peakVels = [];
            end
            if isfield(expData.Custom, 'VelocityOnsetPercentOfPeak')
                thresholds = peakVels * expData.Custom.VelocityOnsetPercentOfPeak;
            else
                thresholds = [];
            end
            if (length(peakTimes) > length(ONSET_ATTR_COLORS))
                error('Trial #%d has %d peaks, but the function defined only %d colors', trial.TrialNum, length(peakTimes), length(ONSET_ATTR_COLORS));
            end

            % Plot onset-peak pairs
            for i = 1:max(length(onsetTimes), length(peakTimes))
                if (i > length(ONSET_ATTR_COLORS))
                    break;
                end
                if (i <= length(peakTimes))
                    plot([peakTimes(i) peakTimes(i)], yLim, 'color', ONSET_ATTR_COLORS{i}, 'HandleVisibility', 'off');
                    if ~isempty(thresholds)
                        plot([0 maxX], [thresholds(i) thresholds(i)], 'color', ONSET_ATTR_COLORS{i}, 'HandleVisibility', 'off');
                    end
                end
                if (i <= length(onsetTimes))
                    plot([onsetTimes(i) onsetTimes(i)], yLim, 'color', ONSET_ATTR_COLORS{i}, 'HandleVisibility', 'off');
                end
            end
        end
        
        set(gca, 'XLim', [0 2]);
        set(gca, 'YLim', yLim);
        set(gca, 'XTick', 0:0.2:maxX);
        
        grid on;
        if (showTargetNumber)
            titleText = sprintf('Velocity onset for %s, trial #%d (num=%d, target=%s)', expData.SubjectInitials, trial.TrialIndex, trial.TrialNum, getTargetFunc(trial));
        else
            titleText = sprintf('Velocity onset for %s, trial #%d (num=%d)', expData.SubjectInitials, trial.TrialIndex, trial.TrialNum);
        end
        title(titleText, 'FontSize', 24);
        xlabel('Time (sec)', 'FontSize', 16);
        ylabel('Velocity', 'FontSize', 16, 'Rotation', 0);
        set(gca, 'FontSize', 16);
        set(gcf, 'color', 'white');
        
        uicontrol('Parent', gcf, ...
                  'Style', 'pushbutton', ...
                  'Position', [5 35 80 20], ...
                  'String', 'Prev', ...
                  'Callback', @onClickPrev);
        uicontrol('Parent', gcf, ...
                  'Style', 'pushbutton', ...
                  'Position', [105 35 80 20], ...
                  'String', 'Next', ...
                  'Callback', @onClickNext);
              
        if ~isempty(customOutFilename)
            
            customSaveBtn = uicontrol('Parent', gcf, ...
                      'Style', 'pushbutton', ...
                      'Position', [405 35 80 20], ...
                      'String', 'Save', ...
                      'Callback', @(~,~,~)saveCustomData(0,0));
                  
            customOnset = uicontrol('Parent', gcf, ...
                      'Style', 'edit', ...
                      'FontSize', 12, ...
                      'Position', [205 35 80 20], ...
                      'String', 'onset');
                  
            customPeak = uicontrol('Parent', gcf, ...
                      'Style', 'edit', ...
                      'FontSize', 12, ...
                      'Position', [305 35 80 20], ...
                      'String', 'peak');
                  
        end
    
        if ~isempty(customButtonCallback)
            uicontrol('Parent', gcf, ...
                      'Style', 'pushbutton', ...
                      'Position', [505 35 80 20], ...
                      'String', customButtonLabel, ...
                      'Callback', @onCustomButton);
        end                  
        
        if (interactive)
            set(gca, 'ButtonDownFcn', @onMouseClick);
            set(get(gca, 'Children'), 'ButtonDownFcn', @onMouseClick);
            set(gcf, 'KeyPressFcn', @onKeyPress);
        end
        
    end

    %------------------------------------------------
    function onMouseClick(~, ~)
        
        coord = get(gca, 'CurrentPoint');
        x = coord(1,1);
        set(customOnset, 'String', sprintf('%.3f', x));
        
        selectedXCoord = [x x];
        if isempty(selectedXPlotHandle)
            yLim = get(gca, 'YLim');
            selectedXPlotHandle = plot(selectedXCoord, yLim, 'Color', mycolors.darkgreen, 'LineStyle', '--', 'LineWidth', 2, 'HandleVisibility', 'off');
            set(selectedXPlotHandle,'XDataSource','selectedXCoord');
        else
            refreshdata(selectedXPlotHandle, 'caller');
        end
        
    end

    %------------------------------------------------
    function onKeyPress(~, ~)
        
        currChar = get(gcf, 'CurrentCharacter');
        accept = strcmpi(currChar, 'a');
        acceptWrongDir = strcmpi(currChar, 'w');
        acceptCOM = strcmpi(currChar, 'c');
        
        accept = accept || acceptWrongDir || acceptCOM;
        if (accept)
            % accept and continue
            saveCustomData(acceptWrongDir, acceptCOM);
            onClickNext();
        elseif strcmpi(currChar, 'x')
            % Delete onset and continue
            set(customOnset, 'String', 'onset');
            saveCustomData(acceptWrongDir, acceptCOM);
            onClickNext();
        elseif strcmpi(currChar, ' ')
            % Just continue
            onClickNext();
        else
            onKeyCallback(currChar, nTrialsProcessed);
        end
        
    end

    %------------------------------------------------
    function clearKeyPressListener
        if (interactive)
            set(gcf, 'KeyPressFcn', @(~,~)1);
        end
    end

    %------------------------------------------------
    function plotMaxVelocityStaticInfo(trial)
        if ~showRefValue
            return;
        end
        
        refVal = getRefValueFunc(expData, trial);
        
        % Enhance one side with a rectangle
        if ~isempty(isTargetOnRightSideFunc)
            if isTargetOnRightSideFunc(trial, expData)
                fillCoords = [0 0; 0 yLim(2); maxX yLim(2); maxX 0];
            else
                fillCoords = [0 0; 0 yLim(1); maxX yLim(1); maxX 0];
            end
            fill(fillCoords(:,1), fillCoords(:,2), [.8 1 .8], 'LineStyle', 'none', 'HandleVisibility', 'off');
        end
        
        if isfield(expData.Custom, 'VelocityOnsetMinTime')
            minTime = expData.Custom.VelocityOnsetMinTime;
            plot([minTime minTime], yLim, 'color', 'green', 'LineStyle', '--', 'HandleVisibility', 'off');
        end
        
        if ~isempty(refVal)
            if (plotThresholdBothSides || trial.Target >= expData.MaxTarget/2)
                plot([0 maxX], [refVal refVal], 'color', 'green', 'LineStyle', '--', 'HandleVisibility', 'off');
            else
                plot([0 .25], [refVal refVal], 'color', 'green', 'LineStyle', '--', 'HandleVisibility', 'off');
            end

            if (plotThresholdBothSides || trial.Target <= expData.MaxTarget/2)
                plot([0 maxX], -[refVal refVal], 'color', 'green', 'LineStyle', '--', 'HandleVisibility', 'off');
            end
            
            text('String', 'Max velocity threshold', 'Color', mycolors.darkgreen, 'Position', [0.01 refVal+yLim(2)*0.03], 'FontSize', 14);
        end
        
        
    end
    
    %------------------------------------------------
    function [trialInd, trialsToPlot, smoothArgs, onsetsAttr, peakTimesAttr, plotThresholdBothSides, ...
            peakVelocitiesAttr, showRefValue, getRefValueFunc, condName, customOutFilename, ...
            onFinishedCallback, customButtonCallback, onKeyCallback, customButtonLabel, interactive, ...
            showTargetNumber, plotOnsetsAndPeaks, plotAcceleration, plotAccelerationBursts, userYLim, maxX, ...
            recalcVelocity, startAtTrial, isTargetOnRightSideFunc, getTargetFunc, velocityAxes, flipXDirTrialFilter] = parseArgs(args, expData)
        
        smoothArgs = {'Gauss', 0.02};
        smoothArgsChanged = false;
        trialInd = 1;
        showRefValue = true;
        getRefValueFunc = @(expData,trial)getStructAttrSafe(expData.Custom, 'PeakVelocityThreshold');
        onsetsAttr = 'XVelocityOnsetTimes';
        peakTimesAttr = 'XVelocityPeakTimes';
        peakVelocitiesAttr = 'XVelocityPeaks';
        trialsToPlot = expData.Trials;
        customOutFilename = '';
        onFinishedCallback = [];
        customButtonCallback = [];
        customButtonLabel = '';
        plotThresholdBothSides = true;
        interactive = 0;
        condName = 'something';
        showTargetNumber = 1;
        onKeyCallback = @(key,nTrials)1;
        plotOnsetsAndPeaks = true;
        plotAcceleration = false;
        plotAccelerationBursts = false;
        userYLim = [];
        maxX = 2;
        recalcVelocity = true;
        startAtTrial = -1;
        isTargetOnRightSideFunc = iif(isa(expData, 'NLExperimentData'), @(trial,expData)trial.Target >= expData.MaxTarget/2, []);
        velocityAxes = {'x'};
        getTargetFunc = @(trial)sprintf('%d', trial.Target);
        flipXDirTrialFilter = @(t)false;
        
        args = stripArgs(args);
        while ~isempty(args)
            switch(lower(args{1}))
                case 'smoothsd'
                    smoothArgs = {'Gauss', args{2}};
                    smoothArgsChanged = true;
                    args = args(2:end);
                    
                case 'smooth'
                    smoothArgs = args{2};
                    smoothArgsChanged = true;
                    args = args(2:end);
                    
                case 'trialind'
                    trialInd = args{2};
                    if length(trialInd) > 1
                        trialsToPlot = trialsToPlot(trialInd);
                        trialInd = 1;
                    end
                    args = args(2:end);
                    
                case 'trialnum'
                    trialNum = args{2};
                    trialsToPlot = trialsToPlot(arrayfun(@(t)t.TrialNum, trialsToPlot) == trialNum);
                    args = args(2:end);
                    
                case 'target'
                    target = args{2};
                    trialsToPlot = expData.getTrialsByTarget(target);
                    args = args(2:end);
                    
                case 'trialfilter'
                    filterFunc = args{2};
                    trialsToPlot = expData.Trials(arrayfun(filterFunc, expData.Trials));
                    args = args(2:end);
                    
                case 'noref'
                    showRefValue = false;
                    
                case 'threshattr'
                    refAttrArg = args{2};
                    args = args(2:end);
                    
                    dotInd = strfind(refAttrArg, '.');
                    if length(dotInd) ~= 1
                        error('Invalid "RefAttr" argument: expecting t.attr or e.attr!');
                    end
                    refAttrName = refAttrArg(dotInd+1:end);
                    switch(lower(refAttrArg(1:dotInd-1)))
                        case 'e'
                            getRefValueFunc = @(expData,trial)getStructAttrSafe(expData.Custom, refAttrName);
                        case 't'
                            getRefValueFunc = @(expData,trial)getStructAttrSafe(trial.Custom, refAttrName);
                        otherwise
                            error('Invalid "RefAttr" argument: expecting t.attr or e.attr!');
                    end
                    
                case 'attrprefix'
                    onsetsAttr = strcat(args{2}, 'OnsetTimes');
                    peakTimesAttr = strcat(args{2}, 'PeakTimes');
                    peakVelocitiesAttr = strcat(args{2}, 'Peaks');
                    args = args(2:end);
                    
                case 'customoutfile'
                    customOutFilename = args{2};
                    args = args(2:end);
                    
                case 'custombtn'
                    customButtonLabel = args{2};
                    customButtonCallback = args{3};
                    args = args(3:end);
                    
                case 'onfinished'
                    onFinishedCallback = args{2};
                    args = args(2:end);
                    
                case 'onkey'
                    onKeyCallback = args{2};
                    args = args(2:end);
                    
                case 'condition'
                    condName = args{2};
                    args = args(2:end);
                    
                case 'thrsh1side'
                    plotThresholdBothSides = false;
                    
                case 'interactive'
                    interactive = 1;
                    
                case 'hidetarget'
                    showTargetNumber = 0;
                    
                case 'noonset'
                    plotOnsetsAndPeaks = false;
                    
                case 'acc'
                    plotAcceleration = true;
                    
                case 'accburst'
                    plotAccelerationBursts = true;
                    
                case 'velocitysource'
                    switch(lower(args{2}))
                        case 'trial'
                            recalcVelocity = false;
                        case 'recalc'
                            recalcVelocity = true;
                        otherwise
                            error('Invalid VelocitySource argument: "%s"', args{2});
                    end
                    args = args(2:end);
                    
                case 'axis'
                    switch(lower(args{2}))
                        case 'x'
                            velocityAxes = {'x'};
                        case 'y'
                            velocityAxes = {'y'};
                        case 'both'
                            velocityAxes = {'x', 'y'};
                        otherwise
                            error('Invalid "Axis" argument (%s)!', args{2});
                    end
                    args = args(2:end);
                    
                case 'ylim'
                    userYLim = args{2};
                    args = args(2:end);
                    
                case 'maxtime'
                    maxX = args{2};
                    args = args(2:end);
                    
                case 'startattrial'
                    startAtTrial = args{2};
                    args = args(2:end);
                    if (startAtTrial > length(expData.Trials))
                        error('Invalid "StartAtTrial" argument (%d): Subject %s has only %d trials', startAtTrial, expData.SubjectInitials, length(expData.Trials));
                    end
                    
                case 'isrightsidefunc'
                    isTargetOnRightSideFunc = args{2};
                    args = args(2:end);
                    
                case 'gettargetfunc'
                    getTargetFunc = args{2};
                    args = args(2:end);
                    
                case 'flipxfor'
                    flipXDirTrialFilter = args{2};
                    args = args(2:end);
                    
                otherwise
                    error('Unsupported arg: %s', args{1});
            end
            args = stripArgs(args(2:end));
        end
        
        if isempty(onsetsAttr)
            error('"AttrPrefix" not specified!');
        end
        
        if smoothArgsChanged && ~recalcVelocity
            fprintf('WARNING: Smoothing arguments are ignored when taking the velocity from the trial\n');
        end
        
        smoothArgs = [{'Smooth'} smoothArgs];
        
        if length(velocityAxes) > 1 && plotOnsetsAndPeaks
            error('Onset & peak cannot be plotted when you plot both x and y velocities!');
        end
        
        if ismember('y', velocityAxes)
            recalcVelocity = true;
        end
        
    end

end

