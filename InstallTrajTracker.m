function InstallTrajTracker()
% InstallTrajTracker() - Download and install the TrajTracker toolbox
% 

    fprintf('\n');
    fprintf('   TrajTracker toolbox installation\n');
    fprintf('   ================================\n');
    
    if is_already_installed()
        return;
    end
    
    fprintf('Please enter the directory under which you plan to store all your TrajTracker results.\n');
    fprintf('Each data directory in TrajTracker is defined by its location relatively to this base directory.\n');
    
    root_path = '';
    ok = false;
    while ~ok
        root_path = input('Root data path (default = /): ', 's');
        if isempty(root_path)
            root_path = '/';
        end
        if exist(root_path, 'dir')
            ok = true;
        else
            fprintf('This directory does not exist\n');
        end
    end
    
    toolbox_filename = 'TrajTrackerAnalyze.mltbx';
    toolbox_url = ['https://github.com/trajtracker/trajtracker_analyze/raw/master/' toolbox_filename];
    local_filename = [tempdir '/' toolbox_filename];
    
    fprintf('Downloading latest version of TrajTracker...\n');
    websave(local_filename, toolbox_url);
    fprintf('Done.\n\n');
    
    fprintf('Installing toolbox...\n');
    toolbox = matlab.addons.toolbox.installToolbox(local_filename, true);
    
    fprintf('%s version %s was installed\n\n', toolbox.Name, toolbox.Version);
    
    ttrk_dir = get_toolbox_dir();
    fprintf('The TrajTracker toolbox was installed in %s\n', ttrk_dir);
    
    create_root_path_func(ttrk_dir, root_path);
    
    fprintf('\n\nSuccessfully installed TrajTracker\n');
    fprintf('\nFor more information, visit us at http://www.trajtracker.com\n');
    
    %------------------------------------------------------------------
    function installed = is_already_installed()
        
        installed = false;
        for tbx = matlab.addons.toolbox.installedToolboxes()
            if strcmp(tbx.Name, 'TrajTracker Analyze')
                fprintf('TrajTracker Analyze version %s is already installed.\n', tbx.Version);
                
                answer = '';
                while ~ismember(answer, {'U', 'C'})
                    answer = upper(input('Do you want to (U)install it or (C)ancel? ', 's'));
                end
                
                if answer == 'U'
                    % Uninstall
                    matlab.addons.toolbox.uninstallToolbox(tbx);
                    fprintf('The previous version was uninstalled\n\n\n');
                    break;
                else
                    % Cancel
                    installed = true;
                end
                
            end
        end
        
    end

    %------------------------------------------------------------------
    function d = get_toolbox_dir()
        d = fileparts(which('NLExperimentData'));
        if isempty(d)
            error('The installation seems to have succeeded but I could not locate the installation directory');
        end
    end

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
