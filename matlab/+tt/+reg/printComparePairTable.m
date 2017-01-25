function printComparePairTable(cmp, paramNums)
%printComparePairTable(cmp, paramNums)
% Print the results of comparing two parameters with tt.reg.compareParams()
% paramNums: Numbers of parameters whose value will also be printed
    
    if ~exist('paramNums', 'var')
        paramNums = [];
    end
    
    % Print header line
    fprintf('Time\tp\tF/t\tCoh-d*\tb2-b1');
    for v = paramNums
        fprintf('\t%s', cmp.paramNames{v});
    end
    fprintf('\n');
    
    SIGNIFICANT = {'', '*'};
    
    for row = 1:length(cmp.times)
        p = cmp.comparePair.pPred(row);
        fprintf('%d\t%s%.3f\t%.2f\t%.2f\t%.3f', round(1000*cmp.times(row)), SIGNIFICANT{1+(p<.05)}, p, cmp.comparePair.fPred(row), cmp.comparePair.esPred(row), cmp.comparePair.values(row));
        for v = paramNums
            fprintf('\t%.3f', cmp.(sprintf('values%d', v))(row));
        end
        fprintf('\n');
    end
    
    fprintf('df(t)/dfe = %d\n', cmp.comparePair.dfPred(1));
    [f,ind] = max(abs(cmp.comparePair.fPred));
    fprintf('Max(F) = %.2f at %d ms\n', f, round(1000*cmp.times(ind)));
    [f,ind] = min(abs(cmp.comparePair.fPred));
    fprintf('Min(F) = %.2f at %d ms\n', f, round(1000*cmp.times(ind)));
    fprintf('* "Coh-d" means Cohen''s d\n');
    
end

