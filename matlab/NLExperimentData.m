classdef NLExperimentData < ExperimentData
% Data of a number-line experiment

    properties
        MaxTarget % Maximal number on the number line
    end
    
    properties(Dependent=true)
        MeanEndpointError
        MeanEndpointBias
    end    
    
    methods
        
        function self = NLExperimentData(maxTarget, initials, subjName)
            self = self@ExperimentData(initials, subjName);
            self.MaxTarget = maxTarget;
        end
        
        function targets = getAllTargets(self)
            maxTarget = max([self.MaxTarget arrayfun(@(t)t.Target, self.Trials)]);
            targets = 0:maxTarget;
        end
        
        function value = get.MeanEndpointError(self)
            if ~ isempty(self.Trials)
                value = mean(arrayfun(@(t)t.EndPointAbsError, self.Trials));
            elseif ~ isempty(self.AvgTrialsAbs)
                value = mean(arrayfun(@(t)t.EndPointAbsError, self.AvgTrialsAbs));
            else
                error('Error: ExperimentData is empty, MeanEndpointError cannot be calculated');
            end
        end
        
        function value = get.MeanEndpointBias(self)
            if ~ isempty(self.Trials)
                value = mean(arrayfun(@(t)t.EndPointBias, self.Trials));
            elseif ~ isempty(self.AvgTrialsAbs)
                value = mean(arrayfun(@(t)t.EndPointBias, self.AvgTrialsAbs));
            else
                error('Error: ExperimentData is empty, MeanEndpointBias cannot be calculated');
            end
        end
        
        function result = clone(self, cloneTrials)
            if ~exist('cloneTrials','var')
                cloneTrials = [];
            end
            result = self.clone@ExperimentData(cloneTrials);
            result.MaxTarget = self.MaxTarget;
        end
        
    end
    
    
    methods(Access=protected)
        
        function copyOfSelf = createEmptyClone(self)
            copyOfSelf = NLExperimentData(self.MaxTarget, self.SubjectInitials, self.SubjectName);
        end
        
        function p = getPlatform(~)
            p = 'NL';
        end
        
    end
    
end
