classdef OnePredRR < handle
    %OnePredRR - regression results of one predictor
    
    properties(SetAccess=private)
        PredName
    end
    
    properties
        b
        beta
        p
        r2
        adj_r2
        
        sd_b
        se_b
        sd_beta
        se_beta
    end
    
    methods
        
        function self = OnePredRR(predName, nTimes)
            self.PredName = predName;
            self.b = NaN(nTimes, 1);
            self.beta = NaN(nTimes, 1);
            self.p = NaN(nTimes, 1);
            self.r2 = NaN(nTimes, 1);
            self.adj_r2 = NaN(nTimes, 1);
        end
        
    end
    
end

