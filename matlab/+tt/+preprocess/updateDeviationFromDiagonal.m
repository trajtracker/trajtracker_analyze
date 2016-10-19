function updateDeviationFromDiagonal(trials, expData)
% updateDeviationFromDiagonal(trials) -
% Update the maximal deviation from a straight line to response (per trial)
%
% The deviation is calculated using two different methods: area between
% actual trajectory and the "ideal" (straight) trajectory, or the maximal
% distance between the two.
%
% Deviation values are reversed when correct-response = left, so that
% larger deviation values always indicate more deviation towards the
% incorrect response.
%

    N_PIXELS_BELOW_RESPONSE = 30;
    
    % All deviations are calculated only until the a MAX_Y virtual line
    % because trajectories of different trials may end in different Y
    % coordinates.
    % The MAX_Y is set to be a little below the response buttons
    % (trajectories may end lower than the button due to smoothing and cropping)
    yCoordForBottomOfResponseButtons = (expData.Custom.TrajZeroCoordY - getResponseButtonHeight() - N_PIXELS_BELOW_RESPONSE) / expData.logicalScaleToPixelsFactor();
    
    starightTrajToResponse = {createStraightTrajectoryTo(-1), createStraightTrajectoryTo(1)};

    for trial = trials
        
        if isempty(trial.UserResponse)
            continue;
        end
        
        straightTrajectory = starightTrajToResponse{trial.UserResponse+1};
        
        [actualX,actualY] = getTrialXY(trial);
        
        trial.DeviationDistance = maxXDistanceBetweenTrajectoryAndStraightLine(trial, actualX, actualY, straightTrajectory);
        trial.DeviationArea = areaBetweenTrajectoryAndStraightLine(trial, actualX, actualY, straightTrajectory);
        
    end

    
    
    %-------------------------------------------------------
    function buttonHeight = getResponseButtonHeight()
        if isfield(expData.Custom, 'ResponseButtonHeight')
            buttonHeight = expData.Custom.ResponseButtonHeight;
        else
            buttonHeight = 100; % Default = 100 pixels
        end
    end

    %-------------------------------------------------------
    % Create a straight trajectory from [0,0] to [endpointX,1]
    %
    function line = createStraightTrajectoryTo(endpointX)
        
        line = struct;
        line.x = abs(0:(endpointX/100):endpointX);
        line.y = 0:0.01:1;
        line.alpha = atan(endpointX);
        
    end
    
    %-------------------------------------------------------
    function [x,y] = getTrialXY(trial)
        
        x = trial.Trajectory(:, TrajCols.X);
        y = trial.Trajectory(:, TrajCols.Y);
        
        maxYInd = find(y > yCoordForBottomOfResponseButtons, 1);
        if isempty(maxYInd)
            maxYPix = round(max(y)*expData.logicalScaleToPixelsFactor());
            fprintf('Warning in trial #%d when calculating deviation from straight line: the trajectory ended %d pixels below the response button\n', ...
                trial.TrialIndex, expData.Custom.TrajZeroCoordY - getResponseButtonHeight() - maxYPix);
            maxYInd = length(y);
        end
        x = x(1:maxYInd);
        y = y(1:maxYInd);
    end
    
    
    %------------------------------------------------------
    function d = maxXDistanceBetweenTrajectoryAndStraightLine(trial, actualX, actualY, straightTrajectory)
        
        lineSlope = straightTrajectory.x(end) / straightTrajectory.y(end);
        straightTrajX = arrayfun(@(y)lineSlope*y, actualY);
        
        if (trial.RequiredResponse == 0)
            straightTrajX = -straightTrajX;
            xDiff = actualX - straightTrajX;
        else
            xDiff = straightTrajX - actualX;
        end
        
        d = max(xDiff);
        
        if isempty(d)
            trial.Trajectory(:, TrajCols.Y)
            error('ERROR in trial #%d: distance cannot be calculated', trial.TrialIndex);
        end
        
    end

    %------------------------------------------------------
    function d = maxOrthoDistanceBetweenTrajectoryAndStraightLine(trial, x, y, straightTrajectory)
        d = max(arrayfun(@(row)minOrthoDistanceBetweenLineAndPoint(straightTrajectory, x(row), y(row)), 1:length(x)));
    end

    %------------------------------------------------------
    function d = minOrthoDistanceBetweenLineAndPoint(line, x, y)
        
        dy = y - line.y(find(line.x>=x,1));
        d = abs(dy) * sin(line.alpha);
        
    end

    %------------------------------------------------------
    function area = areaBetweenTrajectoryAndStraightLine(trial, actualX, actualY, line)
        
        lineSlope = line.x(end) / line.y(end);
        lineX = arrayfun(@(y)lineSlope*y, actualY);
        
        if (trial.RequiredResponse == 0)
            lineX = -lineX;
            xDiff = actualX - lineX;
        else
            xDiff = lineX - actualX;
        end
        
        dy = diff(actualY);
        dy = conv([dy(1); dy; dy(end)], [.5 .5], 'valid');
        
        area = sum(xDiff  .* dy);
    end

    %------------------------------------------------------
    function area = areaBetweenTrajectoryAndStraightLine_OLD(trial, line)
        
        lineSlope = line.x(end);
        lineX = arrayfun(@(y)lineSlope*y, trial.Trajectory(:, TrajCols.Y));
        
        xDiff = abs(trial.Trajectory(:, TrajCols.X) - lineX);
        
        dy = diff(trial.Trajectory(:, TrajCols.Y));
        dy = conv([dy(1); dy; dy(end)], [.5 .5], 'valid');
        
        area = sum(xDiff  .* dy);
        
        % Divide by the trajectory X-length
        area = area ./ abs(diff(trial.Trajectory([1,end], TrajCols.X)));
        
    end
end
