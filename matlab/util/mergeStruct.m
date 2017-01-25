function result = mergeStruct(arrayOfStruct)
% result = mergeStruct(cellArrayOfStruct) - Merge several struct's into one.
% Later struct's in the array overrides entries in earlier struct
% 
% Written by Dror Dotan, 2016

    if ~iscell(arrayOfStruct) 
        error('Expecting a cell array input!');
    end
    
    result = struct;
    
    for ind = 1:length(arrayOfStruct)
        
        st = arrayOfStruct{ind};
        
        if ~ isstruct(st) 
            error('The input cell array should contain struct objects! error in index #%d', ind);
        end
        
        keys = fieldnames(st);
        for i = 1:size(keys,1)
            key = char(keys(i,:));
            result.(key) = st.(key);
        end
        
    end

end
