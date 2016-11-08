%        -------------------------------------------------------
%        -- TrajTracker analysis toolbox: Directory structure --
%        -------------------------------------------------------
%
%  Where are all the files stored? / setting the toolbox after installation
% ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
% 
% The TrajTracker toolbox assumes that you store your data on the file
% system in a certain format and a certain directory structure.
% 
% The path for a given data file is almost always specified relatively
% a certain base path, which is defined by the <a href="matlab:help TrajTrackerDataPath">TrajTrackerDataPath</a>()
% function.
% You can choose any base path you want, as long as you keep your files
% anywhere under it. If you choose base path = "/", you can put the files 
% everywhere on your computer; but we recommend choosing a meaningful
% base path, so you can later move all your data to another location
% and you'll only have to modify TrajTrackerDataPath()
% 
% The TrajTrackerDataPath function is not provided with the toolbox. You
% will find, however, a file called TrajTrackerDataPath.m.txt. 
% Copy it, remove the ."txt" suffix, edit the function to return the base
% path you chose, and put the function anywhere in your matlab path.
%
% 
%   Storing datasets 
% ++++++++++++++++++++
% Each dataset is stored in a separate directory, which is anywhere under
% the base path (not necessarily a direct child of the base path).
% A dataset's directory contains two sub-directories:
% - raw: The raw files from the application (see help <a href="matlab:help tt.DataFormats">tt.DataFormats</a>)
% - binary: the data in matlab format. The preprocessed dataset will be
%           stored here in a file called session_data.mat. You can also
%           store here regression results and other data files.
