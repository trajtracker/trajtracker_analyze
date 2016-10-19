function subjData = loadSubjects(subDir, varargin)
% subjData = loadSubjects(dirName, ...) - load a dataset with experiments of
% multiple subjects.
%
% dirName: A sub-directory under the base data path (which is specified by
%          the "TrajTrackerDataPath" function)

% Copyright (c) 2016 Dror Dotan
% Licensed under the Academic Free License version 3.0
% http://opensource.org/licenses/AFL-3.0

    [condName] = parseArgs(varargin);
    
    fprintf('Loading data from %s...\n', subDir);
    
    fn = [TrajTrackerDataPath '/' subDir '/binary/session_data.mat'];
    loadedData = load(fn);
    
    subjData = prepareLoadedExpData(loadedData, subDir, condName);


    %--------------------------------------------------------------------
    function subjData = prepareLoadedExpData(loadedData, subDir, condName)

        loadedDataArray = tt.util.structToArray(loadedData.raw);
        platform = loadedDataArray(1).ExperimentPlatform;

        raw = struct();
        d = struct();

        for expData = loadedDataArray
            expData.Group = subDir;
            if isempty(expData.Custom)
                expData.Custom = struct; % Backward compatibility
            end
            raw.(expData.SubjectInitials) = expData;
            d.(expData.SubjectInitials) = expData.ExpDataWithOKTrials;
        end

        if (~ isempty(loadedDataArray(1).AvgTrialsAbs)) % TODO: this condition would later be removed
            switch(platform)
                case 'NL'
                    raw.avg = tt.preprocess.createAvgExpData(raw);
                case 'DC'
                    % No average trials
                otherwise
                    error('Unsupported platform: %s', platform);
            end
        end

        raw.all = tt.preprocess.createExpDataAll(tt.util.structToArray(raw));
        d.all = tt.preprocess.createExpDataAll(tt.util.structToArray(d));

        raw.general = struct('setName', subDir, 'ConsidersOutliers', 0, 'CondName', condName);
        if strcmp(platform, 'NL')
            raw.general.MaxTarget = raw.all.MaxTarget;
        end
        d.general = raw.general;

        subjData = struct('raw', raw', 'd', d);

    end

    
    %-----------------------------------------
    function [condName] = parseArgs(args)

        condName = '';

        args = stripArgs(args);
        while ~isempty(args)
            switch(lower(args{1}))
                case 'condname'
                    condName = args{2};
                    args = args(2:end);

                otherwise
                    error('Invalid argument: %s', args{1});
            end
            args = stripArgs(args(2:end));
        end

    end

end
