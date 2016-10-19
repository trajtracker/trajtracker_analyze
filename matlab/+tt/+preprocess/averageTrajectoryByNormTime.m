function txy = averageTrajectoryByNormTime(trials, numPoints, avgFunc)
%  Calculate the average trajectory for a given set of trials.
%
% Input: 
% - a vector of OneTrialData objects
% - Number of samples required in the trajectory
%
% Output: A trajectory with the given number of samples. Each point in the
% trajectory is the average (centroid) of the corresponding points in the
% trajectories of all given trials.

    if ~ exist('avgFunc', 'var')
        avgFunc = 'mean';
    end
    
    % Get trajectories from each trial and store in a 3-dimensional array
    trajectories = zeros(numPoints, 5, length(trials));
    i=1;
    for td = trials
        trajectories(:,:,i) = td.getTrajectoryWithFixedNumPoints(numPoints);
        i = i+1;
    end

    txy = zeros(numPoints, 3);
    for iRow = 1:numPoints
        time = trajectories(iRow, 1, 1);
        switch(avgFunc)
            case 'mean'
                avgX = mean(trajectories(iRow, 2, :));
                avgY = mean(trajectories(iRow, 3, :));
                
            case 'median'
                avgX = median(trajectories(iRow, 2, :));
                avgY = median(trajectories(iRow, 3, :));
                
            otherwise
                avgFunc %#ok<NOPRT>
                error('Unknown averaging function.'); 
        end
        
        txy(iRow,:) = [time avgX avgY];
    end
    
end
