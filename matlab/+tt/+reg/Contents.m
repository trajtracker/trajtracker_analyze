% -----------------------------------------
% --    TrajTracker: package tt.reg      --
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
%              OneRR.getPredResult() gets the per-predictor info (<a href="matlab:help tt.reg.OnePredRR">OnePredRR</a>),
%              where all the results (b, beta, p, etc.) are stored.
% 
% Basic processing of regression results:
% <a href="matlab:help tt.reg.listInitials">listInitials</a>: Get list of subjects.
% <a href="matlab:help tt.reg.filterSubjects">filterSubjects</a>: Filter regression results object to include/exclude specific subjects.
% <a href="matlab:help tt.reg.toRRArray">toRRArray</a>: Convert a results struct into an array (one entry per subject).
% <a href="matlab:help tt.reg.getRRCoeffs">getRRCoeffs</a>: get results of one parameter for multiple subjects.
% <a href="matlab:help tt.reg.averageRegressionResults">averageRegressionResults</a>: Average regression results over subjects.
% 
% Group-level analyses and plots:
% <a href="matlab:help tt.reg.compareParams">compareParams</a>: Analyze regression results from multiple subjects.
% <a href="matlab:help tt.reg.plotParamComparison">plotParamComparison</a>: Plot the results of multiple subjects.
% <a href="matlab:help tt.reg.reformatOneRRForPlots">reformatOneRRForPlots</a>: reformat one subject results for plotParamComparison().
% 
% Calculating and comparing the timing of regression effects:
% <a href="matlab:help tt.reg.findBThresholdTime">findBThresholdTime</a>: Find the time when a regression effect reached some threshold.
% <a href="matlab:help tt.reg.findBThresholdDelay">findBThresholdDelay</a>: Compare the regression effect reach-threshold time between 2 conditions.
% <a href="matlab:help tt.reg.findBuildupDelay">findBuildupDelay</a>: Compare the regression effect timing between 2 conditions.
% 
% 
% The following functions are used by regress(), you don't call them directly but
% you may need to look at them:
% <a href="matlab:help tt.reg.getTrialMeasures">getTrialMeasures</a>: Extract trial-level measures from trials
% <a href="matlab:help tt.reg.getTrialDynamicMeasures">getTrialDynamicMeasures</a>: Extract per-timepoint measures from trials
% 
% 
% The regression scripts can be customized in several ways.
% The "tt.reg.customize" package includes templates for such cutomizations:
% <a href="matlab:help tt.reg.customize.runRegressions">runRegressions</a>: Run one or more specific regressions on all subjects,
%                 and save the results.
% <a href="matlab:help tt.reg.customize.getMyTrialMeasures">getMyTrialMeasures</a>: for adding new trial-level predictors / dependent variable.
% <a href="matlab:help tt.reg.customize.getMyTrialDynamicMeasures">getMyTrialDynamicMeasures</a>: for adding new per-timepoint predictors / dependent variable.
% 
