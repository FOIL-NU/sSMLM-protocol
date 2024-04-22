classdef ImageViewer < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                    matlab.ui.Figure
        GridLayout                  matlab.ui.container.GridLayout
        AdjustImageButton           matlab.ui.control.Button
        DriftCorrectionButton       matlab.ui.control.Button
        SaveImageButton             matlab.ui.control.Button
        UIAxes                      matlab.ui.control.UIAxes
    end

    properties (Access = public)
        OutputImage
        ColorImage
        EnabledColorsRGB
        WavelengthLimits
        NumberEnabledChannels
        EnabledColorNames
        ContrastLimits
        LegendLocation
        ScalebarLocation
        ColorImageSet = false;
        LocalizationTable
        Image_binsize = 20;
        Image_x
        Image_y
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, tbl)
            if nargin < 2
                % get the user to pick a file
                [file, path] = uigetfile('*.csv', 'Select a localization file to load');
                if isequal(file,0) || isequal(path,0)
                    return;
                end

                tbl = readtable(fullfile(path, file), 'preservevariablenames', true);

                % tbl = table([], [], [], [], 'VariableNames', {'frame', 'x [nm]', 'y [nm]', 'centroid [nm]'});
            end

            % Create a new table for the localization data
            app.LocalizationTable = tbl(:, {'frame', 'x [nm]', 'y [nm]', 'centroid [nm]'});

            if isempty(app.LocalizationTable)
                return;
            end

            % Load the image
            [app.OutputImage, app.Image_x, app.Image_y] = ash2(app.LocalizationTable{:,'x [nm]'}, app.LocalizationTable{:, 'y [nm]'}, app.Image_binsize);
            % Resize the UIFigure to accommodate the image
            app.UIFigure.Position(3:4) = round(size(app.OutputImage) .* (640 ./ size(app.OutputImage,1))) + [0, 150];

            app.loadImage();
        end

        % Button pushed function: AdjustImageButton
        function AdjustImageButtonPushed(app, ~)
            % Calculate the position to open the color histogram app
            pos = app.UIFigure.Position;
            pos(1) = pos(1) + pos(3) + 5;
            pos(3:4) = [360, 450];

            imagesettings.enabled_colors = app.EnabledColorsRGB;
            imagesettings.range_wavelengths = app.WavelengthLimits;
            imagesettings.range_contrasts = app.ContrastLimits;
            imagesettings.num_enabled = app.NumberEnabledChannels;
            imagesettings.color_names = app.EnabledColorNames;
            imagesettings.legend_location = app.LegendLocation;
            imagesettings.scalebar_location = app.ScalebarLocation;

            imageparameters.image_x = app.Image_x;
            imageparameters.image_y = app.Image_y;
            imageparameters.pixel_size = app.Image_binsize;

            if app.ColorImageSet
                colorhistogram = AdjustImage(pos, app.LocalizationTable(:,{'centroid [nm]','x [nm]','y [nm]'}), imageparameters, imagesettings);
            else
                colorhistogram = AdjustImage(pos, app.LocalizationTable(:,{'centroid [nm]','x [nm]','y [nm]'}), imageparameters);
            end

            % add a listener event to the colorhistogram app to update the image
            addlistener(colorhistogram, 'ColorRangesChanged', @(src, event) colorRangesChanged(app, event));
        end

        % Button pushed function: IntensityHistogramButton
        function IntensityHistogramButtonPushed(app, ~)
            % Calculate the position to open the LUT histogram app
            pos = app.UIFigure.Position;
            pos(1) = pos(1) + pos(3) + 5;
            pos(2) = pos(2) + 405;
            pos(3:4) = [320, 400];

            if isempty(app.ColorImage)
                sz = 0;
            else
                sz = size(app.ColorImage, 3);
            end
            % create the intensity histograms using histcounts
            intensities = zeros(256, sz+1);
            for icol = 1:size(app.ColorImage, 3)
                intensities(:,icol) = histcounts(app.ColorImage(:,:,icol), 256, 'binmethod', 'integers','binlimits', [0, 255]);
            end
            intensities(:,end) = histcounts(app.OutputImage, 256, 'binmethod', 'integers','binlimits', [0, 255], 'Normalization', 'probability');

            intensityhistogram = IntensityHistogram(intensities, pos);
            % add a listener event to the intensityhistogram app to update the image
            addlistener(intensityhistogram, 'ColorRangesChanged', @(src, event) colorRangesChanged(app, event));
        end

        % Button pushed function: DriftCorrectionButton
        function DriftCorrectionButtonPushed(app, ~)
            driftCorrection(app);
        end

        % Button pushed function: SaveImageButton
        function SaveImageButtonPushed(app, ~)
            % open a dialog to save the image
            [file,path] = uiputfile('*.png', 'Save Image As');
            if isequal(file,0) || isequal(path,0)
                return;
            end

            % bring the window to the front
            figure(app.UIFigure);

            imwrite(app.OutputImage, fullfile(path, file));
        end
    end

    % Functions for the app
    methods (Access = private)
        function loadImage(app)
            cla(app.UIAxes);
            imshow(app.OutputImage, 'Parent', app.UIAxes);
            axis(app.UIAxes, 'image');
        end

        function driftCorrection(app, N)
            if nargin < 2
                N = 6;
            end
            
            % Determine the number of frames per time interval
            maxFrame = max(app.LocalizationTable{:, 'frame'});
            framesPerInterval = ceil(maxFrame / N);
            
            % Initialize arrays to store drift values
            drift_x = zeros(N, 1);
            drift_y = zeros(N, 1);

            x = app.LocalizationTable{:, 'x [nm]'};
            y = app.LocalizationTable{:, 'y [nm]'};
            f = app.LocalizationTable{:, 'frame'};

            [~, xedges, yedges] = ash2(x, y, app.Image_binsize);
            
            idx0 = f < framesPerInterval;
            im0 = ash2(x(idx0), y(idx0), app.Image_binsize, xedges, yedges);

            for t = 2:N
                idx1 = f >= (t-1)*framesPerInterval & f < t*framesPerInterval;
                im1 = ash2(x(idx1), y(idx1), app.Image_binsize, xedges, yedges);
                [drift_x(t), drift_y(t)] = imxcorroffset(app, im0, im1);
            end
            
            figure(1); hold on;
            plot(drift_x, 'rx');
            plot(drift_y, 'bx');
            % fit it to a cubic polynomrial and plot it together
            f_fine = linspace(1, N, 100);
            plot(f_fine, polyval(polyfit(1:N, drift_x, 3), f_fine), 'r-');
            plot(f_fine, polyval(polyfit(1:N, drift_y, 3), f_fine), 'b-');
        end

        function [x, y] = imxcorroffset(~, im1, im2, gaussfiltsigma)
            if nargin < 4
                gaussfiltsigma = 5;
            end
            
            if any(size(im1)~=size(im2))
                error('im1 and im2 must be the same size');
            end
            
            corr_im = normxcorr2(im1, im2);
            
            if gaussfiltsigma > 0
                corr_im = imgaussfilt(corr_im, gaussfiltsigma);
            end
            
            [ypeak, xpeak] = find(corr_im==max(corr_im(:)));
            x = xpeak - size(im1,2);
            y = ypeak - size(im1,1);
        end
        

        function colorRangesChanged(app, event)
            app.WavelengthLimits = event.range_wavelengths;
            app.EnabledColorsRGB = event.enabled_colors;
            app.NumberEnabledChannels = event.num_enabled;
            app.EnabledColorNames = event.color_names;
            app.LegendLocation = event.legend_location;
            app.ScalebarLocation = event.scalebar_location;
            app.ContrastLimits = event.range_contrasts;
            app.ColorImageSet = true;
            app.ColorImage = event.color_img;
            colorImage(app);
            addLegend(app);
            addScalebar(app);
        end

        function colorImage(app, ~)
            output_image = zeros(size(app.OutputImage,1), size(app.OutputImage,2), 3);
            colorsequence = app.EnabledColorsRGB;

            for icol = 1:app.NumberEnabledChannels
                color_image = app.ColorImage(:,:,icol) - app.ContrastLimits(icol,1);
                color_image = color_image * 255 ./ app.ContrastLimits(icol,2);
                color_image(color_image < 0) = 0;
                color_image(color_image > 255) = 255;
                output_image = output_image + colorimg(color_image, colorsequence(icol,:));
            end

            app.OutputImage = output_image;

            % update the image
            app.loadImage();
        end

        function addLegend(app)
            % determine the location to add the legend
            x_padding = 30;
            y_padding = 30;
            y_spacing = 60;

            switch app.LegendLocation
                case 'Top Right'
                    x0 = size(app.OutputImage,2) - x_padding;
                    y0 = y_padding + y_spacing * 0.5;
                    hortextalign = 'right';
                case 'Top Left'
                    x0 = x_padding;
                    y0 = y_padding + y_spacing * 0.5;
                    hortextalign = 'left';
                case 'Bottom Right'
                    x0 = size(app.OutputImage,2) - x_padding;
                    y0 = size(app.OutputImage,1) - app.NumberEnabledChannels * y_spacing - y_padding + y_spacing * 0.5;
                    hortextalign = 'right';
                case 'Bottom Left'
                    x0 = x_padding;
                    y0 = size(app.OutputImage,1) - app.NumberEnabledChannels * y_spacing - y_padding + y_spacing * 0.5;
                    hortextalign = 'left';
                otherwise
                    return;
            end


            % add text onto the image with the appropriate colors
            for icol = 1:app.NumberEnabledChannels
                text(app.UIAxes, x0, y0 + (icol-1)*y_spacing, ...
                app.EnabledColorNames{icol}, ...
                'Color', app.EnabledColorsRGB(icol,:), ...
                'FontUnits', 'pixels', ...
                'FontSize', 20, ...
                'HorizontalAlignment', hortextalign, ...
                'VerticalAlignment', 'middle');
            end
        end

        function addScalebar(app)
            % determine the location to add the scalebar
            x_padding = 30;
            y_padding = 30;
            y_spacing = 60;

            app.Image_binsize = 20; % nm/pixel

            scalebarlength = 100;
            scalebarwidth = 5;
            scalebarcolor = [1, 1, 1];

            switch app.ScalebarLocation
                case 'Top Right'
                    x0 = size(app.OutputImage,2) - x_padding;
                    y0 = y_padding;
                    scalebarlength = -scalebarlength;
                    y_offset = y_spacing;
                    hortextalign = 'right';
                case 'Top Left'
                    x0 = x_padding;
                    y0 = y_padding;
                    hortextalign = 'left';
                    y_offset = y_spacing;
                case 'Bottom Right'
                    x0 = size(app.OutputImage,2) - x_padding;
                    y0 = size(app.OutputImage,1) - y_spacing * 0.5;
                    y_offset = -y_spacing*0.5;
                    scalebarlength = -scalebarlength;
                    hortextalign = 'right';
                case 'Bottom Left'
                    x0 = x_padding;
                    y0 = size(app.OutputImage,1) - y_spacing * 0.5;
                    y_offset = -y_spacing*0.5;
                    hortextalign = 'left';
                otherwise
                    return;
            end

            % add the scalebar to the image

            line(app.UIAxes, [x0, x0+scalebarlength], [y0, y0], 'Color', scalebarcolor, 'LineWidth', scalebarwidth);
            % calculate the length of the scalebar in um
            scalebartext = sprintf('%d um', round(abs(scalebarlength) * app.Image_binsize * 1e-3));

            text(app.UIAxes, x0, y0+y_offset, scalebartext, ...
                'Color', scalebarcolor, ...
                'FontUnits', 'pixels', ...
                'FontSize', 20, ...
                'HorizontalAlignment', hortextalign, ...
                'VerticalAlignment', 'bottom');
        end
        

        function saveImage(app)
            [filename, pathname] = uiputfile({'*.png', 'PNG File'}, 'Save Image As');
            if isequal(filename,0) || isequal(pathname,0)
                return;
            end
            imwrite(app.OutputImage, fullfile(pathname, filename));
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 640 640];
            app.UIFigure.Name = 'Image Viewer';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {'1x', '1x', '1x', '1x'};
            app.GridLayout.RowHeight = {'1x', 40};
            app.GridLayout.ColumnSpacing = 5;
            app.GridLayout.RowSpacing = 5;

            % Create UIAxes
            app.UIAxes = uiaxes(app.GridLayout);
            app.UIAxes.XTick = [];
            app.UIAxes.YTick = [];
            app.UIAxes.Color = [0 0 0];
            app.UIAxes.Box = 'on';
            app.UIAxes.Layout.Row = 1;
            app.UIAxes.Layout.Column = [1 4];

            % Create SaveImageButton
            app.SaveImageButton = uibutton(app.GridLayout, 'push');
            app.SaveImageButton.FontWeight = 'bold';
            app.SaveImageButton.Layout.Row = 2;
            app.SaveImageButton.Layout.Column = 4;
            app.SaveImageButton.Text = 'Save Image';
            app.SaveImageButton.ButtonPushedFcn = createCallbackFcn(app, @SaveImageButtonPushed, true);

            % Create AdjustImageButton
            app.AdjustImageButton = uibutton(app.GridLayout, 'push');
            app.AdjustImageButton.Layout.Row = 2;
            app.AdjustImageButton.Layout.Column = 1;
            app.AdjustImageButton.Text = 'Adjust Image';
            app.AdjustImageButton.ButtonPushedFcn = createCallbackFcn(app, @AdjustImageButtonPushed, true);

            % Create DriftCorrectionButton
            app.DriftCorrectionButton = uibutton(app.GridLayout, 'push');
            app.DriftCorrectionButton.Layout.Row = 2;
            app.DriftCorrectionButton.Layout.Column = 2;
            app.DriftCorrectionButton.Text = 'Drift Correction';
            app.DriftCorrectionButton.ButtonPushedFcn = createCallbackFcn(app, @DriftCorrectionButtonPushed, true);
            % app.DriftCorrectionButton.Visible = 'off';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = ImageViewer(varargin)

            addpath('lib');

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))


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
end