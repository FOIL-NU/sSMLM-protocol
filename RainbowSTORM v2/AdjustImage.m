classdef AdjustImage < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                matlab.ui.Figure
        GridLayout              matlab.ui.container.GridLayout
            CloseButton             matlab.ui.control.Button
        TabGroup                matlab.ui.container.TabGroup
            ColorTab                matlab.ui.container.Tab
            ColorTabLayout          matlab.ui.container.GridLayout
                Slider7Label            matlab.ui.control.DropDown
                Slider6Label            matlab.ui.control.DropDown
                Slider5Label            matlab.ui.control.DropDown
                Slider4Label            matlab.ui.control.DropDown
                Slider3Label            matlab.ui.control.DropDown
                Slider2Label            matlab.ui.control.DropDown
                Slider1Label            matlab.ui.control.DropDown

                % New sliders for R2023b, commented out for compatibility
                Slider7                 % matlab.ui.control.RangeSlider
                Slider6                 % matlab.ui.control.RangeSlider
                Slider5                 % matlab.ui.control.RangeSlider
                Slider4                 % matlab.ui.control.RangeSlider
                Slider3                 % matlab.ui.control.RangeSlider
                Slider2                 % matlab.ui.control.RangeSlider
                Slider1                 % matlab.ui.control.RangeSlider

                % Older sliders for versions older than R2023b
                Slider7Max              matlab.ui.control.Slider
                Slider6Max              matlab.ui.control.Slider
                Slider5Max              matlab.ui.control.Slider
                Slider4Max              matlab.ui.control.Slider
                Slider3Max              matlab.ui.control.Slider
                Slider2Max              matlab.ui.control.Slider
                Slider1Max              matlab.ui.control.Slider
                Slider7Min              matlab.ui.control.Slider
                Slider6Min              matlab.ui.control.Slider
                Slider5Min              matlab.ui.control.Slider
                Slider4Min              matlab.ui.control.Slider
                Slider3Min              matlab.ui.control.Slider
                Slider2Min              matlab.ui.control.Slider
                Slider1Min              matlab.ui.control.Slider

                ColorUIAxes             matlab.ui.control.UIAxes
            
            ContrastTab            matlab.ui.container.Tab
            ContrastTabLayout      matlab.ui.container.GridLayout
                ContrastSlider7Label    matlab.ui.control.Label
                ContrastSlider6Label    matlab.ui.control.Label
                ContrastSlider5Label    matlab.ui.control.Label
                ContrastSlider4Label    matlab.ui.control.Label
                ContrastSlider3Label    matlab.ui.control.Label
                ContrastSlider2Label    matlab.ui.control.Label
                ContrastSlider1Label    matlab.ui.control.Label

                % New sliders for R2023b, commented out for compatibility
                ContrastSlider7         % matlab.ui.control.RangeSlider
                ContrastSlider6         % matlab.ui.control.RangeSlider
                ContrastSlider5         % matlab.ui.control.RangeSlider
                ContrastSlider4         % matlab.ui.control.RangeSlider
                ContrastSlider3         % matlab.ui.control.RangeSlider
                ContrastSlider2         % matlab.ui.control.RangeSlider
                ContrastSlider1         % matlab.ui.control.RangeSlider

                % Older sliders for versions older than R2023b
                ContrastSlider7Max      matlab.ui.control.Slider
                ContrastSlider6Max      matlab.ui.control.Slider
                ContrastSlider5Max      matlab.ui.control.Slider
                ContrastSlider4Max      matlab.ui.control.Slider
                ContrastSlider3Max      matlab.ui.control.Slider
                ContrastSlider2Max      matlab.ui.control.Slider
                ContrastSlider1Max      matlab.ui.control.Slider
                ContrastSlider7Min      matlab.ui.control.Slider
                ContrastSlider6Min      matlab.ui.control.Slider
                ContrastSlider5Min      matlab.ui.control.Slider
                ContrastSlider4Min      matlab.ui.control.Slider
                ContrastSlider3Min      matlab.ui.control.Slider
                ContrastSlider2Min      matlab.ui.control.Slider
                ContrastSlider1Min      matlab.ui.control.Slider

                ContrastUIAxes          matlab.ui.control.UIAxes

            LabelsTab              matlab.ui.container.Tab
            LabelsTabLayout        matlab.ui.container.GridLayout
                LabelsNamesPanel        matlab.ui.container.Panel
                LabelsNamesLayout       matlab.ui.container.GridLayout
                    Slider7NameEditField    matlab.ui.control.EditField
                    Slider6NameEditField    matlab.ui.control.EditField
                    Slider5NameEditField    matlab.ui.control.EditField
                    Slider4NameEditField    matlab.ui.control.EditField
                    Slider3NameEditField    matlab.ui.control.EditField
                    Slider2NameEditField    matlab.ui.control.EditField
                    Slider1NameEditField    matlab.ui.control.EditField
                    Slider1NameEditFieldLabel  matlab.ui.control.Label
                    Slider2NameEditFieldLabel  matlab.ui.control.Label
                    Slider3NameEditFieldLabel  matlab.ui.control.Label
                    Slider4NameEditFieldLabel  matlab.ui.control.Label
                    Slider5NameEditFieldLabel  matlab.ui.control.Label
                    Slider6NameEditFieldLabel  matlab.ui.control.Label
                    Slider7NameEditFieldLabel  matlab.ui.control.Label
                LabelsPositionsPanel    matlab.ui.container.Panel
                LabelsPositionsLayout   matlab.ui.container.GridLayout
                    ScalebarDropdown        matlab.ui.control.DropDown
                    ScalebarDropdownLabel   matlab.ui.control.Label
                    LegendDropdown          matlab.ui.control.DropDown
                    LegendDropdownLabel     matlab.ui.control.Label
    end

    properties (Access = private)
        HistogramData
        WavelengthLimits    % to be intialized in the startupFcn
        SliderValues    % to be intialized in the startupFcn
        SliderContrasts % to be intialized in the startupFcn
        
        SliderTags = "";
        SliderLabels = "Gray";
        SliderColors = [1,1,1];
        SliderColorsRGB = [0,0,0];

        SliderItems = ["Red", "Green", "Blue", "Cyan", "Magenta", "Yellow", "Gray"];
        SliderItemsColors = [1,0,0; 0,1,0; 0,0,1; 0,1,1; 1,0,1; 1,1,0; 1,1,1];
        SliderItemsColorsRGB = [1,0,0; 0,1,0; 0,0,1; 0,1,1; 1,0,1; 1,1,0; 0,0,0];

        ImageData
        ImageSizeX
        ImageSizeY
        PixelSize
        ColorImageReady = false;
        ColorImage

        MaximumNumberSliders = 7;
        NumberEnabledSliders = 1;
        XRegion1
        XRegion2
        XRegion3
        XRegion4
        XRegion5
        XRegion6
        XRegion7

        ContrastXRegion1
        ContrastXRegion2
        ContrastXRegion3
        ContrastXRegion4
        ContrastXRegion5
        ContrastXRegion6
        ContrastXRegion7

        CentroidTable
    end

    % Functions for the app
    methods (Access = private)
        function getHistogramLimits(app)
            app.HistogramData = histcounts(app.CentroidTable{:,1}, 200);
            app.WavelengthLimits = [floor(round(min(app.CentroidTable{:,1}),-1)), ceil(round(max(app.CentroidTable{:,1}),-1))];
            tempslidervalues = round(linspace(app.WavelengthLimits(1)/2, app.WavelengthLimits(end)/2, app.MaximumNumberSliders+1));
            tempslidervalues = repelem(tempslidervalues, 2);
            app.SliderValues = reshape(tempslidervalues(2:end-1), 2, app.MaximumNumberSliders)';
            app.SliderContrasts = repmat([0,10], app.MaximumNumberSliders, 1);
        end

        function getSliderLabels(app)
            sliderlabels_temp = strings(app.NumberEnabledSliders,1);
            for iSlider = 1:app.NumberEnabledSliders
                sliderlabels_temp(iSlider) = app.SliderItems{all(app.SliderColors(iSlider,:) == app.SliderItemsColors, 2)};
            end
            app.SliderLabels = sliderlabels_temp;
        end

        function getSliderColorsRGB(app)
            slidercolors_temp = zeros(app.NumberEnabledSliders, 3);
            for iSlider = 1:app.NumberEnabledSliders
                slidercolors_temp(iSlider,:) = app.SliderItemsColorsRGB(strcmpi(app.SliderLabels(iSlider), app.SliderItems),:);
            end
            app.SliderColorsRGB = slidercolors_temp;
        end

        function drawHistogram(app)
            histogram(app.ColorUIAxes, app.CentroidTable{:,1}, 200, 'FaceColor', 'black');
            app.ColorUIAxes.XLim = app.WavelengthLimits;
        end

        function initializeRegions(app)
            defaultColors = [0,0,0; 1,0,0; 0,1,0; 0,0,1; 0,1,1; 1,0,1; 1,1,0];

            for iSlider = 1:app.MaximumNumberSliders
                if isMATLABReleaseOlderThan('R2023a')
                    % xregion is not available in R2022b and older, so we use patch instead
                    % get the y limits of the histogram
                    ylimits = app.ColorUIAxes.YLim;
                    app.(['XRegion', num2str(iSlider)]) = patch(app.ColorUIAxes, [app.SliderValues(iSlider), app.SliderValues(iSlider+1), app.SliderValues(iSlider+1), app.SliderValues(iSlider)], [ylimits(1), ylimits(1), ylimits(end), ylimits(end)], defaultColors(iSlider,:), 'FaceAlpha', 0.3, 'EdgeColor', 'none');
                else
                    app.(['XRegion', num2str(iSlider)]) = xregion(app.ColorUIAxes, app.SliderValues(iSlider), app.SliderValues(iSlider+1), 'FaceAlpha', 0.3, 'FaceColor', defaultColors(iSlider,:));
                end
            end
        end

        function initializeContrastRegions(app)
            defaultColors = [0,0,0; 1,0,0; 0,1,0; 0,0,1; 0,1,1; 1,0,1; 1,1,0];

            for iSlider = 1:app.MaximumNumberSliders
                if isMATLABReleaseOlderThan('R2023a')
                    % xregion is not available in R2022b and older, so we use patch instead
                    % get the y limits of the histogram
                    ylimits = app.ContrastUIAxes.YLim;
                    app.(['ContrastXRegion', num2str(iSlider)]) = patch(app.ContrastUIAxes, [app.SliderContrasts(iSlider,1), app.SliderContrasts(iSlider,2), app.SliderContrasts(iSlider,2), app.SliderContrasts(iSlider,1)], [ylimits(1), ylimits(1), ylimits(end), ylimits(end)], defaultColors(iSlider,:), 'FaceAlpha', 0.3, 'EdgeColor', 'none');
                else
                    app.(['ContrastXRegion', num2str(iSlider)]) = xregion(app.ContrastUIAxes, app.SliderContrasts(iSlider,1), app.SliderContrasts(iSlider,2), 'FaceAlpha', 0.3, 'FaceColor', defaultColors(iSlider,:));
                end
            end
        end

        function setWavelengthLimits(app)
            if isMATLABReleaseOlderThan('R2023b')
                for iSlider = 1:app.MaximumNumberSliders
                    app.(['Slider', num2str(iSlider), 'Min']).Limits = app.WavelengthLimits;
                    app.(['Slider', num2str(iSlider), 'Max']).Limits = app.WavelengthLimits;
                end
            else
                for iSlider = 1:app.MaximumNumberSliders
                    app.(['Slider', num2str(iSlider)]).Limits = app.WavelengthLimits;
                end
            end
        end

        function setSliderValues(app)
            if isMATLABReleaseOlderThan('R2023b')
                for iSlider = 1:app.MaximumNumberSliders
                    app.(['Slider', num2str(iSlider), 'Min']).Value = app.SliderValues(iSlider,1);
                    app.(['Slider', num2str(iSlider), 'Max']).Value = app.SliderValues(iSlider,2);
                end
            else
                for iSlider = 1:app.MaximumNumberSliders
                    app.(['Slider', num2str(iSlider)]).Value = app.SliderValues(iSlider,:);
                end
            end
        end

        function setSliderLabels(app)
            for iSlider = 1:app.MaximumNumberSliders
                if iSlider <= app.NumberEnabledSliders
                    app.(['Slider', num2str(iSlider), 'Label']).Value = app.SliderLabels(iSlider);
                    app.(['ContrastSlider', num2str(iSlider), 'Label']).Text = app.SliderLabels(iSlider);
                    app.(['Slider', num2str(iSlider), 'NameEditFieldLabel']).Text = app.SliderLabels(iSlider);
                else
                    app.(['Slider', num2str(iSlider), 'Label']).Value = '';
                    app.(['ContrastSlider', num2str(iSlider), 'Label']).Text = '';
                    app.(['Slider', num2str(iSlider), 'NameEditFieldLabel']).Text = '';
                end
            end
        end

        function setEditFieldValues(app)
            for iSlider = 1:app.NumberEnabledSliders
                app.(['Slider', num2str(iSlider), 'NameEditField']).Value = app.SliderTags(iSlider);
            end
        end

        function getColorImage(app)
            color_image = nan(length(app.ImageSizeX)-1, length(app.ImageSizeY)-1, app.NumberEnabledSliders);

            for icol = 1:app.NumberEnabledSliders
                idx = app.CentroidTable{:, 1} >= app.SliderValues(icol,1) & app.CentroidTable{:, 1} <= app.SliderValues(icol,2);
                x = app.ImageData{idx, 'x [nm]'};
                y = app.ImageData{idx, 'y [nm]'};

                color_image_temp = ash2(x, y, app.PixelSize, app.ImageSizeX, app.ImageSizeY);
                color_image_min = min(color_image_temp(:));
                color_image_max = prctile(color_image_temp(:), 99.9) * 2;
                % set the ContrastSlider limits to the min and max of the color_image_temp
                if isMATLABReleaseOlderThan('R2023b')
                    app.(['ContrastSlider', num2str(icol), 'Min']).Limits = [color_image_min, color_image_max];
                    app.(['ContrastSlider', num2str(icol), 'Max']).Limits = [color_image_min, color_image_max];
                else
                    app.(['ContrastSlider', num2str(icol)]).Limits = [color_image_min, color_image_max];
                end
                
                color_image(:,:,icol) = color_image_temp;
            end

            app.ColorImage = color_image;
        end

        function setEnabledSlidersandLabels(app)
            % make sure that we have one additional sliderLabel enabled at all times so that we can use it to add more sliders.
            for iSlider = 1:app.MaximumNumberSliders
                if iSlider <= app.NumberEnabledSliders
                    if isMATLABReleaseOlderThan('R2023b')
                        app.(['Slider', num2str(iSlider), 'Min']).Enable = 'on';
                        app.(['Slider', num2str(iSlider), 'Max']).Enable = 'on';
                        app.(['ContrastSlider', num2str(iSlider), 'Min']).Enable = 'on';
                        app.(['ContrastSlider', num2str(iSlider), 'Max']).Enable = 'on';
                    else
                        app.(['Slider', num2str(iSlider)]).Enable = 'on';
                        app.(['ContrastSlider', num2str(iSlider)]).Enable = 'on';
                    end
                    app.(['XRegion', num2str(iSlider)]).Visible = 'on';
                    app.(['Slider', num2str(iSlider), 'NameEditField']).Enable = 'on';
                    app.(['Slider', num2str(iSlider), 'NameEditFieldLabel']).Enable = 'on';
                    app.(['ContrastSlider', num2str(iSlider), 'Label']).Enable = 'on';
                else
                    if isMATLABReleaseOlderThan('R2023b')
                        app.(['Slider', num2str(iSlider), 'Min']).Enable = 'off';
                        app.(['Slider', num2str(iSlider), 'Max']).Enable = 'off';
                        app.(['ContrastSlider', num2str(iSlider), 'Min']).Enable = 'off';
                        app.(['ContrastSlider', num2str(iSlider), 'Max']).Enable = 'off';
                    else
                        app.(['Slider', num2str(iSlider)]).Enable = 'off';
                        app.(['ContrastSlider', num2str(iSlider)]).Enable = 'off';
                    end
                    app.(['XRegion', num2str(iSlider)]).Visible = 'off';
                    app.(['Slider', num2str(iSlider), 'NameEditField']).Enable = 'off';
                    app.(['Slider', num2str(iSlider), 'NameEditFieldLabel']).Enable = 'off';
                    app.(['ContrastSlider', num2str(iSlider), 'Label']).Enable = 'off';
                end

                if iSlider <= app.NumberEnabledSliders + 1
                    app.(['Slider', num2str(iSlider), 'Label']).Enable = 'on';
                else
                    app.(['Slider', num2str(iSlider), 'Label']).Enable = 'off';
                end
            end
        end

        function updateXRegionColors(app)
            for iSlider = 1:app.NumberEnabledSliders
                app.(['XRegion', num2str(iSlider)]).FaceColor = app.SliderColorsRGB(iSlider,:);
            end
        end

        function updateXRegionValues(app)
            if isMATLABReleaseOlderThan('R2023a')
                for iSlider = 1:app.NumberEnabledSliders
                    % xregion is not available in R2022b and older, so we use patch instead
                    app.(['XRegion', num2str(iSlider)]).XData = [app.SliderValues(iSlider,1), app.SliderValues(iSlider,end), app.SliderValues(iSlider,end), app.SliderValues(iSlider,1)];
                end
            else
                for iSlider = 1:app.NumberEnabledSliders
                    app.(['XRegion', num2str(iSlider)]).Value = app.SliderValues(iSlider,:);
                end
            end
        end

        function guessPeaks(app)
            windowSize = 5;
            peakThreshold = 300;
            
            % Smooth the data using a moving average
            smoothedData = smoothdata(app.HistogramData, 'movmean', windowSize);

            % Count the number of peaks in the smoothed data
            numPeaks = sum(diff(sign(diff(smoothedData)-peakThreshold))>0);

            if numPeaks > app.MaximumNumberSliders
                numPeaks = app.MaximumNumberSliders;
            elseif numPeaks < 1
                numPeaks = 1;
            end

            app.NumberEnabledSliders = numPeaks;
        end

        function reportChanges(app)
            eventdata = eventupdatecolorranges(app.NumberEnabledSliders, app.SliderColors, app.SliderValues, app.SliderContrasts, app.SliderTags, app.LegendDropdown.Value, app.ScalebarDropdown.Value, app.ColorImage);
            notify(app, 'ColorRangesChanged', eventdata);
        end

        function generateFakeHistogram(app)
            app.CentroidTable = table(200*randn(1000,1), 'VariableNames', {'Centroid'});
            app.ImageData = table(200*randn(1000,1), 200*randn(1000,1), 'VariableNames', {'x [nm]', 'y [nm]'});
            app.drawHistogram();
        end
    end

    % Callbacks that handle component events
    methods (Access = private)
        % Code that executes after component creation
        function startupFcn(app, varargin)
            clc;

            try
                app.CentroidTable = varargin{2}(:,1);
                app.ImageData = varargin{2}(:,{'x [nm]', 'y [nm]'});
            catch
                warning('No data provided, generating fake data for the histogram');
                app.generateFakeHistogram();
            end

            app.getHistogramLimits();
            app.drawHistogram();
            app.initializeRegions();

            if nargin <= 3
                app.ImageSizeX = [min(app.CentroidTable{:, 'x [nm]'}), max(app.CentroidTable{:, 'x [nm]'})];
                app.ImageSizeY = [min(app.CentroidTable{:, 'y [nm]'}), max(app.CentroidTable{:, 'y [nm]'})];
                app.PixelSize = 100;
            else
                app.ImageSizeX = varargin{3}.image_x;
                app.ImageSizeY = varargin{3}.image_y;
                app.PixelSize = varargin{3}.pixel_size;
            end

            if nargin <= 4
                app.guessPeaks();
                if app.NumberEnabledSliders > 1
                    for iSlider = 1:app.NumberEnabledSliders
                        app.SliderTags(iSlider) = "";
                        app.SliderLabels(iSlider) = app.SliderItems{iSlider};
                        app.SliderColors(iSlider,:) = app.SliderItemsColors(iSlider,:);
                        app.SliderColorsRGB(iSlider,:) = app.SliderItemsColorsRGB(iSlider,:);
                    end
                end
            else
                colorsettings = varargin{4};
                app.NumberEnabledSliders = colorsettings.num_enabled;
                app.SliderTags = colorsettings.color_names;
                app.SliderValues = colorsettings.range_wavelengths;
                app.SliderContrasts = colorsettings.range_contrasts;
                app.SliderColors = colorsettings.enabled_colors;
                app.getSliderLabels();
                app.getSliderColorsRGB();
            end

            app.setWavelengthLimits();
            app.setSliderValues();
            
            app.setEditFieldValues();
            app.setSliderLabels();

            app.updateXRegionValues();
            app.updateXRegionColors();

            app.setEnabledSlidersandLabels();
        end

        function SliderValueChanging(app, event)
            changingValue = event.Value;
            sliderIndex = str2double(event.Source.Tag(end));

            if isMATLABReleaseOlderThan('R2023b')
                if strcmpi(event.Source.Tag(1:3), 'min')
                    changingValue = [changingValue, app.(['Slider', num2str(sliderIndex), 'Max']).Value];
                else
                    changingValue = [app.(['Slider', num2str(sliderIndex), 'Min']).Value, changingValue];
                end
                app.(['XRegion', num2str(sliderIndex)]).XData = [changingValue, changingValue, changingValue, changingValue];
            else
                app.(['XRegion', num2str(sliderIndex)]).Value = changingValue;
            end
            
            app.SliderValues(sliderIndex,:) = changingValue;
        end
        
        function SliderValueChanged(app, event)
            sliderIndex = str2double(event.Source.Tag(end));
            app.SliderValues(sliderIndex,:) = event.Value;
            app.(['XRegion', num2str(sliderIndex)]).Value = event.Value;
            app.getColorImage();
            app.reportChanges();
        end

        function SliderLabelValueChanged(app, event)
            sliderIndex = str2double(event.Source.Tag(end));
            color = event.Value;

            if (sliderIndex == app.NumberEnabledSliders + 1) && ~isempty(color)
                app.NumberEnabledSliders = app.NumberEnabledSliders + 1;
                app.SliderLabels = [app.SliderLabels; color];
                app.SliderColors = [app.SliderColors; app.SliderItemsColors(strcmpi(color, app.SliderItems),:)];
                app.SliderColorsRGB = [app.SliderColorsRGB; app.SliderItemsColorsRGB(strcmpi(color, app.SliderItems),:)];
                app.SliderTags = [app.SliderTags; ""];

                app.setSliderLabels();
                app.setEnabledSlidersandLabels();
                app.updateXRegionColors();
                app.updateXRegionValues();
                app.getColorImage();
                app.reportChanges();

            elseif isempty(color)
                app.NumberEnabledSliders = app.NumberEnabledSliders - 1;
                app.SliderLabels = app.SliderLabels([1:sliderIndex-1, sliderIndex+1:end]);
                app.SliderColors = app.SliderColors([1:sliderIndex-1, sliderIndex+1:end],:);
                app.SliderColorsRGB = app.SliderColorsRGB([1:sliderIndex-1, sliderIndex+1:end],:);
                app.SliderTags = app.SliderTags([1:sliderIndex-1, sliderIndex+1:end]);
                % move the slider values up (because this is full rank)
                app.SliderValues = app.SliderValues([1:sliderIndex-1, sliderIndex+1:end, sliderIndex],:);

                app.setWavelengthLimits();
                app.setSliderValues();
                app.setSliderLabels();

                app.setEnabledSlidersandLabels();
                app.updateXRegionColors();
                app.updateXRegionValues();
                app.getColorImage();
                app.reportChanges();

            else
                app.SliderLabels(sliderIndex) = color;
                app.SliderColors(sliderIndex,:) = app.SliderItemsColors(strcmpi(color, app.SliderItems),:);
                app.SliderColorsRGB(sliderIndex,:) = app.SliderItemsColorsRGB(strcmpi(color, app.SliderItems),:);

                app.setSliderLabels();
                app.updateXRegionColors();
                app.getColorImage();
                app.reportChanges();
            end
        end

        function ContrastSliderValueChanging(app, event)
            changingValue = event.Value;
            sliderIndex = str2double(event.Source.Tag(end));

            if isMATLABReleaseOlderThan('R2023b')
                if strcmpi(event.Source.Tag(1:3), 'min')
                    changingValue = [changingValue, app.(['ContrastSlider', num2str(sliderIndex), 'Max']).Value];
                else
                    changingValue = [app.(['ContrastSlider', num2str(sliderIndex), 'Min']).Value, changingValue];
                end
                app.(['ContrastXRegion', num2str(sliderIndex)]).XData = [changingValue, changingValue, changingValue, changingValue];
            else
                app.(['ContrastXRegion', num2str(sliderIndex)]).Value = changingValue;
            end

            app.SliderContrasts(sliderIndex,:) = changingValue;
        end

        function ContrastSliderValueChanged(app, event)
            sliderIndex = str2double(event.Source.Tag(end));
            app.SliderContrasts(sliderIndex,:) = event.Value;
            app.(['ContrastXRegion', num2str(sliderIndex)]).Value = event.Value;
            app.getColorImage();
            app.reportChanges();
        end

        function LegendDropdownValueChanged(app, ~)
            app.reportChanges();
        end

        function ScalebarDropdownValueChanged(app, ~)
            app.reportChanges();
        end

        function EditFieldValueChanged(app, event)
            sliderIndex = str2double(event.Source.Tag(end));
            app.SliderTags(sliderIndex) = event.Value;
            app.reportChanges();
        end

        function CloseButtonPushed(app, ~)
            delete(app.UIFigure);
        end

    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app, varargin)
            % pass the position if it is provided
            try
                position = varargin{1};
            catch
                position = [100, 100, 360, 450];
            end

            SliderLabelItems = [{''}, app.SliderItems];

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = position;
            app.UIFigure.Name = 'Image Settings';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {'1x'};
            app.GridLayout.RowHeight = {'1x', 25};
            app.GridLayout.ColumnSpacing = 5;
            app.GridLayout.RowSpacing = 5;

            % Create TabGroup
            app.TabGroup = uitabgroup(app.GridLayout);
            app.TabGroup.Layout.Row = 1;
            app.TabGroup.Layout.Column = 1;

            % Create ColorTab
            app.ColorTab = uitab(app.TabGroup);
            app.ColorTab.Title = 'Color';

            % Create ColorGridLayout
            app.ColorTabLayout = uigridlayout(app.ColorTab);
            app.ColorTabLayout.ColumnWidth = {80, 5, '1x', 5};
            if isMATLABReleaseOlderThan('R2023b')
                app.ColorTabLayout.RowHeight = {'1x', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit'};
            else
                app.ColorTabLayout.RowHeight = {'1x', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit'};
            end
            app.ColorTabLayout.ColumnSpacing = 0;
            app.ColorTabLayout.RowSpacing = 5;

            % Create ColorUIAxes
            app.ColorUIAxes = uiaxes(app.ColorTabLayout);
            app.ColorUIAxes.Box = 'on';
            app.ColorUIAxes.Layout.Row = 1;
            app.ColorUIAxes.Layout.Column = [1 3];

            % Generate the Sliders from 1 through 7
            if isMATLABReleaseOlderThan('R2023b')
                slidertypes = ['Min'; 'Max'];

                for iSlider = 1:app.MaximumNumberSliders
                    for iSliderType = 1:2
                        app.(['Slider', num2str(iSlider), slidertypes(iSliderType,:)]) = uislider(app.ColorTabLayout);
                        app.(['Slider', num2str(iSlider), slidertypes(iSliderType,:)]).MajorTicks = [];
                        app.(['Slider', num2str(iSlider), slidertypes(iSliderType,:)]).MinorTicks = [];
                        app.(['Slider', num2str(iSlider), slidertypes(iSliderType,:)]).Layout.Row = iSlider * 2 + 1*strcmpi(slidertypes(iSliderType,:), "Min");
                        app.(['Slider', num2str(iSlider), slidertypes(iSliderType,:)]).Layout.Column = [3 4];
                        app.(['Slider', num2str(iSlider), slidertypes(iSliderType,:)]).Tag = [slidertypes(iSliderType),'Slider', num2str(iSlider)];
                        app.(['Slider', num2str(iSlider), slidertypes(iSliderType,:)]).Enable = 'off';
                        app.(['Slider', num2str(iSlider), slidertypes(iSliderType,:)]).ValueChangingFcn = createCallbackFcn(app, @SliderValueChanging, true);
                        app.(['Slider', num2str(iSlider), slidertypes(iSliderType,:)]).ValueChangedFcn = createCallbackFcn(app, @SliderValueChanged, true);
                    end
                end

                for iSlider = 1:app.MaximumNumberSliders
                    app.(['Slider', num2str(iSlider), 'Label']) = uidropdown(app.ColorTabLayout);
                    app.(['Slider', num2str(iSlider), 'Label']).Items = SliderLabelItems;
                    app.(['Slider', num2str(iSlider), 'Label']).Layout.Column = 1;
                    app.(['Slider', num2str(iSlider), 'Label']).Layout.Row = iSlider*2 + [0,1];
                    app.(['Slider', num2str(iSlider), 'Label']).Tag = ['Slider', num2str(iSlider)];
                    if iSlider == 1
                        app.(['Slider', num2str(iSlider), 'Label']).Value = app.SliderLabels(1);
                    else
                        app.(['Slider', num2str(iSlider), 'Label']).Value = SliderLabelItems{1};
                        app.(['Slider', num2str(iSlider), 'Label']).Enable = 'off';
                    end
                    app.(['Slider', num2str(iSlider), 'Label']).ValueChangedFcn = createCallbackFcn(app, @SliderLabelValueChanged, true);
                end
            else
                for iSlider = 1:app.MaximumNumberSliders
                    app.(['Slider', num2str(iSlider)]) = uislider(app.ColorTabLayout, 'range');
                    app.(['Slider', num2str(iSlider)]).MajorTicks = [];
                    app.(['Slider', num2str(iSlider)]).MinorTicks = [];
                    app.(['Slider', num2str(iSlider)]).Layout.Row = iSlider + 1;
                    app.(['Slider', num2str(iSlider)]).Layout.Column = [3 4];
                    app.(['Slider', num2str(iSlider)]).Tag = ['Slider', num2str(iSlider)];
                    app.(['Slider', num2str(iSlider)]).Enable = 'off';
                    app.(['Slider', num2str(iSlider)]).ValueChangingFcn = createCallbackFcn(app, @SliderValueChanging, true);
                    app.(['Slider', num2str(iSlider)]).ValueChangedFcn = createCallbackFcn(app, @SliderValueChanged, true);
                end

                for iSlider = 1:app.MaximumNumberSliders
                    app.(['Slider', num2str(iSlider), 'Label']) = uidropdown(app.ColorTabLayout);
                    app.(['Slider', num2str(iSlider), 'Label']).Items = SliderLabelItems;
                    app.(['Slider', num2str(iSlider), 'Label']).Layout.Column = 1;
                    app.(['Slider', num2str(iSlider), 'Label']).Layout.Row = iSlider + 1;
                    app.(['Slider', num2str(iSlider), 'Label']).Tag = ['Slider', num2str(iSlider)];
                    if iSlider == 1
                        app.(['Slider', num2str(iSlider), 'Label']).Value = app.SliderLabels(1);
                    else
                        app.(['Slider', num2str(iSlider), 'Label']).Value = SliderLabelItems{1};
                        app.(['Slider', num2str(iSlider), 'Label']).Enable = 'off';
                    end
                    app.(['Slider', num2str(iSlider), 'Label']).ValueChangedFcn = createCallbackFcn(app, @SliderLabelValueChanged, true);
                end
            end

            % Create ContrastTab
            app.ContrastTab = uitab(app.TabGroup);
            app.ContrastTab.Title = 'Contrast';

            % Create ContrastTabLayout
            app.ContrastTabLayout = uigridlayout(app.ContrastTab);
            app.ContrastTabLayout.ColumnWidth = {80, 10, '1x', 10};
            if isMATLABReleaseOlderThan('R2023b')
                app.ContrastTabLayout.RowHeight = {'1x', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit'};
            else
                app.ContrastTabLayout.RowHeight = {'1x', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit'};
            end
            app.ContrastTabLayout.ColumnSpacing = 0;
            app.ContrastTabLayout.RowSpacing = 5;

            % Create ContrastUIAxes
            app.ContrastUIAxes = uiaxes(app.ContrastTabLayout);
            app.ContrastUIAxes.Box = 'on';
            app.ContrastUIAxes.Layout.Row = 1;
            app.ContrastUIAxes.Layout.Column = [1 4];

            % Generate the Sliders from 1 through 7
            if isMATLABReleaseOlderThan('R2023b')
                slidertypes = ['Min'; 'Max'];

                for iSlider = 1:app.MaximumNumberSliders
                    for iSliderType = 1:2
                        app.(['ContrastSlider', num2str(iSlider), slidertypes(iSliderType,:)]) = uislider(app.ContrastTabLayout);
                        app.(['ContrastSlider', num2str(iSlider), slidertypes(iSliderType,:)]).MajorTicks = [];
                        app.(['ContrastSlider', num2str(iSlider), slidertypes(iSliderType,:)]).MinorTicks = [];
                        app.(['ContrastSlider', num2str(iSlider), slidertypes(iSliderType,:)]).Layout.Row = iSlider * 2 + 1*strcmpi(slidertypes(iSliderType,:), "Min");
                        app.(['ContrastSlider', num2str(iSlider), slidertypes(iSliderType,:)]).Layout.Column = 3;
                        app.(['ContrastSlider', num2str(iSlider), slidertypes(iSliderType,:)]).Tag = [slidertypes(iSliderType),'Slider', num2str(iSlider)];
                        app.(['ContrastSlider', num2str(iSlider), slidertypes(iSliderType,:)]).Enable = 'off';
                        app.(['ContrastSlider', num2str(iSlider), slidertypes(iSliderType,:)]).ValueChangingFcn = createCallbackFcn(app, @ContrastSliderValueChanging, true);
                        app.(['ContrastSlider', num2str(iSlider), slidertypes(iSliderType,:)]).ValueChangedFcn = createCallbackFcn(app, @ContrastSliderValueChanged, true);
                    end
                end

                for iSlider = 1:app.MaximumNumberSliders
                    app.(['ContrastSlider', num2str(iSlider), 'Label']) = uilabel(app.ContrastTabLayout);
                    app.(['ContrastSlider', num2str(iSlider), 'Label']).HorizontalAlignment = 'right';
                    app.(['ContrastSlider', num2str(iSlider), 'Label']).Layout.Column = 1;
                    app.(['ContrastSlider', num2str(iSlider), 'Label']).Layout.Row = iSlider*2 + [0,1];
                end
            else
                for iSlider = 1:app.MaximumNumberSliders
                    app.(['ContrastSlider', num2str(iSlider)]) = uislider(app.ContrastTabLayout, 'range');
                    app.(['ContrastSlider', num2str(iSlider)]).MajorTicks = [];
                    app.(['ContrastSlider', num2str(iSlider)]).MinorTicks = [];
                    app.(['ContrastSlider', num2str(iSlider)]).Layout.Row = iSlider + 1;
                    app.(['ContrastSlider', num2str(iSlider)]).Layout.Column = 3;
                    app.(['ContrastSlider', num2str(iSlider)]).Tag = ['Slider', num2str(iSlider)];
                    app.(['ContrastSlider', num2str(iSlider)]).Enable = 'off';
                    app.(['ContrastSlider', num2str(iSlider)]).ValueChangingFcn = createCallbackFcn(app, @ContrastSliderValueChanging, true);
                    app.(['ContrastSlider', num2str(iSlider)]).ValueChangedFcn = createCallbackFcn(app, @ContrastSliderValueChanged, true);
                end

                for iSlider = 1:app.MaximumNumberSliders
                    app.(['ContrastSlider', num2str(iSlider), 'Label']) = uilabel(app.ContrastTabLayout);
                    app.(['ContrastSlider', num2str(iSlider), 'Label']).HorizontalAlignment = 'right';
                    app.(['ContrastSlider', num2str(iSlider), 'Label']).Layout.Column = 1;
                    app.(['ContrastSlider', num2str(iSlider), 'Label']).Layout.Row = iSlider + 1;
                end
            end

            % Create LabelsTab
            app.LabelsTab = uitab(app.TabGroup);
            app.LabelsTab.Title = 'Labels';

            % Create LabelsTabLayout
            app.LabelsTabLayout = uigridlayout(app.LabelsTab);
            app.LabelsTabLayout.ColumnWidth = {'1x'};
            app.LabelsTabLayout.RowHeight = {'1x', '3x'};

            % Create LabelsPositionsPanel
            app.LabelsPositionsPanel = uipanel(app.LabelsTabLayout);
            app.LabelsPositionsPanel.Title = 'Positions';
            app.LabelsPositionsPanel.Layout.Row = 1;
            app.LabelsPositionsPanel.Layout.Column = 1;

            % Create LabelsPositionsLayout
            app.LabelsPositionsLayout = uigridlayout(app.LabelsPositionsPanel);
            app.LabelsPositionsLayout.ColumnWidth = {40, '1x', '3x', 40};
            app.LabelsPositionsLayout.RowHeight = {'1x', '1x'};
            app.LabelsPositionsLayout.Padding = [10, 10, 10, 10];

            % Create LegendDropdownLabel
            app.LegendDropdownLabel = uilabel(app.LabelsPositionsLayout);
            app.LegendDropdownLabel.HorizontalAlignment = 'right';
            app.LegendDropdownLabel.Layout.Row = 1;
            app.LegendDropdownLabel.Layout.Column = [1 2];
            app.LegendDropdownLabel.Text = 'Legend';

            % Create LegendDropdown
            app.LegendDropdown = uidropdown(app.LabelsPositionsLayout);
            app.LegendDropdown.Items = {'', 'Top Left', 'Top Right', 'Bottom Left', 'Bottom Right'};
            app.LegendDropdown.Layout.Row = 1;
            app.LegendDropdown.Layout.Column = 3;
            app.LegendDropdown.Value = '';
            app.LegendDropdown.ValueChangedFcn = createCallbackFcn(app, @LegendDropdownValueChanged, true);

            % Create ScalebarDropdownLabel
            app.ScalebarDropdownLabel = uilabel(app.LabelsPositionsLayout);
            app.ScalebarDropdownLabel.HorizontalAlignment = 'right';
            app.ScalebarDropdownLabel.Layout.Row = 2;
            app.ScalebarDropdownLabel.Layout.Column = [1 2];
            app.ScalebarDropdownLabel.Text = 'Scalebar';

            % Create ScalebarDropdown
            app.ScalebarDropdown = uidropdown(app.LabelsPositionsLayout);
            app.ScalebarDropdown.Items = {'', 'Top Left', 'Top Right', 'Bottom Left', 'Bottom Right'};
            app.ScalebarDropdown.Layout.Row = 2;
            app.ScalebarDropdown.Layout.Column = 3;
            app.ScalebarDropdown.Value = '';
            app.ScalebarDropdown.ValueChangedFcn = createCallbackFcn(app, @ScalebarDropdownValueChanged, true);
            
            % Create LabelsNamesPanel
            app.LabelsNamesPanel = uipanel(app.LabelsTabLayout);
            app.LabelsNamesPanel.Title = 'Label Names';
            app.LabelsNamesPanel.Layout.Row = 2;
            app.LabelsNamesPanel.Layout.Column = 1;

            % Create LabelsNamesLayout
            app.LabelsNamesLayout = uigridlayout(app.LabelsNamesPanel);
            app.LabelsNamesLayout.ColumnWidth = {'1x', '3x'};
            app.LabelsNamesLayout.RowHeight = {'1x', '1x', '1x', '1x', '1x', '1x', '1x'};
            app.LabelsNamesLayout.Padding = [50, 10, 50, 10];

            % Genearate the EditFields from 1 through 7
            for iSlider = 1:app.MaximumNumberSliders
                app.(['Slider', num2str(iSlider), 'NameEditField']) = uieditfield(app.LabelsNamesLayout, 'text');
                app.(['Slider', num2str(iSlider), 'NameEditField']).Layout.Row = iSlider;
                app.(['Slider', num2str(iSlider), 'NameEditField']).Layout.Column = 2;
                app.(['Slider', num2str(iSlider), 'NameEditField']).Tag = ['Slider', num2str(iSlider)];
                app.(['Slider', num2str(iSlider), 'NameEditField']).ValueChangedFcn = createCallbackFcn(app, @EditFieldValueChanged, true);

                app.(['Slider', num2str(iSlider), 'NameEditFieldLabel']) = uilabel(app.LabelsNamesLayout);
                app.(['Slider', num2str(iSlider), 'NameEditFieldLabel']).HorizontalAlignment = 'right';
                app.(['Slider', num2str(iSlider), 'NameEditFieldLabel']).Layout.Row = iSlider;
                app.(['Slider', num2str(iSlider), 'NameEditFieldLabel']).Layout.Column = 1;
            end
            
            % Create CloseButton
            app.CloseButton = uibutton(app.GridLayout, 'push');
            app.CloseButton.Layout.Row = 2;
            app.CloseButton.Layout.Column = 1;
            app.CloseButton.Text = 'Close';
            app.CloseButton.ButtonPushedFcn = createCallbackFcn(app, @CloseButtonPushed, true);

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = AdjustImage(varargin)

            % Create UIFigure and components
            createComponents(app, varargin{:})

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app) startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end

    % Event handling
    events
        ColorRangesChanged
    end
end