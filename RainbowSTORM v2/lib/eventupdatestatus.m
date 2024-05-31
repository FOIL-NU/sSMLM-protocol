classdef eventupdatestatus < event.EventData
    properties
        status = '';
    end

    methods
        function data = eventupdatestatus(status)
            data.status = status;
        end
    end
end