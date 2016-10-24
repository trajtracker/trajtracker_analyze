function rr = invalidRegResults(nPredictors)

    rr = struct;
    rr.beta = NaN(nPredictors, 1);
    rr.p = NaN(nPredictors, 1);
    rr.stderr = NaN(nPredictors, 1);
    rr.rSquare = NaN;
    rr.regressionPVal = NaN;
    rr.df = NaN;
    rr.r2_per_predictor = NaN(nPredictors, 1);
    rr.adj_r2_per_predictor = NaN(nPredictors, 1);
    rr.stat = [];

end

