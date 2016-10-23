%------------------------------------------------
%-- TrajTracker analysis toolbox: Data formats --
%------------------------------------------------
%
%   Raw results
% +++++++++++++++
% Generally, we represent the experimental data in three levels:
% 1. Single trial (<a href="matlab:help OneTrialData">OneTrialData</a> object).
% 2. Experiment session (<a href="matlab:help ExperimentData">ExperimentData</a> object): results from one experiment session, one subject.
%    If the experiment included several conditions (mixed design), we will
%    typically break down the data into several ExperimentData objects.
%    Similarly, if a single condition was run in two blocks just for
%    convenience, we will typically merge the data into a single
%    ExperimentData object.
% 3. Dataset: the ExperimentData's of several subjects in one experiment or
%    one condition.
% 
% (regression results)
% (strict classes; flexibility via x.Custom)
% (Trajectory matrices)
