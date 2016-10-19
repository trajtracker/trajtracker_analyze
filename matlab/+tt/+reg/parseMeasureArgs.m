function argValues = parseMeasureArgs(predArgs, argNames, isOptional, errorIfUnknownArg, predName)
%argValues = parseMeasureArgs(predArgs, argNames, isOptional, errorIfUnknownArg, predName)
% Parse arguments of predictor. Each argument is expected to be in the form
% name=value.
% 
% Function parameters:
% predArgs: cell array of arguemnts
% argNames: cell array of arguemnt names
% isOptional: flags indicating whether each arg is optional
% errorIfUnknown: single flag, indicating if to allow unknown arg names
% predName: Name of the predictor
%
% Return cell array of values. An empty cell in the array indicates value
% not found.

    argValues = cell(1, length(argNames));
    
    for iArg = 1:length(predArgs)
        
        currArgProcessed = false;
        
        for iName = 1:length(argNames)
            
            tokens = regexp(predArgs{iArg}, ['^' argNames{iName} '=(.*)$'], 'tokens');
            if ~isempty(tokens)
                currArgProcessed = true;
                argValues{iName} = tokens{1};
                if iscell(argValues{iName})
                    argValues{iName} = argValues{iName}{1};
                end
                break;
            end
            
        end
        
        if errorIfUnknownArg && ~currArgProcessed
            error('Invalid argument (%s) for predictor "%s"', predArgs{iArg}, predName);
        end
        
    end
    
    for iName = find(~isOptional)
        if isempty(argValues{iName})
            error('Argument "%s" was not provided for predictor "%s"', argNames{iName}, predName);
        end
    end

end

