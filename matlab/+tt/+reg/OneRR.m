classdef OneRR < handle
    %ONERR - results of one regression, potentially in several time points
    
    properties(SetAccess=private)
        SubjectInitials   % Subject on which the regression was run
        dependentVar      % Dependent variable - string descriptor
        predictorNames    % Cell array of predictors as string descriptor
        regressionType    % As passed to tt.reg.regress()
    end
    
    properties(Access=private)
        PredResults       % Struct with tt.reg.OnePredRR object per predictor
    end
    
    properties
        PredictorDesc     % Text description of the predictor
        DependentVarDesc  % Text description of the dependent variable
        
        RegressionParams  % The parameters used to run the regression
        
        MSE
        
        %-- Stats about data executed
        times             % Column vector of times. Matches entries in "PredResults".
        MaxMovementTime
        df                % The regression-level df
        sd_x              % StDev of predictors (#timepoints x #predictors matrix)
        sd_y              % StDev of dependent var (per timepoint)
        NSubjects         % Relevant when this object is the average of several subjs
        
        RSquare           % Regression-level R2
        sd_RSquare        % When self.RSquare is average, this is SD
        p                 % Regression-level p value
        stat              % Detailed statistics of the raw regression function
        
        Custom
    end
    
    methods
        
        %---------------------------------------------------------------------
        function self = OneRR(subjInitials, regType, predNames, depVar, times)
            
            self.SubjectInitials = subjInitials;
            self.PredResults = struct;
            self.stat = {};
            self.times = times;
            
            self.regressionType = regType;
            self.predictorNames = predNames;
            self.dependentVar = depVar;
            
            self.RSquare = NaN(length(self.times), 1);
            self.p = NaN(length(self.times), 1);
            self.NSubjects = 1;
            
            self.Custom = struct;
        end
        
        %---------------------------------------------------------------------
        function predRes = addPredResults(self, predRes)
            self.PredResults.(lower(predRes.PredName)) = predRes;
        end
        
        %---------------------------------------------------------------------
        function onePredResults = getPredResult(self, predName)
            predName = lower(predName);
            if isfield(self.PredResults, predName)
                onePredResults = self.PredResults.(predName);
            else
                onePredResults = [];
            end
        end
        
        %---------------------------------------------------------------------
        function desc = getPredDesc(self, predName)
            predName = lower(predName);
            [ok, loc] = ismember(lower(predName), lower(self.predictorNames));
            if ok
                desc = self.PredictorDesc{loc};
            else
                desc = '';
            end
        end
        
        %---------------------------------------------------------------------
        %-- Get results (e.g., the b or beta values) of one predictor results
        %-- attrName: e.g., 'b', 'beta', 'p', etc. You can omit attrName 
        %--           and provide a single argument "pred.attr" 
        function value = getParamValue(self, predName, attrName)
            if ~exist('attrName', 'var')
                % "predName" is actually "pred.attr"
                ind = find(predName == '.', 1);
                if isempty(ind)
                    error('Invalid parameter name (%s): expecting "pred_name.attribute"', predName);
                end
                attrName = predName(ind+1:end);
                predName = predName(1:ind-1);
            end
            
            pr = self.getPredResult(predName);
            if isempty(pr)
                error('There are no results for predictor "%s"', predName);
            end
            value = pr.(attrName);
            
        end
        
        
        
    end
    
end

