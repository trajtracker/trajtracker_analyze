function allInitials = getSubjInitials(allRegResults)
% allInitials = getSubjInitials(regResults) - Get initials of all
% subjects from a regression-results struct

    subjectNames = fieldnames(allRegResults);
    allInitials = {};
    
    for iSubj = 1:length(subjectNames)
        subj = subjectNames{iSubj};
        rr = allRegResults.(subj);
        if (~ isstruct(rr) || strcmp(subj, 'general') || strcmp(subj, 'avg'))
            continue;
        end
        
        allInitials = [allInitials subj]; %#ok<AGROW>
    end
    
end
