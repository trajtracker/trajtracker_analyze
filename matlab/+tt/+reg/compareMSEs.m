function compareMSEs(rr, rrKeys, varargin)
% compareMSEs(rr, regressionKeys) - 
% Compare two regression models.
    
    [rr, rrKeys] = fixArgs(rr, rrKeys);
    [condNames, expecting1Better] = parseArgs(varargin, rrKeys);

    mse1 = arrayfun(@(r)r.(rrKeys{1}).MSE, tt.reg.toRRArray(rr{1}))';
    mse2 = arrayfun(@(r)r.(rrKeys{2}).MSE, tt.reg.toRRArray(rr{2}))';
    meanMSE = [mean(mse1), mean(mse2)];
    
    betterCond = iif(meanMSE(1) < meanMSE(2), 1, 2);
    
    [~,p,~,stat] = ttest(mse1, mse2);
    
    if expecting1Better
        p = iif(betterCond==1, p/2, 1);
        tails = 'one';
    else
        tails = 'two';
    end
    
    fprintf('Better cond: %s (MSE=%.3f), other cond: %s (MSE=%.3f).\n', condNames{betterCond}, meanMSE(betterCond), condNames{3-betterCond}, meanMSE(3-betterCond));
    if expecting1Better && betterCond~=1
        fprintf('     :-(  opposite to prediction\n');
    else
        fprintf('     Difference: t(%d) = %.2f, %s-tailed p=%s\n', stat.df, stat.tstat, tails, formatRealNumber(p, 'MinPrec', 3));
    end
    
    
    %-----------------------------------------------------------------
    function [rr, rrKeys] = fixArgs(rr, rrKeys)
        
        if iscell(rr) && iscell(rrKeys)
            
            if length(rr) ~= length(rrKeys)
                error('RR or regressionKeys must be cell arrays of the same length!');
            end
            
        elseif ~iscell(rr) && ~iscell(rrKeys)
            
            error('Either RR or regressionKeys must be a cell array!');
            
        elseif ~iscell(rr)
            
            rr = repmat({rr}, 1, length(rrKeys));
            
        else
            
            rrKeys = repmat({rrKeys}, 1, length(rr));
            
        end
        
    end

    %-------------------------------------------
    function [condNames, expecting1Better] = parseArgs(args, rrKeys)

        if strcmpi(rrKeys{1}, rrKeys{2})
            condNames = {'Condition 1', 'Condition 2'};
        else
            condNames = rrKeys;
        end
        
        expecting1Better = false;
        
        args = stripArgs(args);
        while ~isempty(args)
            switch(lower(args{1}))
                case 'condnames'
                    condNames = args{2};
                    args = args(2:end);

                case '1better'
                    expecting1Better = true;
                    
                otherwise
                    error('Unsupported argument "%s"!', args{1});
            end
            args = stripArgs(args(2:end));
        end

    end


end
