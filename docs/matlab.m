%% General programming concepts in TrajTracker
% 
% TrajTracker uses some programming tools and concepts that go beyond what
% we may call "basic matlab programming skills". If you are not familiar
% with these, we hope the following may help.
% 

%% Function handles
% 
% A function handle is a variable that represents a certain function.
% A handle to a function, say _f()_, can be passed as argument to another
% function, which would be able to call _f()_ via that handle. 
% 
% A common example to function handles is matlab's _arrayfun()_:
% 
%   a = 1:100;
%   b = arrayfun(@(x)x^2, a);
% 
% _arrayfun()_ gets two arguments - a function handle and an
% array - and applies to function to each element in the array.
% 
% The TrajTracker toolbox uses function handles for several goals.
% For example, |tt.util.filterTrials()| get the experiment data
% of one or several subjects and returns a corresponding data structure in
% which some of the trials were filtered out. To specify which trials
% should be included and which should be filtered out,
% |tt.util.filterTrials()| gets a function handle for a filtering function 
% that defines, per trial, whether to include it or not.
% 
% For this to work, |filterTrials()| should know how to call the
% filtering function you provide it. The way it works is that
% |filterTrials()| only accepts functions with a certain *signature*
% (= arguments and return value) - e.g., it can get a filtering function
% that gets a single argument (the trial) and returns a boolean value
% (true/false, indicating whether the trial should be included).
% 
% You can define function handles in two ways: by specifying a handle to an
% already-defined function, or by defining function inline. For example:
% 
%   function include = includeOnlyOddTargets(trial)
%       include = mod(trial.Target, 2) == 1;
%   end
% 
%   %-- Refer to a predefined function
%   f = tt.util.filterTrials(mydataset, @includeOnlyOddTargets);
% 
%   %-- Define a function inline
%   f = tt.util.filterTrials(mydataset, @(trial)mod(trial.Target, 2) == 1);
%   
% For more information on function handles, look 
% <https://www.mathworks.com/help/matlab/function-handles.html here>.


%% Classes
% 
% A _class_ is an object containing several entries (fields),
% much similarly to a matlab |struct|. Still, there are some important differences
% between classes and |struct|s:
% 
% * *Classes have names and are predefined*. Don't think of a class as a
%   variable; think of it as a definition of a complex type. You define a
%   class, and then you can define variables of this class. Variables of a
%   certain class are called objects.
%   In TrajTracker, we use two main classes: ExperimentData (objects of
%   this class contain information about a single experiment session of one
%   subject) and OneTrialData (objects of this class contain all
%   information of a single trial). The definition of a class is done in a
%   file whose name becomes the class name.
% 
% * *structs are dynamic, classes are not*. The class definition declares a
%   list of fields (also called "data members") that each object of that
%   class should have. Any object of the class automatically gets these
%   fields when initialized, and you cannot add new fields.
%   To nevertheless allow dynamic addition of fields to our TrajTracker
%   classes, we use a work-around that bypasses this limitation of matlab:
%   in each of our classes (ExperimentData and OneTrialData), we defined a
%   field called "Custom" (i.e., _expData.Custom_ and _trialData.Custom_)
%   whose value is initialized to a |struct|. Dynamic data can be added to
%   these |struct|s, e.g.:
% 
%   trialData.Custom.MyDynamicVariable = 3
% 
% * *Classes have methods*: a |struct| object contains data. A class contains
%   both data and functions. The functions of a class, called _methods_,
%   are defined as part of the class definition. The syntax for calling
%   them resembles that of the class data members:
% 
%   filtered = experimentData.filterTrials(...arguments...)
% 
% * *Class objects can be passed by reference*. When you assign the value
%   of a variable/struct to a new variable (e.g., |a = struct; b = a|)
%   you create a new copy of the data. Variables |a| and |b| are
%   independent - changing |a| has no effect on |b| and vice versa.
%   Similarly, if you pass a |struct| variable to a function and the
%   function changes its value (e.g. adds a field), this change will not be
%   reflected outside of the function.
%   A class can decide to change this behavior (and TrajTracker classes 
%   indeed do), and decide that objects of this class will be handled 
%   _by reference_. This means that when you "copy" the object to a new
%   variable, or pass it to a function, you don't really copy its data:
%   you're only creating another reference to the same physical object
%   (i.e. same memory location). Changing one will change the other. To see
%   this, try the following code:
%   
%   a = struct('x', 1);
%   b = a;
%   b.new_field = 3;
%   disp(a.new_field);  % This will result in an error: new_field was added to b but not to a
%   
%   a = NLOneTrialData(1, 1);
%   b = a;
%   b.TrialIndex = 5;
%   disp(a.TrialIndex);
% 
% * *Classes have private members*. In a |struct|, you can access all
%   fields. In a class object, some fields may be defined as _private_,
%   meaning that they can be accessed only by methods of that class. If you
%   display the object from matlab command line, private members will not
%   be shown.
% 
% 
% 
% To learn more about matlab classes, look
% <https://www.mathworks.com/help/matlab/object-oriented-programming-in-matlab.html here>
