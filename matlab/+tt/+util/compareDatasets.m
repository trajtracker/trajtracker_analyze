function anovaTab = compareDatasets(datasets, varargin)
% result = compareSubjects(datasets, ...) -
% Compare values between datasets with repeated measures ANOVA with the
% subject as the random factor.
%
% datasets: one per condition
% 
% Optional arguments:
% SubjFunc <functon>: Get value per subject
% TrialFunc <function>: Get value per trial (compare subject averages)
% Print - print results
% Desc - description of results (when printing)

    [getSubjValueFunc, printResult, printDesc] = parseArgs(varargin);

    subjIDs = tt.inf.listInitials(datasets{1});
    
    anovaData = [];
    for iCond = 1:length(datasets)
        condVals = arrayfun(@(sid)getSubjValueFunc(datasets{iCond}.(sid{1})), subjIDs);
        anovaData = [anovaData condVals'];
    end
    
    [~,anovaTab] = anova_rm(anovaData, 'off');
    
    if printResult
        df = anovaTab{2,3};
        dfe = anovaTab{4,3};
        F = anovaTab{2,5};
        p = anovaTab{2,6};
        fprintf('%sF(%d,%d) = %.3f, p = %.3f\n', printDesc, df, dfe, F, p);
    end
    
    
    %--------------------------------------------------------
    function [getSubjValueFunc, printResult, printDesc] = parseArgs(args)
        
        getSubjValueFunc = [];
        printResult = false;
        printDesc = '';
        
        args = stripArgs(args);
        while ~isempty(args)
            switch(lower(args{1}))
                case 'subjfunc'
                    getSubjValueFunc = args{2};
                    args = args(2:end);
                    
                case 'trialfunc'
                    f = args{2};
                    args = args(2:end);
                    if nargin(f) == 1
                        getSubjValueFunc = @(expData)mean(arrayfun(f, expData.Trials));
                    else
                        getSubjValueFunc = @(expData)mean(arrayfun(@(t)f(t,expData), expData.Trials));
                    end
                    
                case 'trialattr'
                    attrName = args{2};
                    args = args(2:end);
                    getSubjValueFunc = @(expData)mean(arrayfun(@(t)t.(attrName), expData.Trials));
                    if isempty(printDesc)
                        printDesc = ['Trial.' attrName ': '];
                    end
                    
                case 'trialcustomattr'
                    attrName = args{2};
                    args = args(2:end);
                    getSubjValueFunc = @(expData)mean(arrayfun(@(t)t.Custom.(attrName), expData.Trials));
                    if isempty(printDesc)
                        printDesc = ['Trial.Custom.' attrName ': '];
                    end
                    
                case 'print'
                    printResult = true;
                    
                case 'desc'
                    printDesc = [args{2} ': '];
                    args = args(2:end);
                    
                otherwise
                    error('Unsupported argument "%s"', args{1});
            end
            args = stripArgs(args(2:end));
        end
        
        
        if isempty(getSubjValueFunc)
            error('You did not specify the value to compare');
        end
        
    end

end

