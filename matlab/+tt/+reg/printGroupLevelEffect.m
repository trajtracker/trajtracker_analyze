function printGroupLevelEffect(allRR, rrKey, varargin)
%printGroupLevelEffect(cmpData, ...) -
% Print regression results - the b/beta values and whether the group-level effect
% is significant or not.
% 
% allRR: struct with regression results per subject
% rrKey: Regression key (the entry in the per-subject struct)
% 
% Optional arguments:
% Param <char / cell array>: name(s) of predictor(s) to print
% Prefix <char / cell array>: prefix(es) of predictor(s) to print
% Time <#>: print the given time point. Negative value = time from end of
%           trajectory.
% RRIndex <#>: Print the given time point, but here the time point is
%           provided as an index number in the array of b values. index<=0
%           means distance from end of trajectory.
% Beta: use beta rather than b values.
    
    [paramNameFilter, bType, getRowNumFunc] = parseArgs(varargin);

    allParamNames = allRR.avg.(rrKey).predictorNames;
    paramNames = allParamNames(logical(arrayfun(@(p)paramNameFilter(p{1}), allParamNames)));
    if isempty(paramNames)
        fprintf('printGroupLevelEffect() WARNING: No matching predictor name was found\n');
        return;
    end
    
    paramNames = arrayfun(@(p){[p{1} '.' bType]}, paramNames);
    
    cmpResult = tt.reg.compareParams(allRR, rrKey, paramNames);
    
    for cmp = cmpResult.cmpParam
        row = getRowNumFunc(cmpResult, cmp);
        p = cmp.pPred(row);
        fprintf('%s[%s] = %.3f, p = %s %s\n', bType, cmp.ParamName, cmp.values(row), format_pval(p), getSignificance(p));
    end
    
    %----------------------------------------------
    function s = getSignificance(p)
        if (p < .001)
            s = '(***)';
        elseif (p < .01)
            s = '(**)';
        elseif (p < .05)
            s = '(*)';
        elseif (p < .1)
            s = '(+)';
        else
            s = '';
        end
    end


    %-------------------------------------------
    function row = getRowNum(cmpResults, ~, rowNum)
        row = max(abs(rowNum), 1);
        row = min(row, length(cmpResults.times));
        if rowNum <= 0
            row = length(cmpResults.times) - row;
        end
    end
    
    %-------------------------------------------
    function row = getRowForTime(cmpResult, ~, time)
        if time < 0
            time = cmpResult.times(end)+time;
        end
        row = find(cmpResult.times >= abs(time)-0.0001, 1);
        if isempty(row), row = length(cmpResult.times); end % get last index
    end
    
    
    %-------------------------------------------
    function [paramNameFilter, bType, getRowNumFunc] = parseArgs(args)

        paramNameFilter = [];
        bType = 'b';
        isBeta = false;
        getRowNumFunc = @(cmpResult, cmp)1;
        
        args = stripArgs(args);
        while ~isempty(args)
            switch(lower(args{1}))
                case 'param'
                    paramName = args{2};
                    if ischar(paramName)
                        paramNameFilter = @(p)strcmpi(p, paramName);
                    elseif iscell(paramName)
                        paramName = lower(paramName);
                        paramNameFilter = @(p)ismember(lower(p), paramName);
                    else
                        error('Invalid "Param" argument: %s', param);
                    end
                    args = args(2:end);

                case 'prefix'
                    pref = args{2};
                    paramNameFilter = @(p)startsWith(p, pref, true);
                    args = args(2:end);

                case 'paramnamefilter'
                    paramNameFilter = args{2};
                    args = args(2:end);

                case 'rrindex'
                    rowNum = args{2};
                    args = args(2:end);
                    getRowNumFunc = @(cmpResult, cmp)getRowNum(cmpResult, cmp, rowNum);
                    
                case 'time'
                    time = args{2};
                    args = args(2:end);
                    getRowNumFunc = @(cmpResult, cmp)getRowForTime(cmpResult, cmp, time);
                    
                case 'beta'
                    bType = 'beta';
                    isBeta = true;
                    
                otherwise
                    error('Unsupported argument "%s"!', args{1});
            end
            args = stripArgs(args(2:end));
        end

        if isempty(paramNameFilter)
            paramNameFilter = iif(isBeta,  @(p)~strcmp(p, 'const'),  @(p)true);
        end
        
    end

end

