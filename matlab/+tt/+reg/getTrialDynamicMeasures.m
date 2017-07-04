function [measures, outMeasureNames, measureDescs] = getTrialDynamicMeasures(expData, trials, inMeasureNames, rowNums)
%[measures, measureNames, measureDescs] = getTrialDynamicMeasures(expData, trials, measureNames, rowNums)
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
    
    nTrials = length(trials);
    nMeasures = length(inMeasureNames);
    nTimePoints = size(rowNums, 2);
    maxRowPerTrial = repmat(arrayfun(@(t)size(t.Trajectory, 1), trials), 1, nTimePoints);

    measures = NaN(nTrials, nMeasures, nTimePoints);
    outMeasureNames = inMeasureNames;
    measureDescs = cell(1, nMeasures);
    
    for iMeasure = 1:nMeasures

        currMeasure = [];
        
        tokens = regexp(inMeasureNames{iMeasure}, '^Traj\.(\w+)$', 'tokens');
        if ~isempty(tokens) && ~(length(tokens) == 1 && isempty(tokens{1}))
            trajColName = tokens{1}{1};
            currMeasure = getTrajectoryColumn(trials, trajColName, rowNums);
            measures(:, iMeasure, :) = currMeasure;
            outMeasureNames{iMeasure} = ['traj_' trajColName];
            continue;
        end
        
        [measureName, measureArgs] = tt.reg.internal.parseMeasureName(inMeasureNames{iMeasure}); %#ok<ASGLU>
        currMeasureDesc = ''; %#ok<NASGU>
        
        switch(measureName)
            case 'x'
                currMeasure = getTrajectoryColumn(trials, TrajCols.X, rowNums);
                currMeasureDesc = 'x coord';
                
            case 'x_nl'
                x = getTrajectoryColumn(trials, TrajCols.X, rowNums);
                measures(:, iMeasure, :) = expData.xToNumber(x);
                outMeasureNames{iMeasure} = 'x';
                currMeasureDesc = 'x value';
                
            case 'xvel'
                currMeasure = getTrajectoryColumn(trials, TrajCols.XVelocity, rowNums);
                currMeasureDesc = 'x speed';
                
            case 'y'
                currMeasure = getTrajectoryColumn(trials, TrajCols.Y, rowNums);
                currMeasureDesc = 'y coord';
                
            case 'yvel'
                currMeasure = getTrajectoryColumn(trials, TrajCols.YVelocity, rowNums);
                currMeasureDesc = 'y speed';
                
            case 'yacc'
                currMeasure = getTrajectoryColumn(trials, TrajCols.YAcceleration, rowNums);
                currMeasureDesc = 'y acceleration';
                
            case 'ivel'
                % Instantaneous speed (= speed in the xy direction)
                currMeasure = getInstVelocity(trials, rowNums);
                currMeasureDesc = 'xy speed';
                
            case {'ep', 'iep'}
                currMeasure = getTrajectoryColumn(trials, TrajCols.ImpliedEP, rowNums);
                currMeasureDesc = 'Implied endpoint';
                
            case {'rldir', 'rldir_like_final', 'rldir_like_final01'}
                % Currently pointing to right/left
                iep = getTrajectoryColumn(trials, TrajCols.ImpliedEP, rowNums);
                if isNL
                    currDir = (iep > expData.MaxTarget/2) * 2 - 1;
                else
                    currDir = sign(iep);
                end

                if strcmp(measureName, 'rldir')
                    % Measure is the current direction (-1 or +1; 0 = N/A)
                    currMeasure = currDir;
                else
                    % Measure is the match between current direction and final response (-1 or +1; 0 = N/A)
                    finalResponse = arrayfun(@(t)t.UserResponse, trials) * 2 - 1;
                    finalResponse = repmat(finalResponse, 1, nTimePoints);
                    currMeasure = (currDir == finalResponse) * 2 - 1;
                    currMeasure(currDir == 0) = 0;
                end
                if strcmp(measureName, 'rldir_like_final01')
                    currMeasure = currMeasure > 0;
                end
                currMeasureDesc = 'L/R';
                
            case 'iep_vs_expected_response'
                % Implied endpoint, multiplied by expected response
                iep = getTrajectoryColumn(trials, TrajCols.ImpliedEP, rowNums);
                expectedResp = sign(arrayfun(@(t)t.RequiredResponse, trials) - 0.5); % code as -1 or +1
                for ii = 1:size(iep, 2)
                    iep(:, ii) = iep(:, ii) .* expectedResp;
                end
                currMeasure = iep;
                
                currMeasureDesc = 'L/R correct';

            otherwise
                error('Unknown measure name "%s"', measureName);
        end

        if isempty(currMeasure)
            error('Huh? the measure was not calcualted!');
        end
        
        measures(:, iMeasure, :) = currMeasure;
        measureDescs{iMeasure} = iif(isempty(currMeasureDesc), measureName, currMeasureDesc);

    end
    
    %------------------------------------------
    % Get traj column from several trials in several time points
    % Return a trials x timepoints matrix
    function currMeasure = getTrajectoryColumn(trials, colSpec, rowNums)
        
        if isnumeric(colSpec)
            colNum = colSpec;
        else
            colNum = TrajCols.colByName(colSpec);
            if isnan(colNum)
                error('There is no trajectory column "%s"', colSpec);
            end
        end
        
        %-- Make sure we don't exceed end of trial
        rowNums = min(rowNums, maxRowPerTrial);
        
        currMeasure = NaN(nTrials, nTimePoints);
        for i = 1:length(trials)
            currMeasure(i, :) = trials(i).Trajectory(rowNums(i,:), colNum)';
        end
    end

    %------------------------------------------
    function currMeasure = getInstVelocity(trials, rowNums)
        currMeasure = NaN(length(trials), size(rowNums,2));
        for itr = 1:length(trials)
            trial = trials(itr);
            trialRows = rowNums(itr, :);
            velInf = tt.vel.getTrialVelocity(trial, 'Axis', 'xy');
            v = velInf.velocity';
            if length(v) < max(trialRows)
                v = [v repmat(v(end), 1, max(trialRows)-length(v))];
            end
            currMeasure(itr, :) = v(trialRows);
        end
    end

end

