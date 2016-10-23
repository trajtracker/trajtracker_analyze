function s2 = getStructFields(s1, fieldNames, exclude)
% s = getStructFields(s, fieldNames[, 'exclude']) - get some fields from 
% a struct, return them as a new struct.
% The 3rd argument can optionally indicate to EXCLUDE the provided field
% names.

    exclude = exist('exclude', 'var') && strcmpi(exclude, 'exclude');
    
    
    if exclude
        % remove the given fields
        s2 = s1;
        for i = 1:length(fieldNames)
            f = fieldNames{i};
            if isfield(s2, f)
                s2 = rmfield(s2, f);
            end
        end
    else
        % Leave only the given fields
        s2 = struct;
        for i = 1:length(fieldNames)
            f = fieldNames{i};
            if isfield(s1, f)
                s2.(f) = s1.(f);
            end
        end
    end
    

end

