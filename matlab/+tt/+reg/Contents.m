% -----------------------------------------
% --     TrajTracker: package tt.reg     --
% -----------------------------------------
% 
% Running regressions:
% <a href="matlab:help tt.reg.regress">regress</a>: Run regression per subject
% <a href="matlab:help tt.reg.averageRegressionResults">averageRegressionResults</a>: calc average RR from several subjects.
% 
% The regression results are typically stored in the following format:
% Main object: struct with one entry per subject.
% Within this: several objects, one per regression (<a href="matlab:help tt.reg.OneRR">OneRR</a>).
%              Such object contains results from several time points.
%              OneRR.PredResults contains one entry per predictor (<a href="matlab:help tt.reg.OnePredRR">OnePredRR</a>),
%              where all the results (b, beta, p, etc.) are stored.
% 
% Basic processing of regression results:
% <a href="matlab:help tt.reg.getSubjInitials">getSubjInitials</a>: Get list of subjects.
% <a href="matlab:help tt.reg.toRRArray">toRRArray</a>: convert a results struct to array with
%               one entry per subject.
% <a href="matlab:help tt.reg.toRRArray">toRRArray</a>: Convert a results struct into an array (one entry per subject).
% 
% Processing regression results:
% <a href="matlab:help tt.reg.compareParams">compareParams</a>: Analyze regression results from multiple subjects.
% <a href="matlab:help tt.reg.getRRCoeffs">getRRCoeffs</a>: get results of one parameter for multiple subjects.
% 
% 
% The following functions are used by regress(), you don't call them directly but
% you may need to look at them:
% <a href="matlab:help tt.reg.getTrialMeasures">getTrialMeasures</a>: Extract trial-level measures from trials
% <a href="matlab:help tt.reg.getTrialDynamicMeasures">getTrialDynamicMeasures</a>: Extract per-timepoint measures from trials
% 
