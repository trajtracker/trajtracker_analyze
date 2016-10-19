classdef GDOneTrialData < OneTrialData
% The data of a single trial in the decision experiment
    
    properties
        UserResponse        % The response button selected by user
        PrevResponse        % The response button selected in the previous trial
        
        RequiredResponse     % The response button the user should have selected
        PrevRequiredResponse % The previous trial's expected response
        
        DeviationDistance   % maximal distance from the straight line that leads to the actual response made
        DeviationArea % area between trajectory and the straight line that leads to the actual response made
        
        MaxTransientErrorTheta
        MaxTransientErrorThetaRow
    end
    
    properties(Dependent=true)
        IsCorrectResponse      % Whether the user responded as expected
        RequiredResponseLikePrev
    end
    
    methods
        
        function self = GDOneTrialData(trialNum, target)
            self = self@OneTrialData(trialNum, target);
        end
        
        function v = get.IsCorrectResponse(self)
            v = (self.UserResponse == self.RequiredResponse);
        end
        
        function v = get.RequiredResponseLikePrev(self)
            v = (self.PrevRequiredResponse == self.RequiredResponse);
        end
        
        
        function c = clone(self)
            c = GDOneTrialData(self.TrialNum, self.Target);
            c.initFrom(self);
        end
        
    end
    
    methods(Access=protected)
        
        function initFrom(self, c)
            self.initFrom@OneTrialData(c);
            self.UserResponse = c.UserResponse;
            self.RequiredResponse = c.RequiredResponse;
            self.PrevRequiredResponse = c.PrevRequiredResponse;

            self.DeviationDistance = c.DeviationDistance;
            self.DeviationArea = c.DeviationArea;

            self.MaxTransientErrorTheta = c.MaxTransientErrorTheta;
            self.MaxTransientErrorThetaRow = c.MaxTransientErrorThetaRow;
        end
    end
    
end
