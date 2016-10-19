function s = format_pval(p)
%s = format_pval(p) - print p value, formatted in relevant accuract

    if p >= .03
        s = sprintf('%.2f', p);
    elseif p >= .003
        s = sprintf('%.3f', p);
    elseif p >= .0003
        s = sprintf('%.4f', p);
    else
        expo = ceil(-log(p) / log(10));
        x = p * 10 ^ expo;
        s = sprintf('%se-%d', formatRealNumber(x, 'MaxPrec', 3), expo);
    end

end

