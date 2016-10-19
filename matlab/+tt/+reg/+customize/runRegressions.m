function rr = runRegressions(allExpData, varargin)
%rr = runRegressions(allExpData) - run regressions for all subjects.
% 
% Copy this function to your own folder and customize it.
% Note all places with a "CUSTOM" comment

    [outFN, runAllRegressions, regArgs] = parseArgs(varargin);

    if isfield(allExpData, 'raw') 
        allED = allExpData.d; 
    else
        allED = allExpData;
    end;
    
    %CUSTOM: If this is a number-line experiment, change 1st argument to 'NL'
    rr = treg.createEmptyRR('DC', allED.general.setName);
    
    for subject = tt.inf.listInitials(allED)
        rr.(subject{1}) = runForOneSubj(allED.(subject{1}), regArgs);
    end
    
    rr.avg = treg.averageRegressionResults(rr);
    
    if ~isempty(outFN)
        outDirName = [TrajTrackerDataPath '/' allED.general.setName '/binary/', outFN];
        save(outDirName, 'rr');
    end
    
    %------------------------------------------------------------------------
    function result = runForOneSubj(expData, regArgs)
        
        result = struct;
        result.SubjectName = expData.SubjectName;
        result.SubjectInitials = expData.SubjectInitials;
        result.SamplingRate = expData.SamplingRate;
        result.ExcludeFromAverage = expData.ExcludeFromAverage;
        result.TimeExecuted = datestr(now);
        result.MaxMovementTime = max(arrayfun(@(t)t.MovementTime, expData.Trials));
        
        %CUSTOM: change all lines below according to your regressions
        
        result.MyRegResults1 = tt.reg.regress(expData, 'reg', 'DEP_VAR', {'PRED1', 'PRED2'}, regArgs);
        result.MyRegResults2 = tt.reg.regress(expData, 'reg', 'DEP_VAR', {'PRED1', 'MyPrivatePredictor'}, regArgs, 'FMeasureFunc', @tt.reg.customize.getMyTrialMeasures);
        
        if runAllRegressions
            result.MyRegResults3 = tt.reg.regress(expData, 'reg', 'DEP_VAR', {'PRED1', 'PRED4'}, regArgs);
        end
        
    end

    %-------------------------------------------
    function [outFN, runAllRegressions, regArgs] = parseArgs(args)

        outFN = 'default_filename.mat'; %CUSTOM
        runAllRegressions = true;
        regArgs = {};
        
        args = stripArgs(args);
        while ~isempty(args)
            switch(lower(args{1}))
                case 'nosave'
                    outFN = '';

                case 'saveas'
                    outFN = args{2};
                    args = args(2:end);
                    
                case 'basic'
                    runAllRegressions = false;

                case 'regargs'
                    regArgs = args{2};
                    args = args(2:end);
                    
                otherwise
                    error('Unsupported argument "%s"!', args{1});
            end
            args = stripArgs(args(2:end));
        end

    end

end

