function mergedExpData = createAvgExpData(allExpData)
% expData = createAvgExpData(allED)
%
% Create mean trajectories for all the given subjects
%
% Returns: an ExperimentData object with the mean trajectories.
% The returned ExperimentData contains only AvgTrials, no raw trials.

    expDataArray = tt.util.structToArray(allExpData);
    
    if isempty(expDataArray(1).AvgTrialsAbs)
        error('The input experiments have no medians to average!');
    end
        
    switch(expDataArray(1).ExperimentPlatform)
        case 'NL'
            mergedExpData = NLExperimentData(expDataArray(1).MaxTarget, 'avg', 'Merged');
        case 'DC'
            mergedExpData = DCExperimentData('avg', 'Merged');
        otherwise
            error('Unsupported platform');
    end
    
    nAvgTrials = length(expDataArray(1).AvgTrialsAbs);
    mergedExpData.PixelsPerUnit = expDataArray(1).PixelsPerUnit;
    mergedExpData.YPixelsShift = expDataArray(1).YPixelsShift;
    mergedExpData.NLLength = expDataArray(1).NLLength;
    
    for iAvgTrial = 1:nAvgTrials

        trialsAbs = mycell2array(arrayfun(@(ed){ed.AvgTrialsAbs(iAvgTrial)}, expDataArray));
        meanAbs = tt.preprocess.createAvgTrial(mergedExpData, trialsAbs, 'abs', 'mean');
        meanAbs.Custom = trialsAbs(1).Custom;
        mergedExpData.AvgTrialsAbs = [mergedExpData.AvgTrialsAbs, meanAbs]; %#ok<*AGROW>

        if ~isempty(expDataArray(1).AvgTrialsNorm)
            trialsNorm = mycell2array(arrayfun(@(ed){ed.AvgTrialsNorm(iAvgTrial)}, expDataArray));
            meanNorm = tt.preprocess.createAvgTrial(mergedExpData, trialsNorm, 'norm', 'mean');
            meanNorm.Custom = trialsNorm(1).Custom;
            mergedExpData.AvgTrialsNorm = [mergedExpData.AvgTrialsNorm, meanNorm];
        end
        
        for trial = trialsAbs
            mergedExpData.addTrialData(trial);
        end
        
    end
    
    tt.preprocess.calcInitialDir(mergedExpData, 'averages');
    
end
