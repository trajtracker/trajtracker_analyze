function trajMatrix = createTrajectoryMatrixGD(absTimes, x, y, expData, args)
% trajData = createTrajectoryMatrixGD(absTimes, x, y)
% 
% Create the full trajectory matrix for decision experiments

    if ~exist('args', 'var')
        args = struct;
    end
    
    [trajMatrix,trajSlope] = tt.preprocess.createTrajectoryMatrixCommonParts(absTimes, x, y, args);

    %-- Implied endpoint, based on dx/dy

    if isfield(args, 'iEPYCoord')
        yMax = args.iEPYCoord;
    elseif isfield(expData.Custom, 'iEPYCoord')
        yMax = expData.Custom.iEPYCoord;
    else
        yMax = expData.maxYLogicalCoord();
    end
    yDistanceFromAxis = max(yMax - y, 0); % using max(0) just in case the finger went beyond yMax
    impliedEP = x + (yDistanceFromAxis .* trajSlope);  % on a -1..1 scale

    % The implied endpoint cannot be considered to be outside the iPad screen.
    impliedEP = min(impliedEP, 1);
    impliedEP = max(impliedEP, -1);
    
    trajMatrix(:, TrajCols.InstImpliedEP) = impliedEP;
    
end
