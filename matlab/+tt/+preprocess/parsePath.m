function [subDir, filename] = parsePath(filePath)

    if ~startsWith(filePath, TrajTrackerDataPath)
        error('Invalid path: %s (it is not under %s)', filePath, TrajTrackerDataPath);
    end
    
    relPath = filePath((length(TrajTrackerDataPath)+1) : end);
    if relPath(1) == '/' || relPath(1) == '\'
        relPath = relPath(2:end);
    end
    
    inds = find(relPath == '/' | relPath == '\');
    if length(inds) < 2
        error('Invalid path: %s (expecting %s/xxxx/filename)', filePath, TrajTrackerDataPath);
    end
    
    filename = relPath(inds(end)+1 : end);
    subDir = relPath(1 : inds(end-1)-1);

end
