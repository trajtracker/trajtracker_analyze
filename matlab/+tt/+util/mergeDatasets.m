function mergedDS = mergeDatasets(allExpData, varargin)
%mergedED = mergeDatasets(allExpData, ...) -
% Merge several datasets into a single dataset.
% 
% Optional args:
% SaveDS <custom-attr-name> <cell-array> : Save on each trial an indication of
%                the dataset it came from, as a custom attribute. The cell
%                array contains one value per dataset.
% SetName : Update expData.SetName for each merged subject data.

    if isfield(allExpData{1}, 'raw')
        rawArray = arrayfun(@(ed){ed{1}.raw}, allExpData);
        dArray = arrayfun(@(ed){ed{1}.d}, allExpData);
        mergedDS = struct;
        mergedDS.raw = tt.util.mergeDatasets(rawArray, varargin);
        mergedDS.d = tt.util.mergeDatasets(dArray, varargin);
        return;
    end

    
    [sourceDSAttrName,sourceDSNames, newSetName] = parseArgs(varargin);
    
    firstCond = allExpData{1};
    
    mergedDS = struct;
    
    genInfo = firstCond.general;
    genInfo.setName = newSetName;
    genInfo.CondName = newSetName;
    mergedDS.general = genInfo;
    
    
    initials = tt.inf.listInitials(firstCond);
    
    for iSubj = 1:length(initials)
        sid = initials{iSubj};
        
        newExpData = NLExperimentData(genInfo.MaxTarget, sid, firstCond.(sid).SubjectName);
        anyED = allExpData{1}.(sid);
        newExpData.PixelsPerUnit = anyED.PixelsPerUnit;
        newExpData.YPixelsShift = anyED.YPixelsShift;
        
        for iDS = 1:length(allExpData)
            origED = allExpData{iDS}.(sid);
            newExpData.addAllTrialsOf(origED);
            
            if ~isempty(sourceDSAttrName)
                for t = origED.Trials
                    t.Custom.(sourceDSAttrName) = sourceDSNames{iDS};
                end
            end
        end
        
        mergedDS.(sid) = newExpData;
        
    end
    
    %-----------------------------------------------
    function [sourceDSAttrName, sourceDSNames, newSetName] = parseArgs(args)
        
        sourceDSAttrName = '';
        sourceDSNames = {};
        newSetName = 'MERGED';
        
        args = stripArgs(args);
        while ~isempty(args)
            
            switch(lower(args{1}))
                case 'saveds'
                    sourceDSAttrName = args{2};
                    sourceDSNames = args{3};
                    args = args(3:end);
                    
                case 'setname'
                    newSetName = args{2};
                    args = args(2:end);
                    
                otherwise
                    error('Unsupported argument "%s"', args{1});
            end
            
            args = stripArgs(args(2:end));
            
        end
        
    end

end
