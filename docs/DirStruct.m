%% TrajTracker analysis toolbox: Directory structure
%

%%  Where are all the files stored? / setting the toolbox after installation
% 
% The TrajTracker toolbox assumes that you store your data on the file
% system in a certain format and a certain directory structure.
% 
% The path for a given data file is almost always specified relatively
% a certain base path, which is defined by the _TrajTrackerDataPath()_
% function.
% 
% You can choose any base path you want, as long as you keep your files
% anywhere under it. If you choose base path = "/", you can put the files 
% everywhere on your computer; but we recommend choosing a meaningful
% base path, so you can later move all your data to another location
% and you'll only have to modify TrajTrackerDataPath()
% 
% The TrajTrackerDataPath function should be created when you run
% the toolbox installer script.
%

%% Storing datasets 
% 
% Each dataset is stored in a separate directory, which is anywhere under
% the base path (not necessarily a direct child of the base path).
% 
% A dataset's directory contains two sub-directories:
% 
% * raw: The raw files from the application (<DataFormats.html details...>)
% * binary: the data in matlab format. The preprocessed dataset will be
%           stored here in a file called session_data.mat. You can also
%           store here regression results and other data files.

