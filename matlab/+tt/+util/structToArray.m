function edArray = structToArray(edStruct, subjIDs)
% edArray = structToArray(edStruct[, subjIDs])
% Convert a struct with several ExpData's into an array

    if ~exist('subjIDs', 'var')
        subjIDs = tt.inf.listInitials(edStruct);
    end
    
    edArray = myarrayfun(@(id)edStruct.(id{1}), subjIDs);
    
end
