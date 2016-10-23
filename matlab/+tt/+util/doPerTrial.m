function doPerTrial(allExpData, funcToApply, varargin)
%doPerTrial(allExpData, func, ...) - apply a certain function per trial
%
% func: @(trial,ExpData) with no return value
% 
% Optional arguments:
% Trials <Trials / AvgAbs / AvgNorm>
% Silent - disable prints

    [trialSet, verbose] = parseArgs(varargin);
    
    if isa(allExpData, 'ExperimentData')
        
        process(allExpData);
        
    elseif isstruct(allExpData)
        
        for i = tt.inf.listInitials(allExpData)
            process(allExpData.(i{1}));
        end
        
    else
        
        error('Invalid input');
        
    end
    
    %-----------------------------------------------------
    function process(expData)
        
        if verbose
            fprintf('Processing %s...\n', expData.SubjectInitials);
        end
        
        switch(lower(trialSet))
            case 'trials'
                prop = 'Trials';
                
            case 'avgabs'
                prop = 'AvgTrialsAbs';
                
            case 'avgnorm'
                prop = 'AvgTrialsNorm';
                
            otherwise
                error('Unsupported trial set "%s"', trialSet);
        end
        
        for trial = expData.(prop)
            funcToApply(trial, expData);
        end
        
    end

    %-------------------------------------------------------------------
    function [trialSet, verbose] = parseArgs(args)
        
        verbose = true;
        trialSet = 'trials';
        
        args = stripArgs(args);
        
        % Support older API
        if ~isempty(args) && strcmpi(args{1}, 'trials')
            args = args(2:end);
        end
        
        while ~isempty(args)
            switch(lower(args{1}))
                case 'trials'
                    trialSet = args{2};
                    args = args(2:end);
                    
                case 'silent'
                    verbose = false;
                    
                otherwise
                    error('Unsupported argument "%s"', args{1});
            end
            args = stripArgs(args(2:end));
        end
        
    end


end

