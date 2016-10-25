function updatePrevTargets(allExpData, nPrevTrials, markNext)
%updatePrevTargets(dataset, n[, next]) -
% Update, on each trial, the targets of the N previous/next trials.
%
% n: How many prev/next trials to update.
% nNext: if true, marking next trials instead of previous

    if ~exist('markNext', 'var')
        markNext = false;
    end
    
    for i = tt.inf.listInitials(allExpData)
        doUpdate(allExpData.(i{1}), markNext);
    end

    
    %---------------------------------------------------------
    function doUpdate(expData, markNext)
        
        if (markNext)
            dTrial = 1;
            attrNamePrefix = 'NextTarget';
        else
            dTrial = -1;
            attrNamePrefix = 'PrevTarget';
        end

        
        trialInds = arrayfun(@(t)t.TrialIndex, expData.Trials);
        trials = cell(1, max(trialInds));
        for trial = expData.Trials
            trials{trial.TrialIndex} = trial;
        end
        
        for trial = expData.Trials
            
            for iOther = 1:nPrevTrials
                
                otherTrialInd = trial.TrialIndex + dTrial*iOther;
                
                if (otherTrialInd > 0 && otherTrialInd < length(trials) && ~isempty(trials(otherTrialInd)))
                    otherTarget = trials{otherTrialInd}.Target;
                else
                    otherTarget = NaN;
                end
                
                if (iOther == 1)
                    if (markNext)
                        trial.Custom.(attrNamePrefix) = otherTarget;
                    else
                        trial.PrevTarget = otherTarget;
                    end
                end
                trial.Custom.(sprintf('%s%d', attrNamePrefix, iOther)) = otherTarget;
            end
            
        end
        
    end

end

