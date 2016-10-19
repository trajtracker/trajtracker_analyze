function uniqSubjIDs = getSubjIDs(dirName, allowDuplicates)
%uniqSubjIDs = getSubjIDs(dirName[, allowDuplicates]) - 
% Get subject ID's from the raw data directory
% 
% If allowDuplicates=true (default), error if duplicate IDs were found

    path = sprintf('%s/%s/raw', TrajTrackerDataPath, dirName);
    filePattern = sprintf('%s/session*.xml', path);
    files = dir(filePattern);
    
    if isempty(files)
        error('No files match the pattern %s', filePattern);
    end
    
    subjIDs = cell(1, size(files,1));
    
    for i = 1:size(files,1)
        fn = strcat(path, '/', files(i,1).name);
        contents = xml2struct(fn);
        if isfield(contents.data.session.subject.Attributes, 'initials')
            subjID = contents.data.session.subject.Attributes.initials;
        else
            subjName = regexp(contents.data.session.subject.name.Text, ' ', 'split');
            subjID = arrayfun(@(n)n{1}(1), subjName);
        end
        
        subjIDs{i} = lower(subjID);
    end
    
    uniqSubjIDs = unique(subjIDs);
    if exist('allowDuplicates', 'var') && ~allowDuplicates && length(subjIDs) ~= length(uniqSubjIDs)
        nrep = @(sid)sum(arrayfun(@(s)strcmp(s{1}, sid), subjIDs));
        duplicates = uniqSubjIDs(arrayfun(@(s)nrep(s{1})>1, uniqSubjIDs));
        error('There are dupicate subject IDs: %s', join(',', duplicates));
    end
    
    
end

