function encodeVelocityOnsetManually(allExpData, trialFilter, outFN, varargin)
%encodeVelocityOnsetManually(allExpData, trialFilter, outFN, (optional-args), (plot-func-args)) -
% Manually review all trials defined by the filter, and set the x velocity 
% onset of these trials.
% 
% Optional arguments:
% StartAtTrial #: Start working on this trial number.
%            The numbers are over all conditions and subjects. You can see
%            the current trial number by clicking "P" during work. This
%            feature is useful if you want to continue your work later (but
%            make sure not to override the file with the work you've
%            already done!)
% 
% plot-func-args: Arguments that will be transferred to the
%            velocity-plotting func (<a href="matlab:help nl.vel.plotVelocityOnset">nl.vel.plotVelocityOnset</a>)

    if isstruct(allExpData)
        allExpData = {allExpData};
    end
    
    [plotFuncArgs, startAtTrial, subjIDs] = parseArgs(varargin);
    if isempty(subjIDs)
        subjIDs = tt.inf.listInitials(allExpData{1});
    end
    
    totalNTrials = sum(arrayfun(@(allED)sum(arrayfun(@(expData)sum(arrayfun(trialFilter, expData.Trials)), tt.util.structToArray(allED{1}))), allExpData));
    fprintf('Reviewing %d trials...\n', totalNTrials);
    
    if (startAtTrial > 0)
        validateNoManualEncoding(allExpData);
    end
    
    if exist(outFN, 'file')
        askUser = 1;
        while(askUser)
            userAns = input('The output file already exists. Override (y/n)? ', 's');
            if strcmpi(userAns, 'y')
                delete(outFN);
                askUser = 0;
            elseif strcmpi(userAns, 'n')
                disp('Terminating.');
                return;
            end
        end
    end
    
    iCond = 0;
    iSubj = 0;
    currSubjNTrials = 0;
    
    startTime = clock();
    nTrialsProcessed = 0;
    
    disp('>>>>> Working in interactive mode:');
    disp('Use the mouse to determine the onset; use the keyboard to accept/reject:');
    disp('a: Accept onset selection, mark as a valid trial');
    disp('w: Accept onset selection, mark as a wrong-direction trial');
    disp('c: Accept onset selection, mark as a change-of-mind trial');
    disp('x: No onset for this trial');
    disp('p: Print progress');
    disp('space: Skip trial');    
    
    % Start!
    gotoNextCond();
    
    
    %-------------------------------------------
    function gotoNextCond()
        iCond = iCond + 1;
        if (iCond > length(allExpData))
            disp('Finished!!!');
            clf;
            return;
        end
        
        iSubj = 0;
        gotoNextSubj();
        
    end
    
    %-------------------------------------------
    function gotoNextSubj()
        
        nTrialsProcessed = nTrialsProcessed + currSubjNTrials;
        
        iSubj = iSubj + 1;
        if (iSubj > length(subjIDs))
            % Finished this condition
            gotoNextCond();
            return;
        end
        
        subjID = subjIDs{iSubj};
        expData = allExpData{iCond}.(subjID);
        
        fprintf('Reviewing cond %d, subject %s (%d/%d trials)\n', iCond, upper(subjID), sum(arrayfun(trialFilter, expData.Trials)), length(expData.Trials));
        
        currSubjNTrials = sum(arrayfun(trialFilter, expData.Trials));
        
        if (startAtTrial > nTrialsProcessed + currSubjNTrials)
            fprintf('   Skipping this subject\n');
            gotoNextSubj();
            return;
        end
        
        innerFuncArgs = plotFuncArgs;
        if (startAtTrial > 0)
            innerFuncArgs = [innerFuncArgs {'StartAtTrial', startAtTrial-nTrialsProcessed}];
        end
        
        if isa(expData, 'NLExperimentData')
            innerFuncArgs = [innerFuncArgs {'Thrsh1Side'}];
        end
        
        nl.vel.plotVelocityProfile(expData, 'Condition', sprintf('cond%d', iCond), 'TrialFilter', trialFilter, ...
            'CustomOutFile', outFN, 'OnFinished', @gotoNextSubj, 'OnKey', @onKeyHit, 'Interactive', 'HideTarget', innerFuncArgs);
        
    end

    %-------------------------------------------
    function onKeyHit(key, nTrials)
        if strcmpi(key, 'p')
            duration = round(etime(clock(), startTime));
            fprintf('You have been working for %d seconds and you finished %d/%d trials\n', duration, nTrialsProcessed+nTrials, totalNTrials);
        end
    end

    %-------------------------------------------
    function validateNoManualEncoding(allExpData)
        
        for i = 1:length(allExpData)
            for ed = tt.util.structToArray(allExpData{i})
                if (sum(arrayfun(@(t)~strcmp(t.Custom.XVelocityOnsetEncoder, 'auto'), ed.Trials)) > 0)
                    error('You used the "StartAtTrial" flag, but some trials have manual encoding of velocity onset. This is invalid.');
                end
            end
        end
        
    end

    %-------------------------------------------
    function [plotFuncArgs, startAtTrial, subjIDs] = parseArgs(args)
        
        startAtTrial = 0;
        subjIDs = {};
        
        args = stripArgs(args);
        
        while ~isempty(args)
            switch(lower(args{1}))
                case 'startattrial'
                    startAtTrial = args{2};
                    args = args(2:end);
                    
                case 'subjids'
                    subjIDs = args{2};
                    args = args(2:end);
                    
                otherwise
                    % Reached inner-func args: stop processing
                    break;
            end
            args = stripArgs(args(2:end));
        end
        
        plotFuncArgs = args;
    end

end

