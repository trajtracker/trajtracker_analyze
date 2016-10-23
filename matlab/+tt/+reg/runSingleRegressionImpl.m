function oneRegResults = runSingleRegressionImpl(regressionType, predictors, dependentVar, varargin)
%result = runSingleRegressionImpl(regressionType, predictors, dependentVar) - 
% used by regression functions

    [printWarnings] = parseArgs(varargin);
    
    oneRegResults = struct;
    
    %-- For binary regressions: make sure the dependent variable is binary
    BINARY_REGS = {'pointbiserial', 'logglm'};
    BINARY_REGS_DESC = join(',', BINARY_REGS);
    if ismember(regressionType, BINARY_REGS)
        if sum(~ismember(dependentVar, [0 1])) > 0
            error('In %s regressions, the dependent variable must be binary (0,1)!', BINARY_REGS_DESC);
        end

        if length(unique(dependentVar)) <= 1
            oneRegResults = tt.reg.invalidRegResultsImpl(length(predictors)+1);
            if printWarnings
                fprintf('No variance, can''t calculate point biserial\n');
            end
            return;
        end
        
    end

    switch(regressionType)
        case 'step'
            [b,~,pval,inmodel,stats,~,~] = stepwisefit(predictors, dependentVar, 'display', 'off');
            oneRegResults.beta = [stats.intercept; b];
            pval(logical(~inmodel)) = 1;
            oneRegResults.p = [1; pval];   % todo: what is the p-value of the intercept? And where do we put "stats.pval"?

            varDependent = var(dependentVar(logical(~ isnan(dependentVar))));
            oneRegResults.rSquare = 1 - (stats.rmse^2/varDependent) * ((length(dependentVar)-1-stats.df0)/(length(dependentVar)-1));

            oneRegResults.df = stats.dfe;
            oneRegResults.r2_per_predictor = [NaN; stats.TSTAT .^ 2 ./ (stats.TSTAT .^ 2 + oneRegResults.df)];

            oneRegResults.regressionPVal = stats.pval;

        case 'reg'
            %-- Switch off dwtest() warning - this is about calculating the
            %-- Durbin?Watson statistic, and we don't use it
            warning('off', 'stats:pvaluedw:ExactUnavailable');

            stats = regstats(dependentVar, predictors, 'linear');

            oneRegResults.beta = stats.beta;
            oneRegResults.p = stats.tstat.pval;
            oneRegResults.stderr = stats.tstat.se;
            oneRegResults.rSquare = stats.rsquare;
            oneRegResults.regressionPVal = stats.fstat.pval;
            oneRegResults.df = stats.tstat.dfe;
            oneRegResults.r2_per_predictor = stats.tstat.t .^ 2 ./ (stats.tstat.t .^ 2 + oneRegResults.df);
            oneRegResults.stat = stats;

        case 'corr'
            if (size(predictors,2) ~= 1)
                error('Correlation works only with a single predictor!');
            end
            [r,oneRegResults.p] = corrcoef(predictors, dependentVar);
            r = r(1,2);
            oneRegResults.beta = [NaN, r];
            oneRegResults.rSquare = r^2;
            oneRegResults.df = NaN;
            oneRegResults.r2_per_predictor = [NaN r^2];
            oneRegResults.regressionPVal = NaN;
            
        case 'pointbiserial'
            if (size(predictors,2) ~= 1)
                error('Correlation works only with a single predictor!');
            end

            [r,~,p] = pointbiserial(dependentVar, predictors);
            
            b = mean(predictors(dependentVar==1)) - mean(predictors(dependentVar==0));
            oneRegResults.beta = [NaN b];
            
            oneRegResults.p = [NaN p];
            oneRegResults.rSquare = r^2;
            oneRegResults.df = NaN;
            oneRegResults.r2_per_predictor = [NaN r^2];
            oneRegResults.regressionPVal = NaN;
            
        case {'logistic', 'logglm'}

            [b, ~, stats] = glmfit(predictors, dependentVar, 'binomial');
            
            oneRegResults.stat = stats;
            
            oneRegResults.beta = b';
            t = stats.t;
            oneRegResults.rSquare = NaN;
            oneRegResults.p = stats.p';
            oneRegResults.regressionPVal = NaN;
            oneRegResults.df = stats.dfe;
            oneRegResults.stderr = stats.se';
            oneRegResults.r2_per_predictor = t .^ 2 ./ (t .^ 2 + stats.dfe);
            
        otherwise
            error('Unknown regression type (%s). Supported types: step, reg, corr, pointbiserial, logglm.', regressionType);
    end

    oneRegResults.adj_r2_per_predictor = tt.reg.calcAdjRSquare(oneRegResults.r2_per_predictor, length(dependentVar), size(predictors,2));

    %-------------------------------------------
    function [printWarnings] = parseArgs(args)

        printWarnings = true;
        
        args = stripArgs(args);
        while ~isempty(args)
            switch(lower(args{1}))
                case 'silent'
                    printWarnings = false;

                otherwise
                    error('Unsupported argument "%s"!', args{1});
            end
            args = stripArgs(args(2:end));
        end

    end

end

