function value = getXmlAttr(xml, attrName, entityDesc, filename)

    if ~isfield(xml, 'Attributes')
        error('Invalid session file (%s): no attributes on <%s> block', filename, entityDesc);
    end
    if ~isfield(xml.Attributes, attrName)
        error('Invalid session file (%s): no attribute "%s" on <%s> block', filename, attrName, entityDesc);
    end

    value = xml.Attributes.(attrName);

end
