function preprocessSet(subDir, varargin)
%preprocessSet(subDir, ...) - prepare a dataset for use.
% 
% subDir: the name of a directory under the base data path.
% 
% If your data was obtained from an old version of the iPad software, you
% may need to run, prior to this function, a preprocessing perl script
% (preprocessSet.pl)
% 
% Optional arguments:
% SubjIDs <ids> - work only on these ID's
% ProcessDSFunc <func> - run this function after preprocessing and loading
%                        has ended. Signature: @(dataset)->dataset
%                        Where 'dataset' is a struct with one ExperimentData
%                        object per subject.
% And any argument acceptable by <a href="matlab:help tt.preprocess.loadSessionAsExpData">loadSessionAsExpData</a>
% 
% 
% Keeping the experiment data on your file system:
% ------------------------------------------------
% The data from all experiments should be stored under a single base
% directory. Edit the "TrajTrackerDataPath" function to point to this
% directory. Under this, each experiment is stored in a separate sub-directory. 
% Tou can organize these directories in hierarchical structure if you want -
% e.g., ROOT/dir1/dir2/my_experiment
% An experiment's directory should contain 2 or 3 sub-directories:
% binary - for the matlab MAT files. The present script will save the
%          preprocessed data in binary/session_data.mat, and you can put
%          more stuff here (regression results etc.)
%          When you create this directory, you can keep it empty.
% raw - store here the files (XML and CSV) from the experiment software.
% original - if your data came from old TrajTracker versions (on iPad, software version
%          2.2.0d051 or earlier), you should put your data in this file, and then run
%          the perl script preprocessSet.pl. This script that will pre-process
%          the files and save them in the "raw" sub-directory.

% Copyright (c) 2016 Dror Dotan
% Licensed under the Academic Free License version 3.0
% http://opensource.org/licenses/AFL-3.0

    [subjIDs, customDatasetProcessFunc, loadExpDataArgs, platform] = parseArgs(varargin);

    fprintf('\n========== Pre-processing directory "%s" ========\n\n', subDir);
    
    startTime = now;
    
    %-- Load relevant sessions
    sessions = loadSessions(subDir);
    sessions = filterSessions(sessions, subjIDs);
    if isempty(sessions)
        error('There are no sessions to process');
    end
    
    %-- Validate platforms
    if isempty(platform)
        platform = unique(arrayfun(@(s){s.Platform}, sessions));
        if length(platform) == 1
            platform = platform{1};
        else
            error('The directory contains sessions with multiple platforms, this is invalid');
        end
    end
    
    %-- Group sessions
    sessionPerSubj = groupSessionsBySubject(sessions);
    
    %-- Load
    raw = loadSessionData(sessionPerSubj, loadExpDataArgs, platform);
    tmpFN = [TrajTrackerDataPath '/' subDir '/binary/session_data_unfinished.mat'];
    save(tmpFN, 'raw');
    
    %-- Custom operations
    raw = runCustomProcessFunc(raw, customDatasetProcessFunc); %#ok<NASGU>
    save([TrajTrackerDataPath '/' subDir '/binary/session_data.mat'], 'raw');
    delete(tmpFN);
    
    
    durSec = round((now-startTime)*24*3600);
    durMin = floor(durSec/60);
    
    fprintf('\nDirectory "%s" was pre-processed successfully in %02d:%02d minutes\n', subDir, durMin, durSec-durMin*60);
    
    %-----------------------------------------------------------------
    function sessions = loadSessions(subDir)
        
        dirName = [TrajTrackerDataPath '/' subDir '/raw'];
        files = dir([dirName '/session*.xml']);
        
        if isempty(files)
            error('No sessions*.xml files were found in %s', filePattern);
        end
        
        sessions = [];
        
        for i = 1:size(files,1)
            fn = files(i,1).name;
            if (size(strfind(fn, '.xml'),1) == 0)
                error('Invalid filename (expecting an .xml extension): %s', fn);
            end
            
            session = tt.preprocess.loadSessionFile([dirName '/' fn]);
            sessions = [sessions session]; %#ok<AGROW>
        end
        
        subjIdPerSession = arrayfun(@(s){s.SubjInitials}, sessions);
        [~,i] = sort(subjIdPerSession);
        sessions = sessions(i);
        
    end

    %-----------------------------------------------------------------
    function sessions = filterSessions(sessions, subjIDs)
        
        if ~isempty(subjIDs)
            subjIdPerSession = arrayfun(@(s){s.SubjInitials}, sessions);
            include = arrayfun(@(sid)ismember(sid{1}, subjIDs), subjIdPerSession);
            sessions = sessions(include);
        end
        
    end

    %-------------------------------------------------------------------
    function sessionPerSubj = groupSessionsBySubject(sessions)
        
        subjIdPerSession = arrayfun(@(s){s.SubjInitials}, sessions);
        allSubjIDs = unique(subjIdPerSession);
        
        sessionPerSubj = cell(1, length(allSubjIDs));
        for i = 1:length(allSubjIDs)
            sid = allSubjIDs{i};
            sessionPerSubj{i} = sessions(arrayfun(@(s)strcmp(s{1}, sid), subjIdPerSession));
        end
        
    end

    %-------------------------------------------------------------------
    function data = loadSessionData(sessionPerSubj, loadExpDataArgs, platform)
        
        data = struct;
        
        for iSubj = 1:length(sessionPerSubj)
            subjSessions = sessionPerSubj{iSubj};
            expData = tt.preprocess.loadSessionAsExpData(subjSessions, 'MsgSuffix', sprintf(' (#%d/%d)', iSubj, length(sessionPerSubj)), loadExpDataArgs, 'Platform', platform);
            data.(expData.SubjectInitials) = expData;
        end
        
    end

    %-------------------------------------------------------------------
    function ds = runCustomProcessFunc(ds, customFunc)
        
        if isempty(customFunc)
            return;
        end
        
        fprintf('\nRunning custom operations. Note that if this fails, data will not be saved.\n');
        ds = customFunc(ds);
        
    end
    
    %-------------------------------------------------------------------
    function [subjIDs, customDatasetProcessFunc, loadExpDataArgs, platformOverride] = parseArgs(args)
        
        subjIDs = {};
        customDatasetProcessFunc = [];
        loadExpDataArgs = {};
        platformOverride = '';
        
        args = stripArgs(args);
        
        while ~isempty(args)
            switch(lower(args{1}))
                case {'noavg', 'oldtheta', 'extrapolatedsmoothing', 'stm', 'stimulusthenmove', 'excludeoutliers'}
                    loadExpDataArgs = [loadExpDataArgs args(1)]; %#ok<AGROW>
                    
                case {'processedfunc', 'customcols', 'splinex', 'iepycoord', 'velocitysmoothingsd', 'smoothcoords', 'sumexpcustomattrs', 'avgby'}
                    loadExpDataArgs = [loadExpDataArgs args(1:2)]; %#ok<AGROW>
                    args = args(2:end);
                    
                case 'subjids'
                    subjIDs = arrayfun(@(sid){lower(sid{1})}, args{2});
                    args = args(2:end);
                    
                case 'platform'
                    platformOverride = upper(args{2});
                    args = args(2:end);
                    
                case 'processdsfunc'
                    customDatasetProcessFunc = args{2};
                    args = args(2:end);
                    
                otherwise
                    error('Unknown flag "%s"', args{1});
            end
            
            args = stripArgs(args(2:end));
        end
        
    end

end

