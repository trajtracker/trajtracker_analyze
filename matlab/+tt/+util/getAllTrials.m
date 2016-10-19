function [trials, samplingRate, expDataPerTrial, subjNumPerTrial, caIndPerTrial] = getAllTrials(inData)
%[trials, samplingRate, eds, subjNum, caInd] = getAllTrials(obj) - 
% get all trials of the given object, which can be either of:
% - An array of trials
% - An ExperimentData object
% - A struct with several ExperimentData objects
% - A cell array of any of the above
% 
% Returns:
% trials: array of trials
% samplingRate: of one of the trials (hopefully it's the same for all)
% eds: array (same size as "trials") of the corresponding ExpData
% subjNum: array (same size as "trials") of corresponding subject number
% caInd: array (same size as "trials") of corresponding index number
%          in the input cell array (1's if input was not a cell array)

    if isa(inData, 'ExperimentData')
        
        trials = inData.Trials;
        samplingRate = inData.SamplingRate;
        if nargout >= 3
            expDataPerTrial = myarrayfun(@(t)inData, trials);
        end
        if nargout >= 4
            subjNumPerTrial = ones(1, length(trials));
        end
        if nargout >= 5
            caIndPerTrial = ones(1, length(trials));
        end
        
    elseif isstruct(inData)
        
        allED = tt.util.structToArray(inData);
        trials = myarrayfun(@(ed)ed.Trials, allED);
        samplingRate = allED(1).SamplingRate;
        if nargout >= 3
            expDataPerTrial = myarrayfun(@(ed)repmat(ed, 1, length(ed.Trials)), allED);
        end
        if nargout >= 4
            subjNumPerTrial = myarrayfun(@(i)repmat(i, 1, length(allED(i).Trials)), 1:length(allED));
        end
        if nargout >= 5
            caIndPerTrial = ones(1, length(trials));
        end
        
    elseif isa(inData(1), 'OneTrialData')
        
        trials = inData;
        samplingRate = 1;
        subjNumPerTrial = [];
        expDataPerTrial = [];
        if nargout >= 5
            caIndPerTrial = ones(1, length(trials));
        end
        
    elseif iscell(inData)
        
        trials = [];
        samplingRate = [];
        subjNumPerTrial = [];
        expDataPerTrial = [];
        caIndPerTrial = [];
        maxSN = 0;
        for i = 1:length(inData)
            [t, sr, ed, sn] = tt.util.getAllTrials(inData{i});
            trials = [trials t]; %#ok<*AGROW>
            samplingRate = sr;
            if nargout >= 3
                expDataPerTrial = [expDataPerTrial ed];
            end
            if nargout >= 4
                subjNumPerTrial = [subjNumPerTrial sn+maxSN];
                maxSN = max(subjNumPerTrial);
            end
            if nargout >= 5
                caIndPerTrial = [caIndPerTrial repmat(i, 1, length(t))];
            end
        end
        
    else
        
        error('Unsupported argument');
        
    end

end

