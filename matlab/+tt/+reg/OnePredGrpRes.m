classdef OnePredGrpRes < handle
    %OnePredCmpRes - results of group-level analysis of one predictor
    
    properties
        TestType
        
        ParamName
        ParamDesc
        
        values    % Column vector (value per time point)
        sd_values % Column vector (value per time point)
        nSubjValues % Column vector (# of subject with available value, per time point)
        valuesPerGroup    % timepoints x ngroups matrix (only when grouping is used)
        
        % Effect of the predictor
        pPred
        fPred
        dfPred
        esPred % effect size
        
        % Effect of a between-subject grouping factor
        pGroup
        fGroup
        dfGroup
        esGroup
        
        % Interaction between "param" and "factor2"
        pInteraction
        fInteraction
        dfInteraction
        esInteraction
        
        stats
    end
    
    methods
        
        function self = OnePredGrpRes(testType, nTimes)
            self.TestType = testType;
            self.values = NaN(nTimes, 1);
            self.sd_values = NaN(nTimes, 1);
            self.pPred = NaN(nTimes, 1);
            self.fPred = NaN(nTimes, 1);
            self.dfPred = NaN(nTimes, 1);
            self.esPred = NaN(nTimes, 1);
        end
        
    end
    
end

