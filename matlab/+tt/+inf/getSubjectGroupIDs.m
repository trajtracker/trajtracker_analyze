function [groupIDPerSubj, groupNames, subjectsPerGroup] = getSubjectGroupIDs(allExpData, subjIDs)
%[grpPerSubj, names, subjPerGrp] = getSubjectGroupIDs(allExpData, subjIDs) -
% Get the group ID of each of the subject.
% 
%
% groupIDPerSubj: array with group ID per subject. String group IDs are
%                 translated into integer IDs.
% groupNames: cell array with the name of each group.
% subjectsPerGroup: cell array, each entry is a struct with the
%                 ExperimentData of the group's subjects.

    if ~exist('subjIDs', 'var')
        subjIDs = tt.inf.listInitials(allExpData);
    end
    
    grpPerSubj = arrayfun(@(s){allExpData.(s{1}).Group}, subjIDs);
    groupNames = unique(grpPerSubj);
    groupIDPerSubj = arrayfun(@(g)getGroupID(groupNames, g{1}), grpPerSubj);
    
    if nargout > 2
        subjectsPerGroup = splitSubjectsByGroup(allExpData, subjIDs, groupIDPerSubj, length(groupNames));
    end
    
    %----------------------------------------------------------------------
    function id = getGroupID(groupNames, groupName)
        id = find(arrayfun(@(g)strcmp(groupName, g{1}), groupNames), 1);
    end

    %----------------------------------------------------------------------
    function subjectsPerGroup = splitSubjectsByGroup(allExpData, subjIDs, groupIDPerSubj, nGroups)
        
        subjectsPerGroup = cell(nGroups, 1);
        for i = 1:nGroups
            subjectsPerGroup{i} = struct('general', allExpData.general);
        end
        
        for i = 1:length(subjIDs)
            id = subjIDs{i};
            subjectsPerGroup{groupIDPerSubj(i)}.(id) = allExpData.(id);
        end
        
    end

end
