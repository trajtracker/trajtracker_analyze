function s = formatRealNumber(n, varargin)
% str = formatRealNumber(n, ...) - format a number to string.
% Numbers are always formatted in floating-point style, never in e-style (##e+#)
% The function can auto-detect the relevant precision.
% 
% Optional arguments:
% Precision <#> - use this precision. This is equivalent to calling
%                 sprintf('%.*f', precision, number)
% MaxPrec <#> - when auto-detecting, don't exceed this precision.
% 
% Written by Dror Dotan, 2016

    [precision, maxPrecision, minPrecision] = parseArgs(varargin);
    
    if isempty(precision)
        precision = findPrecision(n, maxPrecision);
        precision = max(precision, minPrecision);
    end
    
    if (n == 0)
        s = '0';
    else
        s = sprintf('%.*f', precision, n);
    end
    
    %-------------------------------------------
    function [precision, maxPrecision, minPrecision] = parseArgs(args)

        precision = [];
        maxPrecision = 5;
        minPrecision = 0;
        
        args = stripArgs(args);
        while ~isempty(args)
            switch(lower(args{1}))
                case 'precision'
                    precision = args{2};
                    args = args(2:end);

                case 'maxprec'
                    maxPrecision = args{2};
                    args = args(2:end);
                    
                case 'minprec'
                    minPrecision = args{2};
                    args = args(2:end);
                    
                otherwise
                    error('Unsupported argument "%s"!', args{1});
            end
            args = stripArgs(args(2:end));
        end

    end


end
