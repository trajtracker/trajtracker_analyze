function [measures, outMeasureNames, measureDescs] = getMyTrialDynamicMeasures(expData, trials, inMeasureNames, rowNums)
%[measures, measureNames] = getTrialDynamicMeasures(expData, trials, measureNames, rowNums)
% Get per-trial data that is calculated per time point.
% Used by the new regression infra.
%
% Parameters:
% ===========
% expdata: the experiment object
% trials: a column vector with trials
% inMeasureNames: the measures to calculate - cell array, as provided in
%                                             the call to the main regression function.
% rowNums: Row numbers per time point. The row numbers may differ per trial 
%          (the parameter is a #trials x #timepoints matrix)
% 
% Return value:
% =============
% measures - value per trial, measure, and time point. 
% measureNames - that will appear in regression results.

    if (size(trials, 2) > 1)
        error('"trials" should be a column vector, but it has %d columns!', size(trials, 2));
    end

    isNL = isa(expData, 'NLExperimentData');
    
    nTimePoints = size(rowNums, 2);
    nMeasures = length(inMeasureNames);
    nTrials = length(trials);
    
    measures = NaN(nTrials, nMeasures, nTimePoints);
    outMeasureNames = inMeasureNames;
    measureDescs = cell(1, length(measureNames));

    for iMeasure = 1:nMeasures

        currMeasure = []; %#ok<NASGU>
        
        [measureName, measureArgs] = tt.reg.internal.parseMeasureName(inMeasureNames{iMeasure}); %#ok<ASGLU>
        currMeasureDesc = ''; %#ok<NASGU>

        switch(lower(measureName))
            case 'mypredictor'
                currMeasure = []; %CUSTOM: replace this with a custom code that sets currMeasure to be a nTrials*nTimepoints matrix
                currMeasureDesc = ''; %CUSTOM: replace this with a custom code that sets measure short description (for figures)

            otherwise
                [cm, vn, currMeasureDesc] = tt.reg.getTrialDynamicMeasures(expData, trials, measureNames(iMeasure));
                currMeasure = cm(:, 1, :);
                outMeasureNames{iMeasure} = vn;
                
        end

        if isempty(currMeasure)
            error('Huh? the measure was not calcualted!');
        end
        
        measures(:, iMeasure, :) = currMeasure;
        measureDescs{iMeasure} = iif(isempty(currMeasureDesc), measureName, currMeasureDesc);

    end

end

