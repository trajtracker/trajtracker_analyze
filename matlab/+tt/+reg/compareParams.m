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
% regressionKeys, paramNames - two cell arrays, in identical sizes,
%              indicating which parameters to compare. Each entry in
%              "regressionKeys" indicates the name of a field in "allRR",
%              and each entry in "paramNames" is the name of a field in
%              allRR.(regressionKey)
%              You can specify a single regression name for
%              "regressionKeys" (not a cell array) and a value 'allb'/'allbeta' for
%              paramNames - this means to use all b/beta values of that
%              regression.
%
% Optional arguments:
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
% Multiply <param-name> <factor>: Multiply the values of the given
%               parameter by the given factor.
% OnlySignificant: exclude non-significant b values from the comparison

    % Comparison methods for a single parameter
    COMPARE_TO_ZERO_ANOVA = 1;
    COMPARE_TO_ZERO_WITH_T = 2;
    COMPARE_TO_ITSELF = 3;
    
    [expDataForGrouping, comparedIndices, compare2TOffset, singleParamComparisonMode, singleParamComparisonDelay, ...
        analyzeConstByDefault, subjIDs, comparePair1Larger, paramMultiplyFactors, ...
        expectPositiveBValue, excludeNonsignificantValues] = parseArgs(varargin);
    
    [regressionKeys, paramNames, pValNames, allRR] = validateAndFixArgs(regressionKeys, paramNames, allRR, analyzeConstByDefault);
    
    if isempty(expectPositiveBValue)
        expectPositiveBValue = true(1, length(paramNames));
    end
    
    anyRR = allRR{1}.avg.(regressionKeys{1});
    
    [params, times, subjIDs] = getAllParamValues(allRR, regressionKeys, paramNames, pValNames, subjIDs);
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
    updateMeanValues(result, allRR, regressionKeys, paramNames, subjIDs, paramMultiplyFactors);
    
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
        
        if isempty(groupSubjectsArg);
            result.comparePair = tt.reg.internal.compareParamValues(params(comparedIndices), 'PT', cmpArgs);
        else
            result.comparePair = tt.reg.internal.compareParamValues(params(comparedIndices), 'RMAnova', groupSubjectsArg, cmpArgs);
        end
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
            groupSubjectsArg = {'Group', groupPerSubj};
        end

    end
    
    %--------------------------------------------------------------------
    function [regressionKeys, paramNames, pValNames, allRR, paramMultiplyFactors] = validateAndFixArgs(regressionKeys, paramNames, allRR, analyzeConstByDefault)
        
        paramMultiplyFactors = ones(1,100);
        
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
                
                ind1 = 1;
                if strcmpi(rr1.avg.(regressionKeys).predictorNames{1}, 'const')
                    if (analyzeConstByDefault)
                        paramMultiplyFactors(1) = 1/allRR.general.MaxTarget;
                    else
                        ind1 = 2;
                    end
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
        
        nParams = length(paramNames);
        for i = 1:nParams
            ind = find(paramNames{i}=='.', 1);
            name = paramNames{i}(1:ind-1);
            result.cmpParam(i).ParamName = name;
            result.cmpParam(i).ParamDesc = allRR{1}.avg.(regressionKeys{i}).getPredDesc(name);
        end
    end

    %--------------------------------------------------------------------
    function updateMeanValues(result, allRR, regressionKeys, paramNames, subjIDs, paramMultiplyFactors)
        % Get mean values (per time slot) across subject of several parameters.
        % Return a format acceptable by "plotParamComparison"
        % 
        % allRR, regressionKeys: both can be either a cell array or a single value
        % 
        % Optional arguments:
        % SubjIDs : subject IDs

        nParams = length(paramNames);

        %-- Per parameter, get mean value per time point (over all subjects)
        allValues = cell(1, nParams);
        allSD = cell(1, nParams);
        rTimes = [];
        for i = 1:nParams
            [paramValues, pTimes, subjIDs] = tt.reg.getRRCoeffs(allRR{i}, regressionKeys{i}, paramNames{i}, 'SubjIDs' , subjIDs);
            allValues{i} = nanmean(paramValues, 2);
            allSD{i} = nanstd(paramValues, 0, 2);
            if length(pTimes) > length(rTimes)
                rTimes = pTimes;
            end
        end

        %-- Extend values so that all are of the same lengths

        nTimePoints = max(arrayfun(@(v)length(v{1}), allValues));

        for i = 1:nParams
            v = allValues{i};
            sd = allSD{i};
            if length(v) < nTimePoints
                v = [v; repmat(v(end), nTimePoints-length(v), 1)]; %#ok<AGROW>
                sd = [sd; repmat(sd(end), nTimePoints-length(sd), 1)];  %#ok<AGROW>
            end
            
            if isfield(paramMultiplyFactors, paramNames{i})
                factor = paramMultiplyFactors.(paramNames{ii});
                v = v .* factor;
                sd = sd .* factor;
            end
            
            result.cmpParam(i).values = v;
            result.cmpParam(i).sd_values = sd;
            
        end

        
    end

    %--------------------------------------------------------------------
    function [allExpData, comparedIndices, compare2TOffset, singleParamComparisonMode, ...
            singleParamComparisonDelay, analyzeConstByDefault, subjIDs, ...
            comparePair1Larger, paramMultiplyFactors, expectPositiveBValue, excludeNonsignificantValues] = parseArgs(args)
        
        allExpData = [];
        comparedIndices = [];
        comparePair1Larger = 0;
        singleParamComparisonMode = COMPARE_TO_ZERO_WITH_T;
        singleParamComparisonDelay = 0.2;
        analyzeConstByDefault = 0;
        subjIDs = [];
        compare2TOffset = [];
        paramMultiplyFactors = struct;
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
                    
                case 'multiply'
                    mParamName = args{2};
                    mParamFactor = args{3};
                    args = args(3:end);
                    paramMultiplyFactors.(mParamName) = mParamFactor;
                    
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
