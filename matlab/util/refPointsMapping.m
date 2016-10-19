function result = refPointsMapping(x, numLineLength, numSegments)
% result = refPointsMapping(linearTargets, numLineLength[, numSegments]) -
% A reference-points-based bias function
% 
% The assumption is that a number X is mapped to location X' according to 
% the following rule:
%
% The number line is cut into few equal segments (2 by default). 
% Each number X is mapped with respect to the two ends of the segment to
% which X belongs.
% 
% If the distances of X from the segment ends are L and R, the value of
% X' will be determined according to the ratio between log(L) and log(R).
% That is, on a scale of 0-1, and assuming X is on the first segment of the
% number line, we would get:
%
% X' = log(L+1) / ( log(L+1) + log(R+1) )
% 
% 
% Arguments:
% ----------
% x:             the values to map
% numLineLength: maximal value on the number line
% numSegments:  (optional) the number of segments (default: 2)

    if ~exist('numSegments', 'var')
        numSegments = 2;
    end
    
    result = x;
    
    segmentLength = numLineLength/numSegments;
    if (segmentLength ~= round(segmentLength))
        error('A number line with length=%d cannot be cut into %d segments', numLineLength, numSegments);
    end
    
    
    for iSeg = 1:numSegments
        
        segStart = segmentLength * (iSeg-1);
        segEnd = segmentLength * iSeg;
        
        linearTargetsRelevantInds = logical(x > segStart & x < segEnd);
        
        result(linearTargetsRelevantInds) = segStart + calcWithinSegment(x(linearTargetsRelevantInds)-segStart, segmentLength);
        
    end
    
    
    %----------------------------------------------------------
    function r = calcWithinSegment(linearTargetsInSegment, segmentLength)
        
        leftOfTarget = linearTargetsInSegment+1;
        rightOfTarget = (segmentLength-linearTargetsInSegment)+1;
        
        r = log(leftOfTarget) ./ (log(leftOfTarget) + log(rightOfTarget)) .* segmentLength;
        
    end

end
