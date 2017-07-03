function tb_path = toolboxPath()
%dirName = toolboxPath() - return the root path of the TrajTracker toolbox

    tb_path = fileparts(mfilename('fullpath'));
    tb_path = fileparts(tb_path);
    tb_path = fileparts(tb_path);
    
end

