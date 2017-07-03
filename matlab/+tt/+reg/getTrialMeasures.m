function [measures, outMeasureNames, measureDescs] = getTrialMeasures(expData, trials, measureDescriptors)
% ------------------------------------------------------------------------
% [measures, outMeasureNames, measureDescs] = getTrialMeasures(expData, trials, measureNames) -
% Get values of regression measures that have one value per trial.
%
% trials - a column vector of trials (from the given expData)
% measures - cell array of measures whose value the function will get. Each
%            measure can be:
%            - string descriptor, possibly with arguments. Details below.
%            - Function with this signature:
%              [value, name, description] = f(trials, expData)
%              value: column vector (one numeric value per trial)
%              name: will be used in regression results
%              description: for plots
%
% Return values -
% measures: matrix with cols = measures, rows = trials
% varNames: symbol name of each measure (cell array)
% measureDescs: text description of each measure (cell array)
%
% 
% Valid measure names: (but to make sure, look in the function)
% ====================
% - Custom.xxxx: a custom field
% - Custom.xxxx(#), Custom.xxxx(end), Custom.xxxx(end-#): a custom field, 
%                use the given index.
% - target: the trial.Target field
% - log: log(trial.Target)
% - prevtarget: trial.Target of the previous trial
% - mt: Movement time
% - avgvel : Average velocity (1 / movement_time)
% - yvelocity::row=## : The Y speed at the given row number (if the row
%              number is negative, it refers to row from end of trajectory).
% 
% For numeric targets:
% - units: the unit digit
% - decade_digit, hundred_digit: the decades/hundreds digit
% - decades, hudnreds: the decades/hundreds, as multiplies of 10 or 100
% - logunit, logdecade, loghundred: log of units, decades, or hundreds
% - dprevtarget: absolute distance between current and previous targets
% 
% For number line experiments:
% - ctarget, cprevtarget: targets centered so that the middle of the line is 0.
% - targetside: -1 or 1, depending on whether the target is left/right of
%               the middle.
% - endpoint
% - refpt or ldrfix (they're the same): the reference-points bias function.
%       You can add an optional argument NSeg to specify the number of
%       segments to use (e.g., 'refpt::nseg=3'). Default #segments is 2.
% 
% For decision experiments:
% - Response: The response button clicked
% - CorrectResponse: whether the response was correct (1) or not (0)
% - PrevResponse: Response of the previous trial
% 
% Measure filtering:
% To each of the above measures you can add trial filtering. The filtering
% defines a subset of trials; the measure value will be set to 0 for any
% trial that is not in this subset.
% Filtering is defined using measure arguments, using the following format
% (illustrated for the "MT" measure, movement time):
%   MT::Trial.xx>y : Trial attribute "xx" is larger than y (e.g., MT::Trial.Target>10)
%   MT::Trial.xx<y : Trial attribute smaller than y 
%   MT::Trial.xx=y : Trial attribute equals y 
%   MT::Trial.xx=y1,y2,y3: Trial attribute value is in the list
%   MT::Custom.xx=y : Custom attribute equals the given value
%   MT::Custom.xx in y1,y2,y3: Custom attribute value is in the list
% In comparisons, the 'y' values are assumed to be numeric unless enclosed
% in quotes - e.g., "1". In a comma-separated list of values, the whole list
% (rather than each value) should be enclosed in "".

    if (size(trials, 2) > 1)
        error('"trials" should be a column vector, but it has %d columns!', size(trials, 2));
    end
    
    measures = [];
    outMeasureNames = measureDescriptors;
    measureDescs = cell(1, length(measureDescriptors));

    targets = arrayfun(@(t)t.Target, trials);
    
    for iMeasure = 1:length(measureDescriptors)
        
        descriptor = measureDescriptors{iMeasure};
        
        if isa(descriptor, 'function_handle')
            %-- Custom function
            nFuncArgs = abs(nargout(descriptor));
            if nFuncArgs == 1
                currMeasure = descriptor(trials, expData);
                measureName = sprintf('pred%d', iMeasure);
                currMeasureDesc = '';
            elseif nFuncArgs >= 3
                [currMeasure, measureName, currMeasureDesc] = descriptor(trials, expData);
            else
                error('Invalid get-measure function (%s): it should returns 1 or 3 arguments,', char(descriptor));
            end
            
        elseif ischar(descriptor)
            %-- A known measure (string): parse it
            [measureName, measureArgs] = tt.reg.internal.parseMeasureName(descriptor);
            currMeasureDesc = '';

            %-- Parse the measure: either a custom attribute or a specific measure
            [currMeasure, newName] = tryParseCustomAttrMeasure(measureName, trials);
            if isempty(currMeasure)
                [currMeasure, newName, currMeasureDesc] = parseMeasure(measureName, measureArgs, trials, targets);
            end

            %-- Apply filtering of trials: the measure value is set to non-0
            %-- only for a subset of trials
            [includeTrials, measureNameSuffix] = applyFiltering(trials, measureArgs);
            currMeasure = currMeasure .* includeTrials;
            
            measureName = [newName measureNameSuffix];
            
        else
            
            error('Unsupported measure type (%s): %s', class(descriptor), char(descriptor));
            
        end
        
        measures = [measures currMeasure]; %#ok<*AGROW>
        outMeasureNames{iMeasure} = measureName;
        measureDescs{iMeasure} = iif(isempty(currMeasureDesc), measureName, currMeasureDesc);
        
    end
    
    %-------------------------------------------------------------------
    % Parse a measure as referring to a custom attribute
    % 
    function [values, name] = tryParseCustomAttrMeasure(measureName, trials)
        
        tokens = regexp(measureName, '^Custom\.(\w+)(\(.+\))?$', 'tokens');
        if isempty(tokens) || (~isempty(tokens) && isempty(tokens{1}))
            values = [];
            name = '';
            return;
        end
        
        attrName = tokens{1}{1};
        attrInd = tokens{1}{2};
        if ~isempty(attrInd), attrInd = attrInd(2:end-1); end;
        
        if isempty(attrInd)
            %-- No index provided
            values = arrayfun(@(t)t.Custom.(attrName), trials);
            name = strcat('custom_', attrName);
            
        else
            %-- Index provided
            if startsWith(lower(attrInd), 'end-')
                index = str2double(attrInd(5:end));
                values = arrayfun(@(t)t.Custom.(attrName)(end-index), trials);
                name = sprintf('custom_%s_end_%d', attrName, index);
            elseif strcmpi(attrInd, 'end')
                values = arrayfun(@(t)t.Custom.(attrName)(end), trials);
                name = sprintf('custom_%s_end', attrName);
            else
                index = str2double(attrInd);
                values = arrayfun(@(t)t.Custom.(attrName)(index), trials);
                name = sprintf('custom_%s_%d', attrName, index);
            end
        end
        
    end

    %-------------------------------------------------------------------
    % Parse a measure as one of the known list
    % 
    function [currMeasure, measureName, measureDesc] = parseMeasure(measureName, measureArgs, trials, targets)
        
        measureDesc = '';
        
        switch(lower(measureName))
            
            %-------- Trial-in-session ------------
            case 'trialindex'
                currMeasure = arrayfun(@(t)t.TrialIndex, trials);
                measureDesc = 'Trial number';
                
            case 'sqrtrialindex'
                currMeasure = sqrt(arrayfun(@(t)t.TrialIndex, trials));
                measureDesc = 'sqrt(trial number)';
            
            %-------- Stimulus ------------
            
            case 'target'
                currMeasure = targets;
                measureDesc = 'Target';

            case 'log'
                currMeasure = nlLog(targets, expData.MaxTarget);
                measureDesc = 'Log';

            case 'prevtarget'
                [currMeasure, vn] = getAttrInDistance(trials, measureArgs, 'PrevTarget');
                currMeasure(isnan(currMeasure)) = 0;
                if ~isempty(vn)
                    measureName = vn;
                end
                measureDesc = 'Prev Target';
                
            case 'dprevtarget'
                [prevTarget, vn] = getAttrInDistance(trials, measureArgs, 'PrevTarget');
                currMeasure = abs(prevTarget - targets);
                currMeasure(isnan(currMeasure)) = 0;
                if ~isempty(vn)
                    measureName = vn;
                end
                measureDesc = '|Target-Prev|';
                
            case 'nexttarget'
                [currMeasure, vn] = getAttrInDistance(trials, measureArgs, 'NextTarget');
                currMeasure(isnan(currMeasure)) = 0;
                if ~isempty(vn)
                    measureName = vn;
                end
                measureDesc = 'Next Target';
                
            case 'ctarget' % Target, centered around the middle
                midTarget = expData.MaxTarget/2;
                currMeasure = targets - midTarget;
                measureDesc = 'Target (centered)';
                
            case 'cprevtarget' % Previous target, centered around the middle
                midTarget = expData.MaxTarget/2;
                [currMeasure, vn] = getAttrInDistance(trials, measureArgs, 'CPrevTarget');
                currMeasure = currMeasure - midTarget;
                currMeasure(isnan(currMeasure)) = 0;
                if ~isempty(vn), measureName = vn; end
                measureDesc = 'Prev Target (centered)';
                
            case 'cnexttarget'
                currMeasure = arrayfun(@(t)t.Custom.NextTarget, trials) - expData.MaxTarget/2;
                measureDesc = 'Next Target (centered)';
                
            case 'target_dmid' % Target distance from middle of line
                midTarget = expData.MaxTarget/2;
                currMeasure = abs(targets - midTarget);
                measureDesc = '|Target-Middle|';
                
            case 'log_dmid' % Target distance from middle of line
                midTarget = expData.MaxTarget/2;
                currMeasure = log(abs(targets - midTarget)+1) / log(midTarget+1) * midTarget;
                measureDesc = 'log|Target-Middle|';
                
            case 'targetside'
                midTarget = expData.MaxTarget/2;
                currMeasure = (targets > midTarget) * 2 - 1; % either -1 or 1
                measureDesc = 'Side';
                
            %--------------------
                
            case {'ep', 'x_nl'}
                currMeasure = arrayfun(@(t)t.EndPoint, trials);
                measureDesc = 'Endpoint';
            
            case 'x'
                currMeasure = arrayfun(@(t)t.Trajectory(end, TrajCols.X), trials);
                measureDesc = 'Endpoint';
            
            case 'mt'
                currMeasure = arrayfun(@(t)t.MovementTime, trials);
                measureDesc = 'Movement time';
                
            case 'avgvel'
                currMeasure = arrayfun(@(t)1/t.MovementTime, trials);
                measureDesc = 'Speed';
            
            case 'yvelocity'
                [currMeasure, measureName, rn] = getTrajValueAtTime(trials, TrajCols.YVelocity, measureArgs, 'yvel');
                measureDesc = sprintf('Y speed @ row#%d', rn);
            
            %---------- decomposed digits + their logs -------------

            case 'hundreds'
                currMeasure = floor(targets/100) * 100;
                measureDesc = 'Hundreds';

            case 'hundred_digit'
                currMeasure = mod(floor(targets/100), 10);
                measureDesc = 'Hundreds digit';
                
            case 'decades' % the value of this predictor is unlimited
                currMeasure = floor(targets/10) * 10;
                measureDesc = 'Decades';

            case 'decades90' % This predictor is limited to 0-90 (if target=100, the predictor value is 0)
                currMeasure = mod(floor(targets/10) * 10, 100);
                measureDesc = 'Decades';

            case 'decade_digit'
                currMeasure = mod(floor(targets/10), 10);
                measureDesc = 'Decade digit';
                
            case 'units'
                currMeasure = mod(targets,10);
                measureDesc = 'Units';

            case 'loghundred'
                hundred = floor(targets/100) * 100;
                currMeasure = nlLog(hundred, min(expData.MaxTarget, 1000));
                measureDesc = 'Log(hundreds)';

            case 'logdecade'
                decade = floor(targets/10) * 10;
                currMeasure = nlLog(decade, min(expData.MaxTarget, 100));
                measureDesc = 'Log(decade)';

            case 'logunit'
                currMeasure = nlLog(mod(targets, 10), 10);
                measureDesc = 'Log(unit)';

            %-- Reference points
            case {'ldrfix', 'refpt'}
                args = tt.reg.internal.parseMeasureArgs(measureArgs, {'nseg'}, true, false, 'RefPoints');
                nSegments = iif(isempty(args{1}), 2, args{1});
                currMeasure = refPointsMapping(targets, expData.MaxTarget, nSegments) - targets;
                measureDesc = iif(isempty(args{1}), 'Ref points', sprintf('%d ref points', nSegments+1));

            %-------- Decision experiments -----------
            
            case 'correctresponse'
                currMeasure = arrayfun(@(t)t.IsCorrectResponse, trials);
                
            case 'response'
                currMeasure = arrayfun(@(t)t.UserResponse, trials);
                
            case 'prevresponse'
                currMeasure = arrayfun(@(t)t.PrevResponse, trials);
                
            %-------- END -----------
            otherwise
                error('Unsupported trial measure "%s"', measureName);
        end
        
        
    end

    %-------------------------------------------------------------------
    function [includeTrials, measureNameSuffix] = applyFiltering(trials, measureArgs)
    
        includeTrials = ones(length(trials), 1);
        measureNameSuffix = '';
        
        for arg = measureArgs
            
            ii = find(arg{1} == '.', 1);
            if isempty(ii)
                continue;
            end
            
            objType = arg{1}(1:ii-1);
            arg = arg{1}(ii+1:end); %#ok<FXSET>
            
            tokens = regexp(arg, '^(\w+)(=|>|<|( in ))(.*)$', 'tokens');
            if ~isempty(tokens)
                tokens = tokens{1};
                attrName = tokens{1};
                operator = tokens{2};
                refValue = tokens{3};
                
                getAttrValue = iif(strcmpi(objType,'trial'), @(trial)trial.(attrName), @(trial)trial.Custom.(attrName));
                
                isStringVal = refValue(1) == '"' && refValue(end) == '"';
                if isStringVal
                    refValue = refValue(2:end-1);
                end
                if ismember(operator, {'>', '<'}), isStringVal = false; end
                
                %-- Convert a single numeric value to number
                if ~strcmpi(operator, ' in ')
                    if isStringVal
                        refValueName = refValue;
                    else
                        refValue = str2double(refValue);
                        refValueName = strrep(formatRealNumber(refValue), '.', 'o');
                        refValueName = strrep(refValueName, '-', 'm');
                    end
                end
                
                
                switch(operator)
                    case '='
                        opDesc = 'eq';
                        if isStringVal
                            matchingTrials = arrayfun(@(t)strcmp(getAttrValue(t), refValue), trials);
                        else
                            matchingTrials = arrayfun(getAttrValue, trials) == refValue;
                        end
                        
                    case '>'
                        opDesc = 'gt';
                        matchingTrials = arrayfun(getAttrValue, trials) > refValue;
                        
                    case '<'
                        opDesc = 'lt';
                        matchingTrials = arrayfun(getAttrValue, trials) < refValue;
                        
                    case ' in '
                        opDesc = 'in';
                        
                        %-- parse multiple values
                        refValue = regexp(refValue, ',', 'split');
                        refValueName = join('_', refValue);
                        if isStringVal
                            values = arrayfun(@(t){getAttrValue(t)}, trials);
                            refValue = arrayfun(@(v)str2double(v{1}), refValue);
                        else
                            % numeric
                            values = arrayfun(getAttrValue, trials);
                        end
                        matchingTrials = ismember(values, refValue);
                        
                    otherwise
                        error('Unsupported operator "%s"', operator);
                end
                
                includeTrials = includeTrials & matchingTrials;
                measureNameSuffix = sprintf('%s_%s_%s_%s', measureNameSuffix, attrName, opDesc, refValueName);
                
            end
            
        end
        
    end
    
    
    %-------------------------------------------------------------------
    function [result, varName, rowNum] = getTrajValueAtTime(trials, trajCol, measureArgs, colName)
        
        rowNum = NaN;
        for iArg = 1:length(measureArgs)
            ttokens = regexp(measureArgs{1}, '^row=([-]?\d+)$', 'tokens');
            if ~isempty(ttokens)
                rowNum = str2double(ttokens{1});
                break;
            end
        end
        
        if isnan(rowNum)
            error('Invalid predictor definition - can''t access traj column #%d because row num was not specified as "row=xxx"', trajCol);
        end
        
        result = common.getTrajValueAtTime(trials, rowNum, trajCol);
        
        if rowNum > 0
            varName = sprintf('%s_%d', colName, rowNum);
        else
            varName = sprintf('%s_end_%d', colName, -rowNum);
        end
        
    end

    %-------------------------------------------------------------------
    function [result, varName] = getAttrInDistance(trials, measureArgs, varNamePrefix)
        result = NaN;
        varName = '';

        for iArg = 1:length(measureArgs)
            ttokens = regexp(measureArgs{1}, '^d=(.*)$', 'tokens');
            if ~isempty(ttokens)
                % Target of Nth last trial
                prevTargetNum = str2double(ttokens{1});
                prevTargetAttr = sprintf('%s%d', varNamePrefix, prevTargetNum);
                invalidTrials = arrayfun(@(t)~isfield(t.Custom, prevTargetAttr), trials);
                if (sum(invalidTrials) > 0)
                    InvalidTrialIndices = find(invalidTrials)' %#ok<NOPRT,NASGU>
                    error('Subject %s: %d trials do not have a "%s" custom attribute. Did you call updatePrevTargets() to update this experiment?', upper(expData.SubjectInitials), sum(invalidTrials), prevTargetAttr);
                end
                result = arrayfun(@(t)t.Custom.(prevTargetAttr), trials);
                varName = prevTargetAttr;
                break;
            end
        end

        if isnan(result)
            % Use target of the prev/next trial
            switch(lower(varNamePrefix))
                case 'prevtarget'
                    result = arrayfun(@(t)t.PrevTarget, trials);
                case 'nexttarget'
                    result = arrayfun(@(t)t.Custom.NextTarget, trials);
            end
        end
        
    end
    
end
