function velInfo = getTrialVelocity(trial, varargin)
%velInfo = getTrialVelocity(trial, ...) - get the trial velocity
%(smoothed)
% This is used by various velocity functions.
% 
% Optional args:
% Acc - also calculate acceleration
% Axis X|Y|iep - which velocity to get
% CSmooth <args> - Smooth coordinates before deriving them into velocity
% VSmooth <args> - Smooth velocity before deriving it into acceleration
%        The smoothing arguments are either of:
%        Gauss <sd> - Gaussian smoothing, specify standard deviation
%        Conv <conv-vector> - Convolution with the given vector

    [xCol, velXY, showAcc, coordSmoothFunc, velSmoothFunc] = parseArgs(varargin);
    
    samplingRate = diff(trial.Trajectory(1:2, TrajCols.AbsTime));
    
    if velXY
        % Instantaneous velocity - in whatever direction
        x = coordSmoothFunc(trial.Trajectory(:, TrajCols.X));
        y = coordSmoothFunc(trial.Trajectory(:, TrajCols.Y));
        velocity = sqrt(diff(x) .^ 2 + diff(y) .^ 2) / samplingRate;
    else
        coords = coordSmoothFunc(trial.Trajectory(:, xCol));
        velocity = diff(coords) / samplingRate;
    end

    velInfo = struct;
    
    velInfo.velocity = [0; velocity];
    velInfo.times = trial.Trajectory(:, TrajCols.AbsTime);
    
    if (showAcc)
        velocity = velSmoothFunc(velocity);
        velInfo.acceleration = [0; 0; diff(velocity)] / samplingRate;
    end

    %----------------------------------------------------------
    function x = smoothConv(x, convVector)
        x = conv(x, convVector, 'valid');
        filler = repmat(x(1), length(convVector)-1, 1);
        x = [filler; x];
    end

    %----------------------------------------------------------
    function [xCol, velXY, showAcc, coordSmoothFunc, velSmoothFunc] = parseArgs(args)
        
        showAcc = false;
        xCol = TrajCols.X;
        velXY = false;
        coordSmoothFunc = @(x)x;
        velSmoothFunc = @(x)x;
        
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
                        case 'iep'
                            xCol = TrajCols.ImpliedEP;
                        case 'xy'
                            velXY = true;
                            xCol = [];
                        otherwise
                            error('Invalid axis "%s"', args{2});
                    end
                    args = args(2:end);
                    
                case 'csmooth'
                    smoothMethod = args{2};
                    switch(lower(smoothMethod))
                        case 'conv'
                            convVector = args{3};
                            args = args(2:end);
                            convVector = convVector / sum(convVector);
                            coordSmoothFunc = @(x)smoothConv(x, convVector); 
                            
                        case 'gauss'
                            stDev = args{3};
                            args = args(2:end);
                            dt = diff(trial.Trajectory(1:2, TrajCols.AbsTime));
                            if (stDev > 0)
                                coordSmoothFunc = @(x)smoothg(x, stDev / dt);
                            end
                            
                        otherwise
                            error('Invalid smoothing method "%s"', smoothMethod);
                    end
                    args = args(2:end);
                    
                case 'vsmooth'
                    smoothMethod = args{2};
                    switch(lower(smoothMethod))
                        case 'conv'
                            convVector = args{3};
                            args = args(2:end);
                            convVector = convVector / sum(convVector);
                            velSmoothFunc = @(x)smoothConv(x, convVector); 
                            
                        case 'gauss'
                            stDev = args{3};
                            args = args(2:end);
                            dt = diff(trial.Trajectory(1:2, TrajCols.AbsTime));
                            if (stDev > 0)
                                velSmoothFunc = @(x)smoothg(x, stDev / dt);
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

