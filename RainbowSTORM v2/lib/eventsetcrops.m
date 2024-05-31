classdef eventsetcrops < event.EventData
    properties
        crops = nan(1,4);
    end

    methods
        function data = eventsetcrops(value)
            if numel(value) == 4
                data.crops = value;
            else
                error('Crops must be a 4-element vector');
            end
        end
    end
end