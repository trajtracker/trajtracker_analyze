function [startInds, endInds] = findSequencesOf1(array, minSequenceLength)
%[startInds, endInds] = findSequencesOf1(array, minLength) - 
%within an array, find sequences of 1's

    array = reshape(array, 1, numel(array));
    
    withinSequence = conv(array+0, ones(1, minSequenceLength), 'valid') >= minSequenceLength;

    startInds = find(diff(withinSequence) == 1);
    if (withinSequence(1) == 1)
        startInds = [0 startInds];
    end

    endInds = find(diff(withinSequence) == -1);
    if (withinSequence(end) == 1)
        endInds = [endInds length(withinSequence)];
    end
    
    startInds = startInds + 1;
    endInds = endInds + minSequenceLength - 1;

end

