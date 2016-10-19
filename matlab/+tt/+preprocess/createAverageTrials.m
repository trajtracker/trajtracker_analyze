function createAverageTrials(expData, varargin)
%createAverageTrials(expData, ...) -
% Create trials with median trajectories
% 
% Optional arguments:
% ===================
% GrpFunc <function>: a function @(trial)->number for grouping trials.
%                     Trials with the same group number will be averaged.
%                     Trials with group=NaN will not be aveaged.
%                     Default: group trials by target (requires numeric
%                     targets)
% AvgForGroups <array>: Calculate average trials for each of these groups,
%                     in this order. 
%                     Default: calculate for all available groups.
% Norm: Average by normalized time, not absolute time. 

    [trialGroupingFunc, trialGroups, byAbsTimes] = parseArgs(varargin, expData);
    
    trials = expData.Trials(arrayfun(@(t)t.ErrCode==TrialErrCodes.OK, expData.Trials));
    groupPerTrial = arrayfun(trialGroupingFunc, trials);
    
    if isempty(trialGroups)
        trialGroups = unique(groupPerTrial);
        trialGroups = trialGroups(~isnan(trialGroups));
    end
    
    averageTrials = [];
    
    for group = trialGroups
        
        grpTrials = trials(groupPerTrial==group);
        
        switch (length(grpTrials))
            case 0
                averageTrials = [averageTrials getDummyTrial(expData)]; %#ok<*AGROW>
                
            case 1
                averageTrials = [averageTrials grpTrials];
                
            otherwise
                
                if byAbsTimes
                    trial = tt.preprocess.createAvgTrial(expData, grpTrials, 'abs', 'median');
                else
                    trial = tt.preprocess.createAvgTrial(expData, grpTrials, 'norm', 'median');
                end
                averageTrials = [averageTrials trial];
                
        end
        
    end
    
    if byAbsTimes
        expData.AvgTrialsAbs = averageTrials;
    else
        expData.AvgTrialsNorm = averageTrials;
    end
    
    %-------------------------------------------------------------------
    function t = getDummyTrial(expData)
        switch(expData.ExperimentPlatform)
            case 'NL'
                t = NLOneTrialData(-1,-1);
            case 'DC'
                t = GDOneTrialData(-1,-1);
            otherwise
                error('Unsupported platform "%s"', expData.ExperimentPlatform);
        end
        
        t.ErrCode = TrialErrCodes.Filler;
    end
    
    
    %-------------------------------------------
    function [trialGroupingFunc, trialGroups, byAbsTimes] = parseArgs(args, expData)

        trialGroupingFunc = @(trial)trial.Target;
        trialGroups = [];
        if strcmp(expData.ExperimentPlatform, 'NL'), trialGroups = 0:expData.MaxTarget; end;
        byAbsTimes = true;
        
        args = stripArgs(args);
        while ~isempty(args)
            switch(lower(args{1}))
                case 'grpfunc'
                    trialGroupingFunc = args{2};
                    args = args(2:end);
                    
                case 'avgforgroups'
                    trialGroups = args{2};
                    args = args(2:end);
                    
                case 'norm'
                    byAbsTimes = false;
                    
                otherwise
                    error('Unsupported argument "%s"!', args{1});
            end
            args = stripArgs(args(2:end));
        end

    end

end

