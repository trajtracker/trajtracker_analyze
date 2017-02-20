function result = chooseRandomNTrials(trials, n)
%result = chooseRandomNTrials(trials, n) - Choose N trials randomly.
% The choice is made such that the distribution of targets would be 
% as flat as possible.
% e.g., if there are 5 different targets, and you ask for 10 trials, you'll
% get 2 random trials per target (assuming there are indeed at least 
% 2 trials per target).

    % Shuffle trials
    [~,i] = sort(rand(1,length(trials)));
    trials = trials(i);

    targets = arrayfun(@(t)t.Target, trials);
    uTargets = unique(targets, 'stable');
    nTrialsPerTarget = arrayfun(@(t)sum(targets==t), uTargets);

    % Create a matrix in which each trial index appears once.
    % Each column is the same target numbers
    trialIndMat = NaN(max(nTrialsPerTarget), length(uTargets));
    for iTrg = 1:length(uTargets)
        trialIndMat(1:nTrialsPerTarget(iTrg), iTrg) = find(targets==uTargets(iTrg))';
    end

    % Now, take the first rows
    trialInds = reshape(trialIndMat', 1, numel(trialIndMat));
    trialInds = trialInds(~isnan(trialInds));

    result = trials(trialInds(1:n));

end

