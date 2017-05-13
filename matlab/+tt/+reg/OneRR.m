classdef OneRR < handle
% OneRR - results of one regression (one call to <a href="matlab:help tt.reg.regress">tt.reg.regress</a>
% This includes regression results from one regression model,
% potentially in several time points.
% 
% Properties:
% ===========
% 
%   SubjectInitials:  Subject on which the regression was run
%   Custom:           struct for custom data
% 
% Regression parameters -
% 
%   dependentVar:     The dependent variable definition, as provided to tt.reg.regress()
%   DependentVarDesc: Text description of the dependent variable
%   predictorNames:   The predictor names, as provided to tt.reg.regress()
%                   (cell array)
%   regressionType:   As passed to tt.reg.regress()
%   PredictorDesc:    Cell array with text description per predictor
%   RegressionParams: Struct with parameters used to run the regression
% 
% Info about the regressed trials -
% 
%   times:            The time points on which regression was run
%   MaxMovementTime:  Movement time of the longest trial regressed
%   NSubjects:        Number of subjects regressed (typically 1, but can be
%                     more in case the object represents average of several
%                     results)
%   df:               The regression's degrees of freedom
%   sd_x:             Standard deviation of each predictor across trials
%                     (#timepoints x #predictors matrix)
%   sd_y:             Standard deviation of the dependent variable across trials
%                     (per time-point)
% 
% Regression results -
% 
%   MSE:              MSE of the regression model
%   RSquare:          regression-level r^2
%   p:                regression-level p-value
%   sd_RSquare:       Standard deviation (across subjects) of r^2 (in case
%                     this object is the average across several subjects)
%   stat:             Detailed statistics - results of Matlab's regression
%                     function (cell array, one value per time point;
%                     updated only if explicitly required).
% 
% Methods:
% ========
% getPredResult(pred_name): Get the results of one predictor (<a href="matlab:help tt.reg.OnePredRR">OnePredRR</a>)
% getPredDesc(pred_name): Get the string description of one predictor
% getParamValue(pred_name, param_name): Get a parameter from one predictor
%               results (e.g., getParamValue('const', 'b') to get the
%               regression constant intercept).

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

