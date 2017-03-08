function outDS = filterDataset(inDS, filterFunc, varargin)
%outDS = filterDataset(inDS, filterFuncs, ...) - filter trials for each of 
% the given subjects, and return a new dataset.
% 
% inDS - a struct with "raw" and "d" entries in it
% filterFunc - see <a href="matlab: help tt.util.filterTrials">tt.util.filterTrials</a>
% 
% Optional arguments:
% Dir <relative-path> - set the folder (inside the traj-tracker base path)
%                       of the new dataset 
% Save - save the dataset to "binary" in that folder

    [dsDir, doSave, condName] = parseArgs(varargin);
    
    if isfield(inDS, 'raw')
        % Process "d" and raw
        outDS = struct;
        
        outDS.raw = processDataset(inDS.raw, dsDir, doSave);
        outDS.raw.avg = tt.preprocess.createAvgExpData(outDS.raw);
        outDS.raw.all = tt.preprocess.createExpDataAll(tt.util.structToArray(outDS.raw));
        
        outDS.d = processDataset(inDS.d, dsDir, false);
        outDS.d.all = tt.preprocess.createExpDataAll(tt.util.structToArray(outDS.d));
        
    else
        % inDS has a list of subjects on it
        outDS = processDataset(inDS, dsDir, doSave);
    end

    %----------------------------------------------------------------
    function outDS = processDataset(inDS, dsDir, doSave)
    
        outDS = struct;
        subjIDs = tt.inf.listInitials(inDS);

        for iSubj = 1:length(subjIDs)
            sid = subjIDs{iSubj};

            inED = inDS.(sid);
            outED = inED.clone(0);
            outED.addTrialData(tt.util.filterTrials(inED, filterFunc));

            tt.preprocess.createAverageTrials(outED);
            tt.preprocess.calcInitialDir(outED, 'averages');

            outDS.(sid) = outED;
            fprintf('.');
        end

        fprintf('\n');

        outDS.general = inDS.general;
        outDS.general.CondName = condName;
        
        if ~isempty(dsDir)
            outDS.general.setName = dsDir;
        end

        if doSave
            raw = outDS; %#ok<NASGU>
            save([TrajTrackerDataPath '/' dsDir '/session_data.mat'], 'raw');
        end
    
    end
    
    %------------------------------------
    
    function [dsDir, doSave, condName] = parseArgs(args)
        
        dsDir = '';
        condName = '';
        doSave = false;
        
        args = stripArgs(args);
        while ~isempty(args)
            switch(lower(args{1}))
                case 'save'
                    doSave = true;
                    
                case 'dir'
                    dsDir = args{2};
                    args = args(2:end);
                    
                case 'condname'
                    condName = args{2};
                    args = args(2:end);
                    
                otherwise
                    error('Unsupported argument "%s"', args{1});
            end
            args = stripArgs(args(2:end));
        end
        
        if doSave && isempty(dsDir)
            error('If you specify "save", you must specify DSDir too!');
        end
    end
    
end

