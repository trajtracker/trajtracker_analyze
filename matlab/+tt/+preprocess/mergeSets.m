function raw = mergeSets(inDirNames, outDirName)
%mergeSets(inDirs, outDir) - merge several datasets of subject data
%into a single set.
% 
% inDirs: cell array with names of datasets (directories)
% outDir: Output dataset (directory) name

    raw = struct;
    
    for i = 1:length(inDirNames)
        loadSubjects(inDirNames{i}, i);
    end
    
    disp('Saving...');
    save(strcat(ExpConsts.BinaryDir(outDirName), '/session_data.mat'), 'raw');
    

    %---------------------------------------------------------------------
    function loadSubjects(dirName, subjGroup)
        
        fprintf('Loading %s\n', dirName);
        
        data = load(strcat(ExpConsts.BinaryDir(dirName), '/session_data.mat'));

        for subjID = tt.inf.listInitials(data.raw)
            raw.(subjID{1}) = data.raw.(subjID{1});
            raw.(subjID{1}).Custom.SubjGroup = subjGroup;
        end
    end


end

