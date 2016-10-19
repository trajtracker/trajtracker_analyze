function [bname,dname] = basename(fullpath)
% [bname,dname] = BASENAME(fullPath) - split path into file+directory name
% Glenn Thompson March 2003

    i1=strfind(fullpath,'\');
    i2=strfind(fullpath,'/');
    if isempty([i1 i2])
        bname = fullpath;
        dname = '';
        return;
    end
    i = sort([i1 i2]);
    lasti=length(i);
    l0=i(lasti);
    l1=length(fullpath);
    bname=fullpath(l0+1:l1);
    dname=fullpath(1:l0-1);

end

