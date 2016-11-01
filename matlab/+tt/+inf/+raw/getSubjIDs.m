function result = getSubjIDs(dirName, varargin)
%uniqSubjIDs = getSubjIDs(dirName, ...) - 
% Get subject ID's from the raw data directory
% 
% Optional arguments:
% NoDup: error if duplicate IDs were found with different names
% All: output all ID's (don't exclude duplicate ID's)

    [allowDuplicates, outputAll] = parseArgs(varargin);
    
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
    
    result = iif(outputAll, subjIDs, uniqSubjIDs);
    
    %-------------------------------------------
    function [allowDuplicates, outputAll] = parseArgs(args)

        allowDuplicates = true;
        outputAll = false;
        
        args = stripArgs(args);
        while ~isempty(args)
            switch(lower(args{1}))
                case 'nodup'
                    allowDuplicates = false;
                    
                case 'all'
                    outputAll = true;

                otherwise
                    error('Unsupported argument "%s"!', args{1});
            end
            args = stripArgs(args(2:end));
        end

    end

    
end

