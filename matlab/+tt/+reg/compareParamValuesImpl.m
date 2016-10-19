function cmpResult = compareParamValuesImpl(paramValues, testType, varargin)
% result = compareParamValuesImpl(paramValues, testType, ...) - 
% Comapre the values of two or more parameters in all time points.
% DO NOT CALL THIS FUNCTION DIRECTLY. It's an internal function, used by
% other functions.
% 
% paramValues: cell array, each entry = (#timepoints x #subjects) matrix
% testType: 
%   PT      : Paired T (only if paramValues contains 2 entries)
%   UT      : Unpaired T (only if paramValues contains 2 entries)
%   RMANOVA : Repeated measures ANOVA
%   (Future) BANOVA  : Between-subject ANOVA
%
% Optional arguments:
% ValOffset <offset>: Array (same size as "paramValues"), indicating offset
%                     for paramValues (e.g., ValOffset(1)=1 means that we should
%                     consider paramValues{1} starting at index=2).
% 1Larger           : expecting parameter 1 to be larger
% MaxTimeInd <row>  : maximal row to work on
% Group <values>    : One value per subject - grouping factor. To analyze
%                     with ANOVA as a between-subject factor.
% Debug             : debug mode
% 
% The function returns a <a href="matlab:help tt.reg.OnePredGrpRes">tt.reg.OnePredGrpRes</a> object.

    if ~exist('testType', 'var'), error('Invalid function call'); end
    nSubjects = size(paramValues{1}, 2);
    nParams = length(paramValues);
    
    if ismember(lower(testType), {'pt', 'ut'}) && nParams > 2
        error('t-test can be used to compare 2 value sets, not %d', nParams);
    end
    
    [debugMode, valuesOffset, expectingParam1ToBeLarger, maxRow, groupPerSubj] = parseArgs(varargin, nSubjects, nParams);
    nGroups = length(unique(groupPerSubj));
    
    nTimepoints = min(arrayfun(@(v)size(v{1},1), paramValues));
    if ~isempty(maxRow)
        nTimepoints = min(nTimepoints, maxRow);
    end

    cmpResult = tt.reg.OnePredGrpRes(testType, nTimepoints);
    if nGroups > 1
        cmpResult.valuesPerGroup = NaN(nTimepoints, nSubjects, nGroups);
    end
    
    for timeInd = (1+max(valuesOffset)):nTimepoints
        
        if debugMode
            fprintf('Time = %d\n', timeInd);
        end

        switch(lower(testType))
            case 'pt'
                compareValuesWithPairedT(paramValues{1}(timeInd-valuesOffset(1),:)' - paramValues{2}(timeInd-valuesOffset(2),:)', groupPerSubj, timeInd);
                
            case 'ut'
                if ~isempty(groupPerSubj)
                    error('The "Group" flag can only be used for within-subject tests, not for unpaired t test');
                end
                usedLength = min(arrayfun(@(i) length(paramValues{i}(timeInd,:)), 1:length(paramValues)));
                compareValuesWithUnairedT(paramValues{1}(timeInd,1:usedLength)', paramValues{2}(timeInd,1:usedLength)', timeInd);
                
            case 'rmanova'
                comparedValues = arrayfun(@(i){paramValues{i}(timeInd-valuesOffset(i),:)}, 1:length(paramValues));
                if isempty(groupPerSubj)
                    compareWith1WayAnova(comparedValues, timeInd);
                else
                    compareWith2WayAnova(comparedValues, groupPerSubj, timeInd);
                end
                
            otherwise
                error('Unsupported test type "%s"', testType);
        end
    end
    
    %--------------------------------------------------------------------
    % comparedValues: a cell array with data of one time point. Each entry
    %                 is a column vector with one value per subject.
    function compareWith1WayAnova(comparedValues, timeInd)
        
        anovaData = myarrayfun(@(c)c{1}', comparedValues);
        nanRows = isnan(anovaData(:, 1));
        anovaData = anovaData(~nanRows, :);
        [~, table] = anova_rm(anovaData, 'off');
        
        cmpResult.pPred(timeInd) = table{2,6};
        cmpResult.fPred(timeInd) = table{2,5};
        cmpResult.dfPred(timeInd) = table{2,3};
        if expectingParam1ToBeLarger && length(comparedValues)==2
            cmpResult.pPred(timeInd) = iif(mean(comparedValues{1}) > mean(comparedValues{2}), cmpResult.pPred(timeInd)/2, 1);
        end
        cmpResult.esPred(timeInd) = table{2,7};
        
        cmpResult.stats{timeInd} = table;
        
        if debugMode
            fprintf('  Predictor effect p=%.2f F=%.2f df=%d, eta2=%.3f\n', cmpResult.pPred(timeInd), cmpResult.fPred(timeInd), cmpResult.dfPred(timeInd), cmpResult.esPred(timeInd));
        end
        
    end

    %--------------------------------------------------------------------
    % comparedValues: a cell array with data of one time point. Each entry
    %                 is a column vector with one value per subject.
    function compareWith2WayAnova(comparedValues, groupPerSubj, timeInd)
        
        allGroups = unique(groupPerSubj);
        
        % Each entry is a #subjects x #params matrix
        anovaData = cell(1, length(allGroups));
        
        for iGrp = 1:length(allGroups)
            for iParam = 1:length(comparedValues)
                anovaData{iGrp} = [anovaData{iGrp} comparedValues{iParam}(groupPerSubj == allGroups(iGrp))'];
            end
            % Remove subjects who have no value in this time point
            nanRows = isnan(anovaData{iGrp}(:, 1));
            anovaData{iGrp} = anovaData{iGrp}(~nanRows, :);
        end
        
        [~, table] = anova_rm(anovaData, 'off');
        
        cmpResult.pPred(timeInd) = table{2,6};
        cmpResult.fPred(timeInd) = table{2,5};
        cmpResult.dfPred(timeInd) = table{2,3};
        if expectingParam1ToBeLarger && length(comparedValues)==2
            cmpResult.pPred(timeInd) = iif(mean(comparedValues{1}) > mean(comparedValues{2}), cmpResult.pPred(timeInd)/2, 1);
        end
        cmpResult.esPred(timeInd) = table{2,7};
        
        cmpResult.pGroup(timeInd) = table{3,6};
        cmpResult.fGroup(timeInd) = table{3,5};
        cmpResult.dfGroup(timeInd) = table{3,3};
        cmpResult.esGroup(timeInd) = table{3,7};

        cmpResult.pInteraction(timeInd) = table{4,6};
        cmpResult.fInteraction(timeInd) = table{4,5};
        cmpResult.dfInteraction(timeInd) = table{4,3};
        cmpResult.esInteraction(timeInd) = table{4,7};
        
        cmpResult.stats{timeInd} = table;
        
        for iGrp = 1:length(allGroups)
            cmpResult.valuesPerGroup(timeInd, :, iGrp) = mean(anovaData{iGrp});
        end
        
        if debugMode
            fprintf('  Predictor effect p=%.2f F=%.2f df=%d, eta2=%.3f\n', cmpResult.pPred(timeInd), cmpResult.fPred(timeInd), cmpResult.dfPred(timeInd), cmpResult.esPred(timeInd));
            fprintf('  Group effect p=%.2f F=%.2f df=%d, eta2=%.3f\n', cmpResult.pGroup(timeInd), cmpResult.fGroup(timeInd), cmpResult.dfGroup(timeInd), cmpResult.esGroup(timeInd));
            fprintf('  Interaction effect p=%.2f F=%.2f df=%d\n', cmpResult.pInteraction(timeInd), cmpResult.fInteraction(timeInd), cmpResult.dfInteraction(timeInd));
        end
        
    end

    %--------------------------------------------------------------------
    function compareValuesWithPairedT(comparedValues, groupPerSubj, timeInd)
        
        [~,p,~,stat] = ttest(comparedValues);
        cmpResult.fPred(timeInd) = stat.tstat;
        cmpResult.dfPred(timeInd) = stat.df;
        cmpResult.esPred(timeInd) = cohend(comparedValues);
        if expectingParam1ToBeLarger
            p = iif(mean(comparedValues) > 0, p/2, 1);
        end
        cmpResult.pPred(timeInd) = p;
        
        if ~isempty(groupPerSubj)
            
            groups = unique(groupPerSubj);
            if length(groups) ~= 2
                error('Invalid groups: t-test comparison currently supports only two groups, you provided %d', length(groups));
            end
            
            grp1Data = comparedValues(groupPerSubj == groups(1));
            grp2Data = comparedValues(groupPerSubj == groups(2));

            grp1Data = grp1Data(~isnan(grp1Data));  % remove rows with NaN
            grp2Data = grp2Data(~isnan(grp2Data));

            [~, cmpResult.pGroup(timeInd), ~, stat] = ttest2(grp1Data, grp2Data);
            cmpResult.fGroup(timeInd) = stat.tstat;
            cmpResult.dfGroup(timeInd) = stat.df;

        end
        
    end

    %--------------------------------------------------------------------
    function compareValuesWithUnairedT(values1, values2, timeInd)
        
        [~,p,~,stat] = ttest2(values1, values2);
        
        cmpResult.fPred(timeInd) = stat.tstat;
        cmpResult.dfPred(timeInd) = stat.df;
        cmpResult.esPred(timeInd) = cohend([values1 values2]);
        if expectingParam1ToBeLarger
            p = iif(mean(values1) > mean(values2), p/2, 1);
        end
        cmpResult.pPred(timeInd) = p;
        
    end

    %--------------------------------------------------------------------
    function [debugMode, valuesOffset, expectingParam1ToBeLarger, maxTimeInd, groupPerSubj] = parseArgs(args, nSubjects, nParams)
        
        debugMode = 0;
        valuesOffset = zeros(nParams, 1);
        expectingParam1ToBeLarger = 0;
        maxTimeInd = [];
        groupPerSubj = [];
        
        args = stripArgs(args);
        
        while ~isempty(args)
            
            switch(lower(args{1}))
                case 'debug'
                    debugMode = 1;
                    
                case 'valoffset'
                    valuesOffset = args{2};
                    args = args(2:end);
                    
                case '1larger'
                    expectingParam1ToBeLarger = true;
                    if nParams ~= 2
                        error('The "1Larger" flag can only be used when comparing 2 paramerers');
                    end
                    
                case 'maxtimeind'
                    maxTimeInd = args{2};
                    args = args(2:end);
                    
                case 'group'
                    groupPerSubj = args{2};
                    args = args(2:end);
                    if length(groupPerSubj) ~= nSubjects
                        error('Bad "Group" parameter - you specified %d groups but %d subjects', ...
                            length(groupPerSubj), nSubjects);
                    end
                    if length(unique(groupPerSubj)) == 1
                        fprintf('WARNING: All subjects have the same group, ignoring it\n');
                        groupPerSubj =[];
                    end
                    
                otherwise
                    error('Invalid argument "%s"', args{1});
            end
            
            args = stripArgs(args(2:end));
        end
        
    end

end

