function velInfo = getTrialVelocity(trial, varargin)
%velInfo = getTrialVelocity(trial, ...) - get the trial velocity
%(smoothed)
% This is used by various velocity functions.
% 
% Optional args:
% Acc - also calculate acceleration
% Axis X|Y - which velocity to get
% Smooth Gauss <sd> - Use Gaussian smoothing
% Smooth Conv <conv-vector> - Use convolution smoothing

    [xCol, velXY, showAcc, smoothFunc] = parseArgs(varargin);
    
    samplingRate = diff(trial.Trajectory(1:2, TrajCols.AbsTime));
    
    if velXY
        % Instantaneous velocity - in whatever direction
        x = smoothFunc(trial.Trajectory(:, TrajCols.X));
        y = smoothFunc(trial.Trajectory(:, TrajCols.Y));
        velocity = sqrt(diff(x) .^ 2 + diff(y) .^ 2) / samplingRate;
    else
        coords = smoothFunc(trial.Trajectory(:, xCol));
        velocity = diff(coords) / samplingRate;
    end

    velInfo = struct;
    
    velInfo.velocity = [0; velocity];
    velInfo.times = trial.Trajectory(:, TrajCols.AbsTime);
    
    if (showAcc)
        velocity = smoothFunc(velocity);
        velInfo.acceleration = [0; 0; diff(velocity)] / samplingRate;
    end

    %----------------------------------------------------------
    function x = smoothConv(x, convVector)
        x = conv(x, convVector, 'valid');
        filler = repmat(x(1), length(convVector)-1, 1);
        x = [filler; x];
    end

    %----------------------------------------------------------
    function [xCol, velXY, showAcc, smoothFunc] = parseArgs(args)
        
        showAcc = false;
        xCol = TrajCols.X;
        velXY = false;
        smoothFunc = @(x)x;
        
        args = stripArgs(args);
        while ~isempty(args)
            
            switch(lower(args{1}))
                case 'acc'
                    showAcc = true;
                    
                case 'axis'
                    switch(lower(args{2}))
                        case 'x'
                            xCol = TrajCols.X;
                        case 'y'
                            xCol = TrajCols.Y;
                        case 'xy'
                            velXY = true;
                            xCol = [];
                        otherwise
                            error('Invalid axis "%s"', args{2});
                    end
                    args = args(2:end);
                    
                case 'smooth'
                    smoothMethod = args{2};
                    switch(lower(smoothMethod))
                        case 'conv'
                            convVector = args{3};
                            args = args(2:end);
                            convVector = convVector / sum(convVector);
                            smoothFunc = @(x)smoothConv(x, convVector); 
                            
                        case 'gauss'
                            stDev = args{3};
                            args = args(2:end);
                            dt = diff(trial.Trajectory(1:2, TrajCols.AbsTime));
                            if (stDev > 0)
                                smoothFunc = @(x)smoothg(x, stDev / dt);
                            end
                            
                        otherwise
                            error('Invalid smoothing method "%s"', smoothMethod);
                    end
                    args = args(2:end);
                    
                otherwise
                    error('Unsupported argument "%s"', args{1});
            end
            
            args = stripArgs(args(2:end));
        end
        
    end
    
end

