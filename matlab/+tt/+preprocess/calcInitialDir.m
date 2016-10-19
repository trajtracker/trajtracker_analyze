function calcInitialDir(expData, trialSet, varargin)
%calcInitialDir(expData, trialsToUpdate, ...)
% Per trial, update the direction vector which best fits the initial part of a
% trajectory.
% The "initial part" is defined as the bottom 20% of the trajectory
% 
% trialsToUpdate: trials or averages
% 
% Optional args:
% Flags: "v" is verbose mode

    verboseMode = ~isempty(varargin) && strcmp(varargin{1}, 'v');
    
    switch(expData.ExperimentPlatform)
        case 'NL'
            maxValidInitialXByYSlope = NaN;
        case 'DC'
            maxValidInitialXByYSlope = 0.2;
        otherwise
            error('Platform %s not supported', expData.ExperimentPlatform);
    end

    switch(trialSet)
        case 'trials'
            for trial = expData.Trials
                updateTrial(trial, maxValidInitialXByYSlope);
            end
            
        case 'averages'
            for trial = expData.AvgTrialsNorm
                updateTrial(trial, maxValidInitialXByYSlope);
            end
            for trial = expData.AvgTrialsAbs
                updateTrial(trial, maxValidInitialXByYSlope);
            end
            
        otherwise
            error('Invalid "trialsToUpdate"');
    end
    
    %---------------------------------------------------------------------------
    function updateTrial(trial, maxValidInitialXByYSlope)
        
        if (size(trial.Trajectory, 1) == 0)
            % No trajectory - probably an invalid error code
            trial.InitialDirectionTheta = 0;
            trial.InitialDirectionX0 = 0;
            return;
        end
        
        % n = find(trial.Trajectory(:,TrajCols.Y) >= 0.2, 1);
        n = find(trial.Trajectory(:,TrajCols.AbsTime) >= 0.15, 1);
        if isempty(n)
            trial.InitialDirectionTheta = 0;
            trial.InitialDirectionX0 = 0;
            return;
        end
        
        x = trial.Trajectory(1:n,TrajCols.X);
        if (isConstant(x))
            if (verboseMode) 
                fprintf('      Trial #%d (target=%d): constant X\n', trial.TrialNum, trial.Target);
            end
            p = 0;
            theta = 0;
            x0 = trial.Trajectory(1,TrajCols.X);
            x_by_y_slope = 0;
        else
            if (verboseMode) 
                fprintf('      Trial #%d (target=%d): calculate using regression\n', trial.TrialNum, trial.Target);
            end
            y = trial.Trajectory(1:n,TrajCols.Y);
            
            [p, x0, x_by_y_slope] = getDirection(x, y);
            if (p > 0.05) 
                % Maybe there is a curve; try regressing with less points
                old_p = p;
                n = floor(n*.6);
                x = trial.Trajectory(1:n,TrajCols.X);
                y = trial.Trajectory(1:n,TrajCols.Y);
                [p, x0, x_by_y_slope] = getDirection(x, y);
                if (p > 0.05) 
                    fprintf('      Warning: bad reliability (p=%f) for trajectory initial direction of trial #%d\n', p, trial.TrialNum);
                elseif (verboseMode)
                    fprintf('      Used regression with fewer points due to bad reliability (p=%f) of first regression. New p=%f\n', old_p, p);
                end
            end
            
            if (~isnan(maxValidInitialXByYSlope))
                x_by_y_slope = min(x_by_y_slope, maxValidInitialXByYSlope);
            end
            theta = atan(x_by_y_slope);
        end
        
        trial.InitialDirectionTheta = theta;
        trial.InitialDirectionX0 = x0;
        
        updateCleanX(trial, x0, x_by_y_slope);
        if ~isempty(trial.NormalizedTrajectory)
            updateCleanXNorm(trial, x0, x_by_y_slope);
        end
        
        if (verboseMode)
            fprintf('      x0=%f, slope=%f, p=%f\n', x0, x_by_y_slope, p);
        end
        
    end
    
    
    %---------------------------------------------------------------------------
    function c = isConstant(x)
        deviationFromMean = abs(x-mean(x));
        c = mean(deviationFromMean) < 0.001;
    end

    %---------------------------------------------------------------------------
    % Get the direction vector which best fits the given x/y data.
    % We assume that the vector is nearly vertical, so we regress x by y and
    % not vice versa.
    %
    % Input: the x and y values on which the calculation should be based
    %
    % Returns:
    % theta   : the angle
    % dy_dx   : the slope of the direction vector (dy/dx)
    % x0      : the origin of the direction vector
    % p       : the regression p value
    %
    function [p, x0, x_by_y_slope] = getDirection(x, y)

        if (size(x,2) ~= 1 || size(y,2) ~= 1)
            error('Illegal arguments - x and y should be single columns, but ncols of x=%d, y=%d', size(x,2), size(y,2));
        end

        % In this regression y is the predictor and x is the dependent
        stats = regstats(x, y, 'linear');

        p = stats.fstat.pval;
        x0 = stats.beta(1);
        x_by_y_slope = stats.beta(2);

    end

    function updateCleanX(trial, x0, x_by_y_slope)
        trialX = trial.Trajectory(:, TrajCols.X);
        trialY = trial.Trajectory(:, TrajCols.Y);
        deviations = trialY .* x_by_y_slope + x0;
        trial.Trajectory(:,TrajCols.XClean) = trialX - deviations;
    end

    function updateCleanXNorm(trial, x0, x_by_y_slope)
        trialX = trial.NormalizedTrajectory(:, TrajCols.X);
        trialY = trial.NormalizedTrajectory(:, TrajCols.Y);
        deviations = trialY .* x_by_y_slope + x0;
        trial.NormalizedTrajectory(:,TrajCols.XClean) = trialX - deviations;
    end
end
