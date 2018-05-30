function result = reformatOneRRForPlots(subjRR, rrKey, varargin)
%r = reformatOneRRForPlots(subjRR, rrKey, ...) -
% Transform a regression results to a format plottable by <a href="matlab:help tt.reg.plotParamComparison">plotParamComparison()</a>.
%
% Optional arguments:
% Params <cell-array>: list of params to plot
% Beta - Use beta values rather than b values

    rr = subjRR.(rrKey);
    [paramNames, bFactorType] = parseArgs(varargin, rr);

    result = struct;
    if isfield(subjRR, 'MaxTarget')
        result.MaxTarget = subjRR.MaxTarget;
    end
    result.NSubjects = 1;
    result.paramNames = paramNames;
    result.regKeys = arrayfun(@(i){rrKey}, 1:length(paramNames));
    result.times = rr.times;
    result.DependentVar = rr.dependentVar;
    
    cmpParam = [];
    
    for i = 1:length(paramNames)
        b = rr.getPredResult(paramNames{i}).(bFactorType);
        cmp = tt.reg.OnePredGrpRes('1', length(b));
        cmp.ParamDesc = rr.getPredDesc(paramNames{i});
        cmp.values = b;
        if strcmp(bFactorType, 'b')
            cmp.sd_values = rr.getPredResult(paramNames{i}).se_b;
        else
            cmp.sd_values = rr.getPredResult(paramNames{i}).se_beta;
        end
        
        cmp.pPred = rr.getPredResult(paramNames{i}).p;
        
        cmpParam = [cmpParam cmp];
    end
    
    result.cmpParam = cmpParam;
    
    %---------------------------------------------------------------
    function [paramNames, bFactorType] = parseArgs(args, rr)
        
        paramNames = rr.predictorNames(2:end);
        bFactorType = 'b';
        
        args = stripArgs(args);
        while ~isempty(args)
            
            switch(lower(args{1}))
                case 'params'
                    if (iscell(args{2}))
                        paramNames = args{2};
                    elseif sum(arrayfun(@(v)isnumeric(v), args{2})) == length(args{2})
                        paramNames = rr.predictorNames(args{2});
                    elseif strcmpi(args{2}, 'all')
                        paramNames = rr.predictorNames(1:end);
                    else
                        error('Invalid "Params" specification');
                    end
                    args = args(2:end);
                    
                case 'beta'
                    bFactorType = 'beta';
                    
                otherwise
                    Argument = args{1} %#ok<NOPRT,NASGU>
                    error('Unknown argument');
            end
            
            args = stripArgs(args(2:end));
        end
        
    end

end

