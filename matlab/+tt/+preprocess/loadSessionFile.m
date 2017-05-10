function session = loadSessionFile(filename)
% session = loadSessionFile(filename) - Load a session metadata file (XML),
% without the trial data.
% 
% Return a SessionInf object.

    [subDir, bn] = tt.preprocess.parsePath(filename);
    session = tt.preprocess.SessionInf(subDir, bn);
    
    xml = xml2struct(filename);
    session.xmlData = xml.data;
    
    if isfield(session.xmlData, 'source')
        %-- New format (TrajTracker @ Expyriment)
        tt.preprocess.parseSessionFile_ttrk(session)
    else
        %-- Old format (iPad app)
        tt.preprocess.parseSessionFile_ipad(session)
    end

end

