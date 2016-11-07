% =======================================
% ==   TrajTracker analysis toolbox    ==
% =======================================
% - To see this help again, run "help tt"
% - To see documentation by topic (rather than by function), run <a href="matlab:help tt.Help">help tt.Help</a>
%   This is recommended if you're new to the TrajTracker toolbox.
% 
% IMPORTANT: IF THIS IS THE FIRST TIME YOU RUN THE TOOLBOX, YOU MUST DEFINE
% THE TrajTrackerDataPath() FUNCTION. See details in <a href="matlab:help tt.DirStruct">help tt.DirStruct</a>
% 
% Preprocess/load data:
% <a href="matlab:help tt.preprocessSet">tt.preprocessSet</a> - prepare a dataset
% <a href="matlab:help tt.loadDataset">tt.loadDataset</a> - load an already-preprocessed dataset
% 
% Sub-packages:
% <a href="matlab:help tt.inf">tt.inf</a>: extract various information from TrajTracker's data objects
% <a href="matlab:help tt.util">tt.util</a>: utility functions
% <a href="matlab:help tt.preprocess">tt.preprocess</a>: pre-processing functions
% <a href="matlab:help tt.reg">tt.reg</a>: run regressions & analyze results
% <a href="matlab:help tt.vel">tt.vel</a>: analyze velocities
% <a href="matlab:help tt.vis">tt.vis</a>: visualization (plots)
% <a href="matlab:help tt.curve">tt.curve</a>: find & use curves in trajectries
% 
% <a href="matlab:help tt.nl">tt.nl</a>: for number-line experiments
% <a href="matlab:help tt.dc">tt.dc</a>: for discrete-decision experiments
% 
% 
% THIS TOOLBOX IS PROVIDED AS-IS, WITH ABSOLUTELY NO WARRANTY. It is Licensed under
% the Academic Free License version 3.0 http://opensource.org/licenses/AFL-3.0
% Copyright (c) 2016 Dror Dotan
% 
% If you find any bugs, please let us know via the project's page in github:
% https://github.com/droralef/trajtracker/issues
% 
% To see how to cite this toolbox in publications, run <a href="matlab:tt.citation">tt.citation()</a>
% 
