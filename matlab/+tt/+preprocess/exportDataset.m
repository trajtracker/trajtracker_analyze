function exportDataset(dataset, outDir, varargin)
% exportDataset(dataset, outDir) - Export subjects to a given directory, in
% a format (almost) identical with the input format in the "raw" directory
% 
% For each subject, we export a trials.csv file, trajectory.csv file, and
% one session.xml file for each session (usually one, but may be more if
% data is a merge of several sessions)
% 
% Optional arguments:
% RawCoords: export the unsmoothed x,y coordinates in the trajectory file
%            (they will still be splined to a fixed sampling rate).
% CustomAttrs <cell array>: export these custom attributes, each as a
%             column in the trials.csv file.

    [customAttrNames, xCol, yCol] = parseArgs(varargin);
    
    [srcSessionFileNames, inDir] = getSourceFilenames(dataset);
    
    if ~exist(outDir, 'dir')
        mkdir(outDir);
    end
    
    for expData = tt.util.structToArray(dataset.raw)
        fprintf('Exporting %s...\n', upper(expData.SubjectInitials));
        process(expData, srcSessionFileNames.(expData.SubjectInitials), inDir, outDir);
    end
    
    
    %---------------------------------------------------------------
    function [sessionFilenames, inDir] = getSourceFilenames(dataset)
        
        inDir = [TrajTrackerDataPath '/' dataset.raw.general.setName '/raw'];
        if ~exist(inDir, 'dir')
            fprintf('WARNING: Source directory of this dataset was not found, so only trajectory data will be exported\n');
            sessionFilenames = [];
            return;
        end
        
        sessionFilenames = struct;
        
        files = dir([inDir '/session*.xml']);
        for file = files'
            sessionInf = tt.preprocess.loadSessionFile([inDir '/' file.name]);
            if ~isfield(dataset.raw, sessionInf.SubjInitials)
                error('File %s contains data for subject %s, but this subject was not found in the dataset', file.name, upper(sessionInf.SubjInitials));
            end
            if ~isfield(sessionFilenames, sessionInf.SubjInitials)
                sessionFilenames.(sessionInf.SubjInitials) = {};
            end
            sessionFilenames.(sessionInf.SubjInitials) = [sessionFilenames.(sessionInf.SubjInitials) {file.name}];
        end
        
    end

    %---------------------------------------------------------------
    function process(expData, srcSessionFileNames, inDir, outDir)

        oneSession = length(srcSessionFileNames) == 1;
        for i = 1:length(srcSessionFileNames)
            suffix = iif(oneSession, '', sprintf('_%d', i));
            copyfile([inDir '/' srcSessionFileNames{i}], sprintf('%s/session_inf_%s%s.xml', outDir, expData.SubjectInitials, suffix));
        end
        
        exportTrialsFile(expData, outDir);
        exportTrajectoryFile(expData, outDir);
        
    end

    %---------------------------------------------------------------
    function exportTrialsFile(expData, outDir)
        
        errCodes = TrialErrCodes.getAllErrCodes();
        
        fp = fopen(sprintf('%s/trials_%s.csv', outDir, expData.SubjectInitials), 'w');
        fprintf(fp, 'subSession,trialNum,status,target,presentedTarget,movementTime,timeInSession,timeUntilFingerMoved,timeUntilTarget');
        if ~isempty(customAttrNames)
            fprintf(fp, ',%s', join(',', customAttrNames));
        end
        fprintf(fp, '\n');
        
        for trial = expData.Trials
            if isfield(trial.Custom, 'PresentedTarget')
                presentedTarget = toStr(trial.Target);
            else
                presentedTarget = trial.Custom.PresentedTarget;
            end
            
            errKey = sprintf('e%d', trial.ErrCode);
            status = iif(isfield(errCodes, errKey), errCodes.(errKey), sprintf('Err#%d', trial.ErrCode));
            
            fprintf(fp, '%d,%d,%s,%s,%s,%.3f,%.3f,%.3f,%.3f,%.3f', ...
                trial.SubSession, trial.TrialNum, status, toStr(trial.Target), presentedTarget, trial.MovementTime,...
                trial.TimeInSubSession, trial.TimeUntilFingerMoved, trial.TimeUntilTargetShown);
            for attr = customAttrNames
                fprintf(fp, ',%s', toStr(trial.Custom.(attr{1})));
            end
            fprintf(fp, '\n');
        end
        
        fclose(fp);
    end

    %---------------------------------------------------------------
    function value = toStr(value)
        if isinteger(value)
            value = sprintf('%d', value);
        elseif isnumeric(value)
            value = sprintf('%f', value);
        else
            value = char(value);
        end
    end

    %---------------------------------------------------------------
    function exportTrajectoryFile(expData, outDir)
        
        fp = fopen(sprintf('%s/trajectory_%s.csv', outDir, expData.SubjectInitials), 'w');
        fprintf(fp, 'TrialNum,Time,x,y\n');
        
        for trial = expData.Trials
            
            for iRow = 1:size(trial.Trajectory, 1)
                fprintf(fp, '%d,%.2f,%.6f,%.6f\n', trial.TrialNum, ...
                    trial.Trajectory(iRow, TrajCols.AbsTime), ...
                    trial.Trajectory(iRow, xCol), ...
                    trial.Trajectory(iRow, yCol));
            end
            
        end
        
        fclose(fp);
    end

    %---------------------------------------------------------------
    function [customAttrNames, xCol, yCol] = parseArgs(args)

        xCol = Trajcols.X;
        yCol = TrajCols.Y;
        customAttrNames = {};
        
        args = stripArgs(args);
        while ~isempty(args)
            switch(lower(args{1}))
                case 'customattrs'
                    customAttrNames = args{2};
                    args = args(2:end);
                    if ~iscell(customAttrNames)
                        error('Flag "CustomAttrs" should be followed by a cell array of custom attribute names');
                    end
                    
                case 'rawcoords'
                    xCol = Trajcols.XRaw;
                    yCol = TrajCols.YRaw;

                otherwise
                    error('Unsupported argument "%s"!', args{1});
            end
            args = stripArgs(args(2:end));
        end

    end

end

