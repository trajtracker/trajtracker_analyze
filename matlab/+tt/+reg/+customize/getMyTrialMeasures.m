function [measures, outMeasureNames, measureDescs] = getMyTrialMeasures(expData, trials, measureNames)
% [measures, outMeasureNames, measureDescs] = getMyTrialMeasures(expData, trials, measureNames) -
% Get values of regression measures that have one value per trial.
%
% trials - a column vector of trials (from the given expData)
% measureNames - cell array of measure names (see function for details)
%
% Return values -
% measures: matrix with cols = measures, rows = trials
% varNames: symbol name of each measure (cell array)
% measureDescs: text description of each measure (cell array)

    if (size(trials, 2) > 1)
        error('"trials" should be a column vector, but it has %d columns!', size(trials, 2));
    end
    
    measures = [];
    outMeasureNames = measureNames;
    measureDescs = cell(1, length(measureNames));

    for iMeasure = 1:length(measureNames)
        
        currMeasure = []; %#ok<NASGU>
        
        [measureName, measureArgs] = tt.reg.parsePredictorName(measureNames{iMeasure}); %#ok<ASGLU>
        currMeasureDesc = ''; %#ok<NASGU>
        
        switch(measureName)
            
            %-------- Stimulus ------------
            
            case 'MyPrivatePredictor'
                currMeasure = []; %CUSTOM: replace this with a custom code that sets currMeasure to be a column vector
                currMeasureDesc = ''; %CUSTOM: replace this with a custom code that sets measure short description (for figures)
                
            otherwise
                %-- Call default function
                [currMeasure, vn, currMeasureDesc] = tt.reg.getTrialMeasures(expData, trials, measureNames(iMeasure));
                outMeasureNames{iMeasure} = vn{1};
        end
        
        if isempty(currMeasure)
            error('Huh? the measure was not calcualted!');
        end
        
        
        measures = [measures currMeasure]; %#ok<*AGROW>
        measureDescs{iMeasure} = iif(isempty(currMeasureDesc), measureName, currMeasureDesc);
        
    end
    
end
