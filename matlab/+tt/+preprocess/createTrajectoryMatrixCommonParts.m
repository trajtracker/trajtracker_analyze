function [trajData,trajSlope] = createTrajectoryMatrixCommonParts(absTimes, x, y, args)
%[trajData,trajSlope] = createTrajectoryMatrixCommonParts(absTimes, x, y, args)
% Create the full trajectory matrix
% This function updates the columns common to all experiment types
% 
% args is a struct with several arguments
    
    if ~isfield(args, 'useOldThetaCalculationMethod')
        args.useOldThetaCalculationMethod = false;
    end
    
    if ~isfield(args, 'coordSmoothingSd')
        args.coordSmoothingSd = .02;
    end
    
    if ~isfield(args, 'velocitySmoothingSd')
        args.velocitySmoothingSd = .02;
    end
    
    if ~isfield(args, 'extrapolateForSmoothing')
        args.extrapolateForSmoothing = false;
    end
    
    samplingRate = getFixedSamplingRate(absTimes);
    
    xRaw = x;
    yRaw = y;
    
    if (args.coordSmoothingSd > 0)
        % Smooth X and Y
        nTP = length(x);
        
        if args.extrapolateForSmoothing
            % Extrapolate the trajectory with some time points
            N_EXTEND_TP = round(3 * args.coordSmoothingSd/samplingRate);
            if nTP > N_EXTEND_TP
                e_dx = (x(end) - x(end-N_EXTEND_TP)) / N_EXTEND_TP;
                e_dy = (y(end) - y(end-N_EXTEND_TP)) / N_EXTEND_TP;
                x = [x; x(end) + e_dx * (1:N_EXTEND_TP)'];
                y = [y; y(end) + e_dy * (1:N_EXTEND_TP)'];
            end
        end
        
        x = smoothg(x, args.coordSmoothingSd/samplingRate, NaN, 'symmetric');
        y = smoothg(y, args.coordSmoothingSd/samplingRate, NaN, 'symmetric');
        
        x = x(1:nTP);
        y = y(1:nTP);
    end
    
    trajData = NaN(length(x), TrajCols.NUM_COLS);

    trajData(:, TrajCols.XRaw) = xRaw;
    trajData(:, TrajCols.YRaw) = yRaw;
    
    trajData(:, TrajCols.AbsTime) = absTimes;

    movementTime = absTimes(end);
    trajData(:, TrajCols.NormTime) = absTimes / movementTime;

    trajData(:, TrajCols.X) = x;
    trajData(:, TrajCols.Y) = y;

    % Translate x,y to r,theta notation
    r = sqrt(x.^2 + y.^2);
    trajData(:, TrajCols.R) = r;
    % globalTheta = atan(x ./ y);
    % trajData(:, TrajCols.GlobalTheta) = globalTheta;

    % Radial velocity / acceleration
    dr = [0; diff(r)];
    trajData(:, TrajCols.RadialVelocity) = dr / samplingRate;
    d2r = [0; diff(dr)];
    trajData(:, TrajCols.RadialAccel) = d2r / (samplingRate ^ 2);

    % Instantaneous X velocity and acceleration
    velocity = [0; diff(smoothg(x, args.velocitySmoothingSd / samplingRate, NaN, 'symmetric')) / samplingRate];
    trajData(:, TrajCols.XVelocity) = velocity;
    trajData(:, TrajCols.XAcceleration) = [0; diff(smoothg(velocity, args.velocitySmoothingSd / samplingRate)) / samplingRate];

    % Instantaneous Y velocity and acceleration
    velocity = [0; diff(smoothg(y, args.velocitySmoothingSd / samplingRate, NaN, 'symmetric')) / samplingRate];
    trajData(:, TrajCols.YVelocity) = velocity;
    trajData(:, TrajCols.YAcceleration) = [0; diff(smoothg(velocity, args.velocitySmoothingSd / samplingRate)) / samplingRate];

    % Angular direction and its change
    [instTheta, trajSlope] = calculateInstantaneousTheta(x, y);
    trajData(:, TrajCols.Theta) = instTheta;
    trajData(:, TrajCols.AngularVelocity) = [0; diff(smoothg(instTheta, args.coordSmoothingSd/samplingRate)) / samplingRate];
    
    %------------------------------------------------------------------
    function t = getFixedSamplingRate(times)
        deltaT = diff(times);
        if (sum(abs(diff(deltaT))) > 0.0001)
            error('The sampling rate is not fixed!');
        end
        t = deltaT(1);
    end

    %------------------------------------------------------------------
    function instVelocity = calculateInstantaneousVelocity_OLD(x,y,normalizedTimes)

        highRateTimes = (-0.01:0.0005:1.01)';
        highRateX = spline(normalizedTimes, x, highRateTimes);
        highRateY = spline(normalizedTimes, y, highRateTimes);

        instVelocity = zeros(length(normalizedTimes), 1);

        for i = 1:length(normalizedTimes)
            nowTime = normalizedTimes(i);
            timesAroundNow = highRateTimes - nowTime;

            % Get the index of largest number which is smaller than 'normTime'
            beforeCurrTimeInd = find(timesAroundNow < 0, 1, 'last');
            afterCurrTimeInd = find(timesAroundNow > 0, 1, 'first');

            dx = highRateX(afterCurrTimeInd) - highRateX(beforeCurrTimeInd);
            dy = highRateY(afterCurrTimeInd) - highRateY(beforeCurrTimeInd);
            distance = sqrt(dx^2 + dy^2);
            deltaT = highRateTimes(afterCurrTimeInd) - highRateTimes(beforeCurrTimeInd);

            instVelocity(i,1) = distance/deltaT;

        end

    end

    %------------------------------------------------------------------
    function [theta,slope] = calculateInstantaneousTheta(x, y)

        if (args.useOldThetaCalculationMethod)
            % Use old method for theta-calculation:
            % Find differences in the X and Y axes vs. the finger position
            % as it was few samples ago 
            NSAMPLES_50_MSEC = 5;
            x1 = x(1:end-NSAMPLES_50_MSEC);
            x2 = x(NSAMPLES_50_MSEC+1:end);
            dx = x2 - x1;

            y1 = y(1:end-NSAMPLES_50_MSEC);
            y2 = y(NSAMPLES_50_MSEC+1:end);
            dy = y2 - y1;
            
        else
            % Find differences in the X and Y axes vs. the finger position
            % as it was few samples ago 
            dx = diff(x);
            dy = diff(y);
        end
        
        % Calculate angle of movement (here it's in slope format)
        slope = dx ./ dy;
%        distancePerSlot = sqrt(dx.^2 + dy.^2);
%        slope(logical(distancePerSlot < 0.005)) = NaN;  % cancel slots with very slow finger movement
        
        % When speed is 0 or slow, use last-known-good slope
        badInds = find(isnan(slope) | dy < 0.0002)';
        if (~isempty(badInds) && badInds(1) == 1)
            slope(1) = 0;
            badInds = badInds(2:end);
        end
        for ind = badInds
            slope(ind) = slope(ind-1);
        end
    
        % Fill zeros where info is N/A
        if (args.useOldThetaCalculationMethod) 
            theta = [zeros(NSAMPLES_50_MSEC,1); atan(slope)];
            slope = [zeros(NSAMPLES_50_MSEC,1); slope];
        else
            theta = [0; atan(slope)];
            slope = [0; slope];
        end
        
    end

end
