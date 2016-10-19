function yesOrNo = startsWith(string, prefix, ignoreCase)
%STARTSWITH(string, prefix) - check if string starts with the given prefix
    
    if exist('ignoreCase', 'var') && ignoreCase
        yesOrNo = length(string) >= length(prefix) && strcmpi(string(1:length(prefix)), prefix);
    else
        yesOrNo = length(string) >= length(prefix) && strcmp(string(1:length(prefix)), prefix);
    end
   
end

