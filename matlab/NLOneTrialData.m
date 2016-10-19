classdef NLOneTrialData < OneTrialData
% The data of a single trial in the number-to-line experiment
    
    properties
        EndPoint
        PrevEndPoint
    end
    
    
    properties(Dependent=true)
        EndPointBias
        EndPointAbsError
        PrevEndPointBias
    end

    
    methods
        
        function self = NLOneTrialData(trialNum, target)
            self = self@OneTrialData(trialNum, target);
        end
        
        function value = get.EndPointBias(self)
            value = self.EndPoint - self.Target;
        end
        
        function value = get.EndPointAbsError(self)
            value = abs(self.EndPointBias);
        end
        
        function value = get.PrevEndPointBias(self)
            value = self.PrevEndPoint - self.PrevTarget;
        end
        
    end
    
end
