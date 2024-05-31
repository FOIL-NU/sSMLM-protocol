classdef eventupdatecolorranges < event.EventData
    properties
        enabled_colors
        num_enabled
        range_wavelengths
        range_contrasts
        color_names
        legend_location
        scalebar_location
        color_img
    end

    methods
        function data = eventupdatecolorranges(num_enabled, enabled_colors, range_wavelengths, range_contrasts, color_names, legend_location, scalebar_location, color_img)
            data.enabled_colors = enabled_colors;
            data.range_wavelengths = range_wavelengths;
            data.range_contrasts = range_contrasts;
            data.num_enabled = num_enabled;
            data.color_names = color_names;
            data.legend_location = legend_location;
            data.scalebar_location = scalebar_location;
            data.color_img = color_img;
        end
    end
end