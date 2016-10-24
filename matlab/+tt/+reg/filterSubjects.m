function rr = filterSubjects(oldrr, varargin)
% rr = filterSubjects(rr, ...) - Get RR with only some subjects
% 
% rr: struct with regression results per subject.
% 
% Arguments:
% Include/Exclude <cell-array>: include only the given list of subject IDs,
%                     or exclude just them
% SaveToDir <dataset-subdir> <filename>: Save file to the given directory

    [exclude, saveFN, subjIDs] = parseArgs(varargin);
    
    rr = getStructFields(oldrr, subjIDs, exclude);
    rr.avg = tt.reg.averageRegressionResults(rr);
    rr.general = oldrr.general;
    
    if ~isempty(saveFN)
        save(saveFN, 'rr');
    end
    
    %-------------------------------------------
    function [subjIDs, exclude, saveFN] = parseArgs(args)

        subjIDs = {};
        exclude = '';
        saveFN = '';
        
        args = stripArgs(args);
        while ~isempty(args)
            switch(lower(args{1}))
                case 'exclude'
                    exclude = 'exclude';
                    subjIDs = args{2};
                    args = args(2:end);
                    
                case 'include'
                    exclude = 'include';
                    subjIDs = args{2};
                    args = args(2:end);
                    
                case 'savetodir'
                    subDir = args{2};
                    fn = args{3};
                    args = args(3:end);
                    saveFN = [TrajTrackerDataPath '/' subDir '/binary/' fn];

                otherwise
                    error('Unsupported argument "%s"!', args{1});
            end
            args = stripArgs(args(2:end));
        end

        if isempty(exclude)
            error('Please specify either "Include" or "Exclude"');
        end
        
    end

end

