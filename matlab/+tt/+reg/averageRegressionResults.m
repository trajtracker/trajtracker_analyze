function avgSubjectData = averageRegressionResults(allRegressions, varargin)
%avgSubjectData = averageRegressionResults(allRegressions) -
%Average b/beta/R values over a set of regressions
%
% allRegressions: either a cell array with all regressions; or a struct
% with one regression results per key.
%
% Optional arguments:
% KeyFilter @(rrKey)->BOOL: this function gets a potential regression key and 
%                        returns true/false to include/exclude it in
%                        averaging.
% RRFilter @(rr,rrKey)->BOOL: this function gets a subject's regression-results
%                       object (of one regression) and indicates whether to
%                       include it or not in the averaging.

    [meanFunc, includeRRKeyFunc, includeRRFunc] = parseArgs(varargin);

    switch(class(allRegressions)) 
        case 'cell'
            % ok, nothing to do 
            
        case 'struct'
            % Convert the struct to a cell array
            subjectNames = fieldnames(allRegressions);
            subjArray = {};
            for iSubj = 1:size(subjectNames,1)
                subj = char(subjectNames(iSubj,:));
                subjExpData = allRegressions.(subj);
                if (~ isstruct(subjExpData) || strcmp(subj, 'general') || strcmp(subj, 'avg') || strcmp(subj, 'all'))
                    continue;
                end
                subjArray = [subjArray subjExpData]; %#ok<AGROW>
            end
            allRegressions = subjArray;
            
        otherwise
            error('Unsupported input class: %s', class(allRegressions));
    end
    
    avgSubjectData = struct('SubjectName', 'Average', 'SubjectInitials', 'avg', ...
                            'NSubjects', length(allRegressions));
    if isfield(allRegressions{1}, 'MaxTarget')
        avgSubjectData.MaxTarget = allRegressions{1}.MaxTarget;
    end
    
    regressionTypes = fieldnames(allRegressions{1});
    
    for iFld = 1:size(regressionTypes,1)
        key = char(regressionTypes(iFld,:));
        if ~isa(allRegressions{1}.(key), 'tt.reg.OneRR')
            % Consider only real reg results
            continue;
        end
        
        if ~includeRRKeyFunc(key)
            continue;
        end
        
        regressionsPerSubject = arrayfun(@(r){r{1}.(key)}, allRegressions);
        regressionsPerSubject = regressionsPerSubject(arrayfun(@(rr)includeRRFunc(rr, key), regressionsPerSubject));

        avgSubjectData.(key) = averageOneRegressionResults(regressionsPerSubject);
        avgSubjectData.(key).MaxMovementTime = max(arrayfun(@(r)r{1}.(key).MaxMovementTime, allRegressions));

    end
    
    
    %---------------------------------------------------------------------
    function avgResults = averageOneRegressionResults(allRR)

        nSubjects = length(allRR);
        nSamplesPerRegression = arrayfun(@(r)length(r{1}.times), allRR);
        [maxNSamples, maxInd] = max(nSamplesPerRegression);

        avgResults = tt.reg.OneRR('average', allRR{1}.regressionType, allRR{1}.predictorNames, allRR{1}.dependentVar, allRR{maxInd}.times);
        avgResults.sd_RSquare = nan(maxNSamples,1);
        avgResults.NSubjects = nSubjects;
        df = allRR{1}.df;
        avgResults.df = df;
        avgResults.PredictorDesc = allRR{1}.PredictorDesc;
        avgResults.DependentVarDesc = allRR{1}.DependentVarDesc;
        avgResults.MaxMovementTime = max(arrayfun(@(r)length(r{1}.MaxMovementTime), allRR));
        
        for pred = allRR{1}.predictorNames
            avgPred = avgResults.addPredResults(tt.reg.OnePredRR(pred{1}, maxNSamples));
            avgPred.sd_b = NaN(maxNSamples, 1);
            avgPred.se_b = NaN(maxNSamples, 1);
            avgPred.sd_beta = NaN(maxNSamples, 1);
            avgPred.se_beta = NaN(maxNSamples, 1);
        end

        for i = 1:maxNSamples

            if ~isempty(allRR{1}.RSquare)
                RSquare = arrayfun(@(r)getValueSafe(r{1}.RSquare, i), allRR);
                avgResults.RSquare(i) = meanFunc(RSquare);
                avgResults.sd_RSquare(i) = std(RSquare);
            end
            
            for pred = allRR{1}.predictorNames
                avgPred = avgResults.getPredResult(pred{1});
                srcPreds = myarrayfun(@(r)r{1}.getPredResult(pred{1}), allRR);
                
                bVals = arrayfun(@(p)getValueSafe(p.b, i), srcPreds);
                avgPred.b(i) = meanFunc(bVals);
                avgPred.sd_b(i) = std(bVals);
                avgPred.se_b(i) = std(bVals) / sqrt(nSubjects);
                
                betaVals = arrayfun(@(p)getValueSafe(p.beta, i), srcPreds);
                avgPred.beta(i) = meanFunc(betaVals);
                avgPred.sd_beta(i) = std(betaVals);
                avgPred.se_beta(i) = std(betaVals) / sqrt(nSubjects);
                
                r2Vals = arrayfun(@(p)getValueSafe(p.r2, i), srcPreds);
                avgPred.r2(i) = meanFunc(r2Vals);
%                     adjR2 = calcAdjRSquare(avg_r2, 41, length(predictorNames));
%                     avgResults.(adjr2Var)(i) = adjR2;
%                     % I am really not sure about the following calculation.
%                     % It's certainly not exact, but it may be close enough (just a bit stricter than the correct result).
%                     tval = sqrt((avg_r2 .* df) ./ (1-avg_r2));
%                     avg_pval = 2*tcdf(-tval, df);
%                     avgResults.(sprintf('p_%s', pred{1}))(i) = avg_pval;
            end
            
        end
        
    end

    %---------------------------------------------------------------------
    function value = getValueSafe(array, index)
        value = array(min(index, length(array)));
    end

    %--------------------------------------------------------------
    function [meanFunc, includeRRKeyFunc, includeRRFunc, filterSubjFunc] = parseArgs(args)
        
        meanFunc = @nanmean;
        includeRRKeyFunc = @(~)true;
        includeRRFunc = @(~,~)true;
        filterSubjFunc = [];
        
        args = stripArgs(args);
        
        while ~isempty(args)
            
            switch(lower(args{1}))
                case 'median'
                    meanFunc = @median;
                    
                case 'keyfilter'
                    includeRRKeyFunc = args{2};
                    args = args(2:end);
                    
                case 'rrfilter'
                    includeRRFunc = args{2};
                    args = args(2:end);
                    
                otherwise
                    error('Unknown argument: %s', args{1});
            end
            
            args = stripArgs(args(2:end));
        
        end
    end

end
