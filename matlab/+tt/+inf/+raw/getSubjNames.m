function names = getSubjNames(dirName)
%names = getSubjNames(dirName) -
% Return a list of subject names for a certain dataset

    path = sprintf('%s/%s/raw', TrajTrackerDataPath, dirName);
    filePattern = sprintf('%s/session*.xml', path);
    files = dir(filePattern);
    
    if isempty(files)
        error('No files match the pattern %s', filePattern);
    end
    
    names = cell(1, size(files,1));
    
    for i = 1:size(files,1)
        fn = strcat(path, '/', files(i,1).name);
        contents = xml2struct(fn);
        names{i} = contents.data.session.subject.name.Text;
    end
    
    names = sort(names);
    
end

