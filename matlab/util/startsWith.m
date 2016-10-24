function yesOrNo = startsWith(string, prefix, ignoreCase)
%STARTSWITH(string, prefix) - check if string starts with the given prefix
    
    if exist('ignoreCase', 'var') && ignoreCase
        string = lower(string);
        prefix = lower(prefix);
    end
    
    if iscell(prefix)
        
        yesOrNo = false;
        for i = 1:length(prefix)
            if startsWith(string, prefix{i})
                yesOrNo = true;
                break;
            end
        end
        
    else
        
        yesOrNo = length(string) >= length(prefix) && strcmp(string(1:length(prefix)), prefix);
        
    end
   
end

