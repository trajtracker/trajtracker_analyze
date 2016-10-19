function initials = listInitials(allED)
% initials = listInitials(allExpData) - Find initials of all subjects
% 
% allExpData: a strcut with one ExperimentData entry per subject, or a struct 
%             with the entries 'd' and 'raw', each of which is a struct of
%             ExperimentData's.
% Return a cell array with initials of all subjects.

    keys = fieldnames(allED);
    if isempty(setdiff(keys, {'raw', 'd'}))
        allED = allED.d;
        initials = tt.inf.listInitials(allED);
        return;
    end
    
    initials = keys';
    ok = arrayfun(@(i)isa(allED.(i{1}), 'ExperimentData') && ~allED.(i{1}).ExcludeFromAverage, initials);
    initials = initials(ok);
    
end
