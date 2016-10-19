function arsq = calcAdjRSquare(rsq, nObservations, nPredictors)
    arsq = 1 - (1 - rsq) * (nObservations - 1) / (nObservations - nPredictors - 1);
end
