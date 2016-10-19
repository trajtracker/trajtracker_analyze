classdef ExperimentData < handle
% ExperimentData - the data of one experiment (typically this contains one
% subject, one session).
% 
% This is a base class, you should use only the derived classes
% NLExperimentData or GDExperimentData
    
    properties(SetAccess=private)
        SubjectID    % Unique ID (meaningless)
        SubjectName  % Full name
        SessionID    % Unique ID of session
        Trials       % Array of OneTrialData objects
        ExperimentPlatform % 'NL' or 'DC'
    end
    
    properties
        SubjectInitials   % We typically use the initials as the subj ID
        Group             % For grouping subjects for analyses
        AvgTrialsNorm     % mean calculated by normalized time
        AvgTrialsAbs      % mean calculated by absolute time
        TotalDuration     % in seconds
        SoftwareVersion
        BuildNumber       % Numeric value
        RunDate           % Of the experiment
        SubjBirthday
        Custom            % Struct with custom attributes
    end
    
    properties(Dependent=true)
        ValidTrials       % trials which are not dummy
        SamplingRate
        MaxMovementTime
        MeanMovementTime
        MeanSpeed
        MaxTrajectoryLength
        LongestTrajectoryNSamples % No. of rows in the Trajectory matrix in the longest trajectory
        LongestTrial            % The longest from 'self.Trials'
        ShortestTrial           % The shortest from 'self.Trials'
        OKTrials                % Trials with ErrCode="OK"
        ExpDataWithOKTrials     % Clone object, leave only ErrCode="OK" trials
        ExcludeFromAverage
        FailedTrialRate
        SubjAgeDays
    end
    
    methods
        
        %==========================================
        % Constructor
        %==========================================
        function self = ExperimentData(platform, subjID, subjName, sessionID)
            self.ExperimentPlatform = platform;
            self.SubjectID = subjID;
            self.SubjectInitials = subjID;
            self.SubjectName = char(subjName);
            self.SessionID = sessionID;
            self.Custom = struct;
        end
        
        %==============================================================
        %       Dependent property
        %==============================================================
        
        function value = get.ValidTrials(self)
            value = ExperimentData.getValidTrials(self.Trials);
        end
        
        function value = get.SamplingRate(self)
            okTrials = [self.OKTrials self.AvgTrialsAbs];
            if (isempty(okTrials))
                error('ExperimentData.SamplingRate cannot be called because this experiment contains no good trial');
            end
            value = okTrials(1).SamplingRate;
        end
        
        function value = get.MaxMovementTime(self)
            if ~ isempty(self.Trials)
                value = max(arrayfun(@(t)t.MovementTime, self.ValidTrials));
            elseif ~ isempty(self.AvgTrialsAbs)
                value = max(arrayfun(@(t)t.MovementTime, ExperimentData.getValidTrials(self.AvgTrialsAbs)));
            else
                error('Error: ExperimentData is empty, MaxMovementTime cannot be calculated');
            end
        end
        
        function value = get.MeanMovementTime(self)
            if ~ isempty(self.Trials)
                value = mean(arrayfun(@(t)t.MovementTime, self.Trials));
            elseif ~ isempty(self.AvgTrialsAbs)
                value = mean(arrayfun(@(t)t.MovementTime, self.AvgTrialsAbs));
            else
                error('Error: ExperimentData is empty, MeanMovementTime cannot be calculated');
            end
        end
        
        function value = get.MeanSpeed(self)
            if ~ isempty(self.Trials)
                value = mean(arrayfun(@(t)1/t.MovementTime, self.Trials));
            elseif ~ isempty(self.AvgTrialsAbs)
                value = mean(arrayfun(@(t)1/t.MovementTime, self.AvgTrialsAbs));
            else
                error('Error: ExperimentData is empty, MeanSpeed cannot be calculated');
            end
        end
        
        function value = get.MaxTrajectoryLength(self)
            value = max(arrayfun(@(t)size(t.Trajectory,1), self.Trials));
        end
        
        function value = get.LongestTrajectoryNSamples(self)
            value = max(arrayfun(@(t)size(t.Trajectory,1), self.Trials));
        end
        
        function trial = get.LongestTrial(self)
            [~,longestTrialInd] = max(arrayfun(@(t)t.MovementTime, self.Trials));
            trial = self.Trials(longestTrialInd);
        end
        
        function trial = get.ShortestTrial(self)
            [~,shortestTrialInd] = min(arrayfun(@(t)t.MovementTime, self.OKTrials));
            trial = self.Trials(shortestTrialInd);
        end
        
        function trials = get.OKTrials(self)
            trials = self.Trials(logical(arrayfun(@(t)t.ErrCode == TrialErrCodes.OK, self.Trials)));
        end
        
        function clone = get.ExpDataWithOKTrials(self)
            clone = self.filterTrialsWithErrCode(TrialErrCodes.OK);
            clone.AvgTrialsAbs = self.AvgTrialsAbs;
            clone.AvgTrialsNorm = self.AvgTrialsNorm;
            clone.SoftwareVersion = self.SoftwareVersion;
            clone.BuildNumber = self.BuildNumber;
            clone.SubjectInitials = self.SubjectInitials;
            clone.Group = self.Group;
            clone.TotalDuration = self.TotalDuration;
            clone.RunDate = self.RunDate;
            clone.SubjBirthday = self.SubjBirthday;
            clone.Custom = self.Custom;
        end
        
        function v = get.ExcludeFromAverage(self)
            v = strcmp(self.SubjectInitials, 'all') || strcmp(self.SubjectInitials, 'avg');
        end
        
        function age = get.SubjAgeDays(self)
            age = daysact(self.SubjBirthday, self.RunDate);
        end
        
        function targets = getAllTargets(self) %#ok<MANU,STOUT>
            throw MException('Method createEmptyClone() should be overriden in the derived class!');
        end
        
        function v = get.FailedTrialRate(self)
            if (isempty(self.Trials))
                v = 0;
            else
                nFailed = sum(arrayfun(@(t)t.ErrCode ~= TrialErrCodes.OK && t.ErrCode ~= TrialErrCodes.Outlier, self.Trials));
                v = nFailed / length(self.Trials);
            end
        end
        
        
        %==============================================================
        % Return a clone of self, with only some of the trials
        %==============================================================
        
        function clone = filterTrialsWithErrCode(self, errCodes)
            clone = self.filterTrials(@(t)ismember(t.ErrCode, errCodes));
        end
        
        
        function clone = filterTrials(self, filterFunction)
            
            clone = self.clone(0);
            
            for trial = self.Trials
                if (filterFunction(trial))
                    clone.addTrialData(trial);
                end
            end
            
        end
        
        function result = clone(self, cloneTrials)
            
            if ~exist('cloneTrials','var') || isempty(cloneTrials)
                cloneTrials = 1;
            end
            
            result = self.createEmptyClone();
            
            result.SoftwareVersion = self.SoftwareVersion;
            result.BuildNumber = self.BuildNumber;
            result.SubjectInitials = self.SubjectInitials;
            result.Group = self.Group;
            result.TotalDuration = self.TotalDuration;
            result.Custom = self.Custom;
            
            if (cloneTrials)
                result.Trials = self.Trials;
                result.AvgTrialsNorm = self.AvgTrialsNorm;
                result.AvgTrialsAbs = self.AvgTrialsAbs;
            else
                result.Trials = [];
            end
            
        end
        
        %==============================================================
        function addTrialData(self, td)
            self.Trials = [self.Trials td];
        end
        
        %==============================================================
        function addAllTrialsOf(self, otherExpData)
            self.Trials = [self.Trials otherExpData.Trials];
        end
        
        %==============================================================
        function td = getTrialByNum(self, trialNum)
            inds = logical(arrayfun(@(t) ismember(t.TrialNum, trialNum), self.Trials));
            if (isempty(inds))
                error('Trial %d was not found', trialNum);
            end
            td = self.Trials(inds);
        end
        
        %==============================================================
        function trials = getTrialsByTarget(self, targets, excludeOutlierTrajectories)
            if (exist('excludeOutlierTrajectories', 'var') && excludeOutlierTrajectories)
                relevantTrials = self.Trials(logical(arrayfun(@(t)~t.IsOutlierTrajectory, self.Trials)));
            else
                relevantTrials = self.Trials;
            end
            inds = arrayfun(@(td)ismember(td.Target, targets), relevantTrials);
            trials = relevantTrials(inds);
        end
        
        %==============================================================
        % Organize the trials by target.
        % Return a cell array, of the same size as the 'targets' array.
        % Each entry in the cell array is an array of OneTrialData objects.
        function trialGroups = splitTrialsByTarget(self, targets)
            if ~exist('targets', 'var')
                targets = 0:self.MaxTarget;
            end
            trialGroups = common.splitTrialsByTarget(self.Trials, targets);
        end
        
        %==============================================================
        % apply the given function to each target, calculate average over
        % all trials, and return an array of averages
        %==============================================================
        function averages = applyAndGetAveragePerTarget(self, func)
            allTargets = self.getAllTargets();
            averages = NaN(length(allTargets),1);
            for i = 1:length(allTargets)
                funcOutputs = arrayfun(func, self.getTrialsByTarget(allTargets(i)));
                averages(i) = mean(funcOutputs);
            end
        end
        
        %==============================================================
        % apply the given function to each target, calculate stdev over
        % all trials, and return an array of stdevs
        %==============================================================
        function result = applyAndGetStDevPerTarget(self, func)
            allTargets = self.getAllTargets();
            result = NaN(length(allTargets),1);
            for i = 1:length(allTargets)
                funcOutputs = arrayfun(func, self.getTrialsByTarget(allTargets(i)));
                result(i) = std(funcOutputs);
            end
        end
        
        %==============================================================
        % apply the given function to each target, calculate average over
        % all trials, and return an array of averages
        %==============================================================
        function [averages, stdevs] = applyAndGetAverageAndStDevPerTarget(self, func)
            allTargets = self.getAllTargets();
            averages = NaN(length(allTargets),1);
            stdevs = NaN(length(allTargets),1);
            for i = 1:length(allTargets)
                funcOutputs = arrayfun(func, self.getTrialsByTarget(allTargets(i)));
                averages(i) = mean(funcOutputs);
                stdevs(i) = std(funcOutputs);
            end
        end
        
        %==============================================================
        function printOutliers(self)
            nonOutlierTrials = self.filterTrialsWithErrCode(TrialErrCodes.OK).Trials;
            nonOutlierTargets = arrayfun(@(x)x.Target, nonOutlierTrials);
            nonOutlierEP = arrayfun(@(x)x.EndPoint, nonOutlierTrials);
            
            outlierTrials = self.filterTrialsWithErrCode(TrialErrCodes.Outlier).Trials;
            for t = outlierTrials
                validEndpoints = sort(nonOutlierEP(logical(nonOutlierTargets==t.Target)));
                fprintf('Target=%d outlier=%f  (min=%f max=%f)\n', t.Target, ...
                    t.EndPoint, validEndpoints(1), validEndpoints(length(validEndpoints)));
            end
        end
    end

    
    methods(Access=protected)
        
        function copyOfSelf = createEmptyClone(self) %#ok<STOUT>
            error('Method createEmptyClone() should be overriden in the derived class (class=%s)!', class(self));
        end
        
    end
    
    methods(Static)
        
        function filteredTrials = filterTrialList(srcTrials, filterFunction)
            doInclude = arrayfun(@(t)filterFunction(t), srcTrials);
            filteredTrials = srcTrials(logical(doInclude));
        end
        
        function v = getValidTrials(trials)
            v = trials(arrayfun(@(t)t.TrialNum >= 0, trials));
        end
        
    end
    
end
