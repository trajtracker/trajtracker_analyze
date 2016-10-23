function edArray = structToArray(edStruct, subjIDs)
% edArray = structToArray(edStruct[, subjIDs])
% Convert a struct with several ExpData's into an array

    if isempty(setdiff(fieldnames(edStruct), {'raw', 'd'}))
        error('Please provide "dataset.d" or "dataset.raw" as the argument');
    end
    
    if ~exist('subjIDs', 'var')
        subjIDs = tt.inf.listInitials(edStruct);
    end
    
    edArray = myarrayfun(@(id)edStruct.(id{1}), subjIDs);
    
end
