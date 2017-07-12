function InstallTrajTracker()
% InstallTrajTracker() - Download and install the TrajTracker toolbox
% 

    fprintf('\n');
    fprintf('   TrajTracker toolbox installation\n');
    fprintf('   ================================\n');
    
    fprintf('Please enter the directory under which you plan to store all your TrajTracker results.\n');
    fprintf('Each data directory in TrajTracker is defined by its location relatively to this base directory.\n');
    
    root_path = '';
    while ~exist(root_path, 'dir')
        root_path = input('Root data path (default = /): ', 's');
        if isempty(root_path)
            root_path = '/';
        end
    end
    
    toolbox_filename = 'TrajTracker.mltbx';
    toolbox_path = '' + toolbox_filename;
    local_filename = tempdir + '/' + toolbox_filename;
    
    fprintf('Downloading latest version of TrajTracker...\n');
    websave(local_filename, toolbox_path);
    fprintf('Done.\n\n');
    
    fprintf('Installing toolbox...\n');
    toolbox = matlab.addons.toolbox.installToolbox(local_filename, true);
    
    fprintf('%s version %s was installed\n\n', toolbox.Name, toolbox.Version);
    
    ttrk_dir = toolboxdir(toolbox.Name);
    
    fprintf('\nThe TrajTracker toolbox was installed in %s\n', ttrk_dir);
    
    addpath(strcat(ttrk_dir, '/util'));
    savepath();
    
    create_root_path_func(ttrk_dir, root_path)
    
    fprintf('\n\nSuccessfully installed TrajTracker\n');
    fprintf('\nFor more information, visit us at http://www.trajtracker.com\n');
    
    %------------------------------------------------------------------
    function create_root_path_func(directory, root_path)
        
        fprintf('Creating a TrajTrackerDataPath.m file...\n');
        
        func_text = join('', {'function p = TrajTrackerDataPath()\n', ...
            sprintf('    p = ''%s''\n', root_path), ...
            'end\n' });
        
        try
            fh = fopen([directory '/TrajTrackerDataPath.m'], 'w');
            fprintf(fh, func_text);
            fclose(fh);
        catch e
            fprintf('\n\n\n\nTHE INSTALLATION ACTUALLY SUCCEEDED!\n\n\n\n');
            fprintf('The toolbox was installed, but I could not create the TrajTrackerDataPath.m file in %s', directory);
            fprintf('Create this file yourself, and paste the following code in it:\n%s\n\n', func_text);
            rethrow(e);
        end
    end
    
end
