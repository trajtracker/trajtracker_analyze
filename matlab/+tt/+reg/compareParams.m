function [result,params] = compareParams(allRR, regressionKeys, paramNames, varargin)
%[result,params] = compareParams(allRR, regressionKeys, paramNames, ...)
%
%   Extract values of one or more parameters of a regression, across subjects, 
%   and compare these values vs. zero and/or one vs. another:
%   Each parameter is compared vs. 0; optionally, two parameters could be
%   compared with each other.
%   The comparison includes the language group as a factor.
%
% allRR - struct with regression results of all subjects (output of
%              tt.reg.customize.runRegressions or a similar function).
% regressionKeys: regression key (fieldname in the per-subject regression results).
%              This can be either a cell array or a single regression.
% paramNames:  Regression predictors to analyze. Each predictor here is of
%              the format "x.y", where "x" is the predictor name and "y" is
%              a field in the OnePredRR object - e.g., "const.b", "target.beta",
%              etc.
%              To multiply a parameter value by a constant, use x.y*value
%              or x.y/value - e.g., "const.b*20". This has no effect on the
%              statistical comparison, but will change the value when
%              plotting it.
%              If you provided a single regression key in "regressionKeys",
%              you can set "paramNames" to be 'allb' or 'allbeta', meaning
%              that all b/beta values will be compared. beta[const] is 0
%              and b[const] is not analyzed in this mode, unless you use the
%              'const' flag.
% If both regressionKeys and paramNames are cell arrays, they must be of
% equal size.
%
% Optional arguments:
% -------------------
% GroupSubjects <subj> - consider the subjects' grouping in the
%              statistical comparisons (t/ANOVA). The argument <subj> is a
%              struct with one ExperimentData per subject. They will be
%              grouped by each subject's "Group" attribute.
% Compare <array> - indices of two parameters to compare
% CompareTOffset <t1 t2> - time offsets of the two parameters to compare
%             (relevant only when the "Compare" flag is used)
% Cmp1Larger - when using "Compare [a b]", this flag indicates that the
%              comparison results should use one tailed p-values, under the
%              assumption that a>b
% paramsMethod <method> - How to check the significance of each parameter 
%               in each time point. Available methods:
%       TZero (default): compare the parameter value to zero using t-test (no language factor)
%       Zero: compare the parameter value to zero using ANOVA
%       Delay: compare the parameter value to its own value x millisec ago
% paramsDelay <dt> - The delay for paramsMethod="delay" (default=0.2)
%               The difference beteen time point t and t+paramsDelay will
%               be marked in the output on time point t.
% PositiveB <array of boolean flags> - per predictor, indicate whether we
%               expect a positive value.
% Const - if "paramNames" is defined as "all", this flag means that the
%               regression intercept should be analyzed too.
% SubjIDs <cell-array>: process these subjects
% OnlySignificant: exclude non-significant b values from the comparison

    % Comparison methods for a single parameter
    COMPARE_TO_ZERO_ANOVA = 1;
    COMPARE_TO_ZERO_WITH_T = 2;
    COMPARE_TO_ITSELF = 3;
    
    [expDataForGrouping, comparedIndices, compare2TOffset, singleParamComparisonMode, singleParamComparisonDelay, ...
        analyzeConstByDefault, subjIDs, comparePair1Larger, ...
        expectPositiveBValue, excludeNonsignificantValues] = parseArgs(varargin);
    
    [regressionKeys, paramNames, pValNames, allRR, paramMultiplyFactors] = validateAndFixArgs(regressionKeys, paramNames, allRR, analyzeConstByDefault);
    
    if isempty(expectPositiveBValue)
        expectPositiveBValue = true(1, length(paramNames));
    end
    
    [params, times, subjIDs] = getAllParamValues(allRR, regressionKeys, paramNames, pValNames, subjIDs);
    for ip = 1:length(params)
        params{ip} = params{ip} * paramMultiplyFactors(ip);
    end
    groupSubjectsArg = getGroupingArg(expDataForGrouping, subjIDs);
    
    result = createResultObj(allRR, regressionKeys, paramNames, subjIDs, times);
    
    result.cmpParam = [];
    
    %-- Compare each parameter to 0
    for iParam = 1:length(params)
        
        arg1Larger = iif(expectPositiveBValue(iParam), '1Larger', {});
        currParam = params{iParam};
        zeroValues = zeros(size(currParam));
        
        switch(singleParamComparisonMode)
            case COMPARE_TO_ZERO_ANOVA
                if isempty(groupSubjectsArg)
                    disp('WARNING: without grouping subjects, why use ANOVA? Consider setting paramsMethod=TZero');
                end
                cmp = tt.reg.internal.compareParamValues({currParam, zeroValues}, 'RMAnova', groupSubjectsArg, arg1Larger);
                
            case COMPARE_TO_ZERO_WITH_T
                cmp = tt.reg.internal.compareParamValues({currParam, zeroValues}, 'PT', groupSubjectsArg, arg1Larger);
                
            case COMPARE_TO_ITSELF
                singleParamComparisonDeltaInds = ceil(singleParamComparisonDelay / (times(2)-times(1)));
                cmp = tt.reg.internal.compareParamValues({currParam, currParam}, 'RMAnova', groupSubjectsArg, 'ValOffset', [0 singleParamComparisonDeltaInds]);
                
            otherwise
                error('Unsupported single-param comparison mode');
        end
        
        if (sum(cmp.pGroup <= 0.1) > 0)
            fprintf('Possible group effect for %s\n', paramNames{iParam});
        end
        
        result.cmpParam = [result.cmpParam cmp];
        
    end
    
    updateParamName(result, paramNames, allRR);
    updateMeanValues(result, paramNames, params);
    
    %-- Compare two parameters vs. one another
    if ~isempty(comparedIndices)
        
        cmpArgs = {'MaxTimeInd', length(times)};
        if (comparePair1Larger) 
            cmpArgs = [cmpArgs {'1Larger'}];
        end
        if ~isempty(compare2TOffset)
            compare2TOffsetInds = ceil(compare2TOffset / (times(2)-times(1)));
            cmpArgs = [cmpArgs {'ValOffset', compare2TOffsetInds}];
        end
        
        if isempty(groupSubjectsArg)
            result.comparePair = tt.reg.internal.compareParamValues(params(comparedIndices), 'PT', cmpArgs);
        else
            result.comparePair = tt.reg.internal.compareParamValues(params(comparedIndices), 'RMAnova', groupSubjectsArg, cmpArgs);
        end
        
        result.comparePair.values = params{comparedIndices(2)} - params{comparedIndices(1)};
        result.comparedIndices = comparedIndices;
    end
    
    %=======================================================================

    %--------------------------------------------------------------------
    % Get the values to compare.
    %
    % Returns:
    % times - column array of regression times
    % params - cell array. Each entry is an array of values, in all time slots
    %
    function [params, times, subjIDs] = getAllParamValues(allRR, regressionKeys, paramNames, pValNames, subjIDs)
        
        params = cell(1, length(regressionKeys));
        
        times = [];
        filterSubjIDArg = iif(isempty(subjIDs), {}, {'SubjIDs' , subjIDs});
        
        for i = 1:length(regressionKeys)
            [params{i}, tmp_times, subjIDs] = tt.reg.getRRCoeffs(allRR{i}, regressionKeys{i}, paramNames{i}, filterSubjIDArg);
            if excludeNonsignificantValues
                pValues = tt.reg.getRRCoeffs(allRR{i}, regressionKeys{i}, pValNames{i}, filterSubjIDArg);
                if expectPositiveBValue(i)
                    params{i}(pValues>0.1 | params{i}<=0) = NaN;
                else
                    params{i}(pValues>0.05) = NaN;
                end
            end
            if (isempty(times) || length(tmp_times) < length(times))
                % Use the shortest "times" vector available (to make comparison possible)
                times = tmp_times;
            end
        end
        
    end

    %--------------------------------------------------------------------
    function groupingArg = getGroupingArg(expDataForGrouping, subjIDs)
            
        groupingArg = {};
        if isempty(expDataForGrouping)
            return;
        end
        
        [groupPerSubj, groupNames] = tt.inf.getSubjectGroups(expDataForGrouping, subjIDs);
        if length(groupNames) > 1
            fprintf('%d groups: %s, %s\n', length(groupNames), groupNames{1}, groupNames{2});
            groupingArg = {'Group', groupPerSubj};
        end

    end
    
    %--------------------------------------------------------------------
    function [regressionKeys, paramNames, pValNames, allRR, paramMultiplyFactors] = validateAndFixArgs(regressionKeys, paramNames, allRR, analyzeConstByDefault)
        
        if iscell(allRR)
            rr1 = allRR{1};
        else
            rr1 = allRR;
        end
        
        if ischar(paramNames)
            
            if ismember(lower(paramNames), {'allb', 'allbeta'})
                
                bFactor = paramNames(4:end); % remove the "all" prefix
                
                if iscell(regressionKeys)
                    error('When using default parameters, specify just a single regression key!');
                end
                
                if ~analyzeConstByDefault && strcmpi(rr1.avg.(regressionKeys).predictorNames{1}, 'const')
                    ind1 = 2;
                else
                    ind1 = 1;
                end
                
                paramNames = arrayfun(@(p){[p{1} '.' bFactor]}, rr1.avg.(regressionKeys).predictorNames(ind1:end));
                pValNames = arrayfun(@(p){[p{1} '.p']}, rr1.avg.(regressionKeys).predictorNames(ind1:end));
                regressionKeys = arrayfun(@(i){regressionKeys}, 1:length(paramNames));
                
            else
                
                if ~iscell(regressionKeys)
                    error('When a single parameter name, specify a cell array of regression key!');
                end
                
                param1 = paramNames;
                paramNames = arrayfun(@(p){param1}, 1:length(regressionKeys));
                pValNames = {};
                
            end
            
        else
            
            if ~iscell(paramNames)
                error('Param names must be a cell array of strings!');
            end

            if ~iscell(regressionKeys)
                regressionKeys = arrayfun(@(i){regressionKeys}, 1:length(paramNames));
            end

            if (length(regressionKeys) ~= length(paramNames))
                error('Regression keys and param names must have the same number of elements!');
            end
            
            if (analyzeConstByDefault)
                disp('WARNING: The "Const" flag will be ignored because parameter names were explicitly specified');
            end
            
            pValNames = {};
            
        end
        
        if ~iscell(allRR)
            allRR = arrayfun(@(i){allRR}, 1:length(paramNames));
        end
        
        paramMultiplyFactors = ones(1, length(paramNames));
        for i = 1:length(paramNames)
            tokens = regexp(paramNames{i}, '^(.*)([*/])([0-9.-]+)$', 'tokens');
            if isempty(tokens)
                continue;
            end
            tokens = tokens{1};
            operator = tokens{2};
            factor = str2double(tokens{3});
            paramMultiplyFactors(i) = iif(operator=='*', factor, 1/factor);
            paramNames{i} = tokens{1};
        end
        
    end


    %--------------------------------------------------------------------
    function result = createResultObj(allRR, regressionKeys, paramNames, subjIDs, times)

        result = struct;
        result.paramNames = paramNames;
        result.regKeys = regressionKeys;
        result.times = times;
        result.NSubjects = length(subjIDs);
        if isfield(allRR{1}.general, 'MaxTarget')
            result.MaxTarget = allRR{1}.general.MaxTarget;
        end
        
    end

    %--------------------------------------------------------------------
    function updateParamName(result, paramNames, allRR)
        
        anyRR = tt.reg.toRRArray(allRR{1});
        anyRR = anyRR(1);
        
        nParams = length(paramNames);
        for i = 1:nParams
            ind = find(paramNames{i}=='.', 1);
            prmName = paramNames{i}(1:ind-1);
            result.cmpParam(i).ParamName = prmName;
            result.cmpParam(i).ParamDesc = anyRR.(regressionKeys{i}).getPredDesc(prmName);
        end
    end

    %--------------------------------------------------------------------
    function updateMeanValues(result, paramNames, params)
        
        % Get mean values (per time slot) across subject of several parameters.
        % Return a format acceptable by "plotParamComparison"
        % 
        % allRR, regressionKeys: both can be either a cell array or a single value

        nParams = length(paramNames);

        %-- Per parameter, get mean value per time point (over all subjects)
        allValues = cell(1, nParams);
        nAvailableSubjectsPerTimePoint = cell(1, nParams);
        allSD = cell(1, nParams);
        for i = 1:nParams
            allValues{i} = nanmean(params{i}, 2);
            allSD{i} = nanstd(params{i}, 0, 2);
        end

        %-- Extend values so that all are of the same lengths

        nTimePoints = max(arrayfun(@(v)length(v{1}), allValues));

        for i = 1:nParams
            v = allValues{i};
            sd = allSD{i};
            nsubj = nAvailableSubjectsPerTimePoint{i};
            if length(v) < nTimePoints
                nExtend = nTimePoints-length(v);
                v = [v; repmat(v(end), nExtend, 1)]; %#ok<AGROW>
                sd = [sd; repmat(sd(end), nExtend, 1)];  %#ok<AGROW>
                nsubj = [nsubj; repmat(nsubj(end), nExtend, 1)];  %#ok<AGROW>
            end
            
            result.cmpParam(i).values = v;
            result.cmpParam(i).sd_values = sd;
            result.cmpParam(i).nSubjValues = nsubj;
            
        end

    end

    %--------------------------------------------------------------------
    function [allExpData, comparedIndices, compare2TOffset, singleParamComparisonMode, ...
            singleParamComparisonDelay, analyzeConstByDefault, subjIDs, ...
            comparePair1Larger, expectPositiveBValue, excludeNonsignificantValues] = parseArgs(args)
        
        allExpData = [];
        comparedIndices = [];
        comparePair1Larger = 0;
        singleParamComparisonMode = COMPARE_TO_ZERO_WITH_T;
        singleParamComparisonDelay = 0.2;
        analyzeConstByDefault = 0;
        subjIDs = [];
        compare2TOffset = [];
        expectPositiveBValue = [];
        excludeNonsignificantValues = false;
        
        args = stripArgs(args);
        
        while ~isempty(args)
            switch(lower(args{1}))
                case 'groupsubjects'
                    allExpData = args{2};
                    args = args(2:end);
                    
                case 'compare'
                    comparedIndices = args{2};
                    if (numel(comparedIndices) < 2)
                        error('"compare <x> - expecting more than one element!');
                    end
                    args = args(2:end);
                    
                case 'cmp1larger'
                    comparePair1Larger = 1;
                    
                case 'paramsmethod'
                    switch(lower(args{2}))
                        case 'zero'
                            singleParamComparisonMode = COMPARE_TO_ZERO_ANOVA;
                        case 'tzero'
                            singleParamComparisonMode = COMPARE_TO_ZERO_WITH_T;
                        case 'delay'
                            singleParamComparisonMode = COMPARE_TO_ITSELF;
                        otherwise
                            error('Invalid comparison method (%s)', args{2});
                    end
                    args = args(2:end);
                    
                case 'paramsdelay'
                    singleParamComparisonDelay = args{2};
                    if (singleParamComparisonDelay <= 0 || singleParamComparisonDelay > 3) 
                        error('paramsDelay must be a number in the range (0,3]');
                    end
                    args = args(2:end);
                    
                case 'subjids'
                    subjIDs = args{2};
                    args = args(2:end);
                    
                case 'comparetoffset'
                    compare2TOffset = args{2};
                    args = args(2:end);
                    if length(compare2TOffset) ~= 2
                        error('Invalid "CompareTOffset" argument - expecting 2 values!');
                    end
                    
                case 'positiveb'
                    expectPositiveBValue = args{2};
                    args = args(2:end);
                    
                case 'const'
                    analyzeConstByDefault = 1;
                    
                case 'onlysignificant'
                    excludeNonsignificantValues = true;
                    
                otherwise
                    error('Invalid argument: %s', args{1});
            end
            
            args = stripArgs(args(2:end));
            
        end
        
    end

end
