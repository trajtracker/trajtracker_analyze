function averages = averageTrajectoryByTime(trials, samplingRate, numPoints, trajColumns, avgFunc)
%  Calculate the average/standard deviation trajectory for a given set of trials.
%
% Input: 
% trials      : a vector of OneTrialData objects
% samplingRate: The required sampling rate (in seconds)
% numPoints   : The number of points in the output trajectory.
% trajColumns : The trajectory columns to include in the result
% avgFunc     : Either 'mean' or 'std'
%
% Output: A trajectory with the given number of samples. Each point in the
% trajectory is the average (centroid) of the corresponding points in the
% trajectories of all given trials.
% If 'numPoints' is longer or shorter than the actual trajectory, the
% trajectory is either chopped or extended by keeping the same x/y values

    % Default num-points is determined by the average trajectory duration
    if ~ exist('numPoints', 'var') || numPoints <= 0
        numPoints = round(getAverageTrajectoryDuration() / samplingRate);
    end
    if ~ exist('avgFunc', 'var')
        avgFunc = 'mean';
    end
    
    % Get trajectories from each trial and store in a 3-dimensional array
    trajectories = zeros(numPoints, 1+length(trajColumns), length(trials));
    i=1;
    for td = trials
        try
            trajectories(:,:,i) = td.getTrajectoryWithFixedSamplingRate(samplingRate, numPoints, trajColumns);
        catch e
            fprintf('Error in trial #%d\n', td.TrialNum);
            e.rethrow()
        end
        i = i+1;
    end

    averages = nan(numPoints, length(trajColumns));
    averages(:,1) = trajectories(:, 1, 1); % times
    
    for col = 1:length(trajColumns)
        dataFromAllTrials = trajectories(:, col+1, :);
        dataFromAllTrials = reshape(dataFromAllTrials, size(dataFromAllTrials, 1), size(dataFromAllTrials, 3));
        switch(avgFunc)
            case 'mean'
                averages(:,col+1) = mean(dataFromAllTrials, 2);
            case 'median'
                averages(:,col+1) = median(dataFromAllTrials, 2);
            case 'std'
                for row = 1:size(averages,1)
                    averages(row,col+1) = std(dataFromAllTrials(row,:));
                end
            otherwise
                error('Unknown average function: %s', avgFunc);
        end
    end
    
    
    function a = getAverageTrajectoryDuration()
        a = mean(arrayfun(@(x)x.MovementTime, trials));
    end

end
