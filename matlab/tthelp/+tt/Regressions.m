%-----------------------------------------------
%-- TrajTracker analysis toolbox: Regressions --
%-----------------------------------------------
%
% To show this again, run "help tt.Regressions"
% 
% To read basic explanations about TrajTracker's regression analyses, visit
% our website: http://drordotan.wixsite.com/trajtracker/ttrk-analyze-design
% 
% For a list of all regression functions, run <a href="matlab:help tt.reg">help tt.reg</a>
% 
% 
%  Overview
% ++++++++++
% 
% TrajTracker's approach is to run one regression per subject, and analyze
% the regression coefficients (b or beta) to obtain a group-level effect.
% When the analyzed data (the dependent variable, the predictors, or both)
% is a "dynamic" measure (i.e., its value changes throughout the
% trajectory), this analysis is performed in different points along the
% trajectory - usually, for different absolute time points, starting from
% the finger movement onset time and proceeding in fixed intervals.
% 
% TrajTracker regressions are typically handled by two functions:
% - <a href="matlab:help tt.reg.regress">tt.reg.regress</a> runs a specific regression model 
%   on the data of a single subject. If the regression is
%   timepoint-dependent, the function will run the regression model per
%   time point.
% - Another function loops through subjects and calls tt.reg.regress() per
%   subject. This function can also attempt several regression models, in
%   which case it will call tt.reg.regress() for each model.
%   This is a function you should write yourself. A template, which you can
%   copy and edit, is provided in tt.reg.customize.runRegressions
% 
% 
%  Defining the predictors and the dependent variable
% ++++++++++++++++++++++++++++++++++++++++++++++++++++
% 
% TrajTracker supports a set of predefined measures, each of which can be
% used as predictor or as a dependent variable. You create a regression
% model simply by defining the measure names, e.g.:
% 
% tt.reg.regress(expData, 'reg', 'avgvel', {'target', 'prevtarget'})
% 
% This function uses a regression model where the dependent variable is the
% average velocity in the trial ('avgvel') and there are 2 predictors: the
% target number of the present trial and of the previous trial.
% 
% The TrajTracker-supported trial-level measures are defined in 
% <a href="matlab:help tt.reg.getTrialMeasures">tt.reg.getTrialMeasures</a>.
% 
% Here's another example:
% 
% tt.reg.regress(expData, 'reg', 'Traj.XSpeed', {'target', 'prevtarget'}, 'TPDep')
% 
% In this example, the dependent variable is the momentary x speed
% ("Traj.XSpeed"). This value changes per time point - this is indicated by
% the 'TPDep' parameter (a similar parameter 'TPPred' indicates that the
% predictor value changes per time point).
% The TrajTracker-supported dynamic (within-trajectory) measures are defined in 
% <a href="matlab:help tt.reg.getTrialDynamicMeasures">tt.reg.getTrialDynamicMeasures</a>.
% 
% If you want to define a measure, not provided in the default TrajTracker
% scripts, you can do this in several ways:
% - Write a function that saves this measure as a custom attribute, and 
%   use "Custom.xxxx" as the measure name. This is useful only for
%   trial-level measures.
% - Provide a function instead of the measure name. This too can be used
%   only for trial-level measures.
% - Create your own version of "getTrialMeasures" or "getTrialDynamicMeasures". 
%   Your custom function will get the ExperimentData object and the string names
%   of the measures sent to the "regress" function; it should return the
%   values of all measures (per time point, in case of dynamic measures).
%   Templates for such custom functions are available in 
%   tt.reg.customize.getTrialMeasures and tt.reg.customize.getTrialDynamicMeasures
% 
% 
%  Defining the trials included in the regression analysis
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++
% 
% TrajTracker runs one regression per subject, and potentially also per
% time point. Within each of these regressions, the default mode is that 
% each trial contributes a single data point. You can override this default
% behavior in two ways:
% 
% - Filtering: use filters to include only a subset of trials in the
%   analysis. The regress() function can get a 'TrialFilter' parameter - a
%   function that decides, per trial, whether to include it or not. For
%   example:
%   tt.reg.regress(....., 'TrialFilter', @(trial)trial.Target>20)
%   will include in the regressions only trials with target > 20
% 
% - Transform: After filtering trials, you can also specify a function that 
%   transforms the set of filtered trials into a new set of trials. For
%   example, the transformation function can group all trials having the
%   same target number, and calculate the average trajectory of these
%   trials (this is useful to prevent bias towards over-represented targets).
% 
% 
%  Grouping time points
% ++++++++++++++++++++++
% 
% This topic is relevant only for dynamic regressions, i.e., regressions
% that run per time point.
% 
% By default, one regression will be run per time point, starting at t=0
% and proceeding in fixed time intervals. If some trials end earlier than
% others, these trials will be artifically extended using their endpoint
% values.
% The regress() function provides several parameters for tweaking this
% behavior: 'dt' defines the delay between regressions, and
% 'Row1OffsetFunc' or 'Row1OffsetAttr' allows starting the regressions at a
% time point other than t=0.
% 
% Alternatively, you can use the 'rows' parameter to explicitly provide numbers
% of rows in the trajectory matrix.
% 
% Last, you can use each of the above mechanisms to define "virtual time
% points", and use 'TpToRowFunc' to convert these time points, per trial, into
% row numbers in the trajectory matrix.
% 
% 
%  The results format
% ++++++++++++++++++++
% 
% The regression results are organized in a multi-level data structure:
% 
% - The results of a complete dataset are a Matlab struct, in which each
%   entry is the data of one subject. The struct key is the subject
%   initials.
% 
% - The results of one subject are a Matlab struct. It has some predefined
%   fields (e.g., SubjectName, SubjectInitials), and one additional field per
%   regression model attempted. This field is a <a href="matlab:help tt.reg.OneRR">tt.reg.OneRR</a> object.
% 
% - The OneRR object reflects the results of one regression model for one
%   subject - i.e., the output of a single call to tt.reg.regress().
%   It contains the model definitions (predictor, dependent var), the time
%   points for which the regression was run, and the regression results,
%   the most important of which are the regression coefficients per
%   predictor and time point.
%   The results of one predictor can be obtained by calling
%   oneRR.getPredResult(predictor_name)
%   
% - The results of one predictor are stored as a <a href="matlab:help tt.reg.OnePredRR">tt.reg.OnePredRR</a> object.
%   This object stores the b value, beta value, p value, etc., each of
%   which is a column vector with one entry per time point.
% 
% 
%  Group-level analyses & plotting the regression results
% ++++++++++++++++++++++++++++++++++++++++++++++++++++++++
% 
% After regressions were run, we can examine, per time point, whether the 
% effect of a predictor is significantly larger than 0 or than another
% predictor. This is done via the <a href="matlab:help tt.reg.compareParams">tt.reg.compareParams()</a> function.
% 
% The output of tt.reg.compareParams() is also used for plotting the
% regression results with <a href="matlab:help tt.reg.plotParamComparison">tt.reg.plotParamComparison()</a>.
% 
% To plot the results of a single subject, transform the regression results
% into the format required by plotParamComparison() - this is done using
% the <a href="matlab:help tt.reg.reformatOneRRForPlots">tt.reg.reformatOneRRForPlots()</a> function.
% 

help tt.Regressions
