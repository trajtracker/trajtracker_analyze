function trajMatrix = createTrajectoryMatrixNL(absTimes, x, y, expData, args)
% trajData = createTrajectoryMatrixNL(absTimes, x, y, maxTarget[, args])
% 
% Create the full trajectory matrix for number-to-line experiments

    if ~exist('args', 'var')
        args = struct;
    end
    
    [trajMatrix,trajSlope] = tt.preprocess.createTrajectoryMatrixCommonParts(absTimes, x, y, args);

    %-- Implied endpoint, based on dx/dy

    yDistanceFromAxis = 1 - y;
    impliedEPOn1Scale = (x + (yDistanceFromAxis .* trajSlope)) / (expData.NLLength/2);  % on a -1..1 scale
    impliedEP = impliedEPOn1Scale * expData.MaxTarget/2 + expData.MaxTarget/2;

    % The implied endpoint cannot be considered to be outside the iPad screen.
    % Also, when theta is too sideways, the implied endpoint is meaningless
    impliedEP = min(impliedEP, expData.MaxTarget * 1.05);
    impliedEP = max(impliedEP, -expData.MaxTarget * 0.05);
    MAX_INFORMATIVE_THETA = pi * 85 / 180;
    impliedEP(logical(abs(trajMatrix(:, TrajCols.Theta)) > MAX_INFORMATIVE_THETA)) = NaN;

    trajMatrix(:, TrajCols.ImpliedEP) = impliedEP;
    
end
