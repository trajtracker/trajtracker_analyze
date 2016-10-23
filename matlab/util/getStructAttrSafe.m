function value = getStructAttrSafe(s, attrName, defaultValue)
%value = getStructAttrSafe(s, attrName[, defaultValue]) -
% Get the value of a struct attribute. If the attribute does not exist,
% return a default value.
% 
% Written by Dror Dotan, 2016
    
    if isfield(s, attrName)
        value = s.(attrName);
    elseif exist('defaultValue', 'var')
        value = defaultValue;
    else
        value = [];
    end

end

