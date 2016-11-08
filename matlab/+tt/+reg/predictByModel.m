function [predictions, moreInf] = predictByModel(expData, regResults, varargin)
% [predictions, moreInf] = predictByModel(expData, regResults, ...) -
% Calculate the predictions (per trial) of a regression model
% 
% Optional arguments:
% -------------------
% TrialFilter @(trial)->BOOL: filtering function
% Residuals: Calculate the residuals (returned within "moreInf")
    
    [trialFilters, calcResiduals] = parseArgs(varargin);
    
    trials = tt.util.filterTrials(expData.Trials, trialFilters);
    if ~isempty(regResults.RegressionParams.ConsolidateTrialsFunc)
        trials = trials(regResults.RegressionParams.ConsolidateTrialsFunc, expData);
    end
    
    rowNums = getRowNums(regResults, trials);
    [predictorValues, depVarValues] = getPredictors(expData, trials, rowNums, regResults, calcResiduals);
    
    constInd = find(strcmp('const', regResults.predictorNames), 1);
    if ~isempty(constInd)
        predictorValues = [predictorValues(:, 1:constInd-1) ones(length(trials), 1) predictorValues(:, constInd:end)];
    end
    
    predictions = NaN(length(trials), length(rowNums));
    for iTP = 1:length(rowNums)
        bValues = arrayfun(@(pn)regResults.getPredResult(pn{1}).b, regResults.predictorNames)';
        predictions(:, iTP) = predictorValues(:, :, iTP) * bValues;
    end
    
    moreInf = struct('trials', trials);
    moreInf.times = regResults.times;
    moreInf.Platform = expData.ExperimentPlatform;
    
    if calcResiduals
        moreInf.residuals = depVarValues - predictions;
        moreInf.MSE = sum(moreInf.residuals .^ 2) / regResults.df;
    end
    

    %-------------------------------------------------------
    % Return a column vector of row numbers
    function rowNums = getRowNums(regResults, trials)
         longestTrial = tt.util.getLongestTrial(trials);
         rowNums = arrayfun(@(t)find(longestTrial.Trajectory(:, TrajCols.AbsTime) >= t-0.0001, 1), regResults.times);
    end

    %-------------------------------------------------------
    % predictorValues: either a #trials x #predictors matrix; or a #trials x #predictors x #TP matrix
    % depVarValues: either an array (#trials) or a #trials x #TP matrix
    function [predictorValues, depVarValues] = getPredictors(expData, trials, rowNums, regResults, getDepVar)
        
        %-- Get predictors
        predictorSpec = regResults.RegressionParams.PredictorSpec;
        if regResults.RegressionParams.FixedPred
            predictorValues = regResults.RegressionParams.GetTrialMeasuresFunc(expData, trials', predictorSpec);
        else
            predictorValues = regResults.RegressionParams.GetDynamicMeasuresFunc(expData, trials', predictorSpec, rowNums);
        end
        
        if ~getDepVar
            depVarValues = [];
            return;
        end
        
        %-- Get dependent variable
        depVarSpec = regResults.RegressionParams.DepVarSpec;
        if regResults.RegressionParams.FixedDepVar
            depVarValues = regResults.RegressionParams.GetTrialMeasuresFunc(expData, trials', {depVarSpec});
        else
            depVarValues = regResults.RegressionParams.GetDynamicMeasuresFunc(expData, trials', {depVarSpec}, rowNums);
        end
        
    end

    %-------------------------------------------
    function [trialFilters, calcResiduals] = parseArgs(args)

        trialFilters = {};
        calcResiduals = false;
        
        args = stripArgs(args);
        while ~isempty(args)
            switch(lower(args{1}))
                case 'trialfilter'
                    trialFilters = [trialFilters args(2)]; %#ok<AGROW>
                    args = args(2:end);

                case 'residuals'
                    calcResiduals = true;
                    
                otherwise
                    error('Unsupported argument "%s"!', args{1});
            end
            args = stripArgs(args(2:end));
        end

    end

end

