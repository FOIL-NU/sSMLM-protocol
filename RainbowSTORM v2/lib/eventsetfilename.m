classdef eventsetfilename < event.EventData
    properties
        filename = '';
    end

    methods
        function data = eventsetfilename(filename)
            data.filename = filename;
        end
    end
end