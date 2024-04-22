classdef IntensityHistogram < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure            matlab.ui.Figure
        GridLayout          matlab.ui.container.GridLayout
        Slider              matlab.ui.control.Slider
        SaveImageButton     matlab.ui.control.Button
        YellowSlider        matlab.ui.control.RangeSlider
        YellowSliderLabel   matlab.ui.control.Label
        MagentaSlider       matlab.ui.control.RangeSlider
        MagentaSliderLabel  matlab.ui.control.Label
        CyanSlider          matlab.ui.control.RangeSlider
        CyanSliderLabel     matlab.ui.control.Label
        BlueSlider          matlab.ui.control.RangeSlider
        BlueSliderLabel     matlab.ui.control.Label
        GreenSlider         matlab.ui.control.RangeSlider
        GreenSliderLabel    matlab.ui.control.Label
        RedSlider           matlab.ui.control.RangeSlider
        RedSliderLabel      matlab.ui.control.Label
        UIAxes              matlab.ui.control.UIAxes
    end

    properties (Access = private)
        HistogramData
        HistogramNumber
        HistogramTotal
    end

    % Functions for the app
    methods (Access = private)
        function drawHistogram(app, histogram_number)
            if nargin < 2
                histogram_number = app.HistogramNumber;
            end
            bar(app.UIAxes, app.HistogramData(:, histogram_number), 'FaceColor', [0, 0, 0], 'EdgeColor', [0, 0, 0]);
            app.UIAxes.XLim = [0, 10];
        end

        function updateEnabledSliders(app, ~)
            componentsColors = {
                {'Red', 'Green', 'Blue', 'Cyan', 'Magenta', 'Yellow'}
            };

            for i1 = 1:6
                if i1 <= app.HistogramTotal
                    app.(['XRegion', componentsColors{1}{i1}]).Visible = 'on';
                    app.([componentsColors{1}{i1}, 'Slider']).Enable = 'on';
                    app.([componentsColors{1}{i1}, 'SliderLabel']).Enable = 'on';
                else
                    app.(['XRegion', componentsColors{1}{i1}]).Visible = 'off';
                    app.([componentsColors{1}{i1}, 'Slider']).Enable = 'off';
                    app.([componentsColors{1}{i1}, 'SliderLabel']).Enable = 'off';
                end
            end
        end
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, varargin)
            app.HistogramData = varargin{1};
            app.HistogramNumber = size(app.HistogramData, 2);
            app.HistogramTotal = size(app.HistogramData, 2) - 1;
            if app.HistogramNumber > 2
                app.Slider.Limits = [1, app.HistogramTotal];
                app.Slider.Value = 1;
                app.Slider.Enable = 'on';
            else
                app.Slider.Enable = 'off';
            end
            % Create the histogram
            app.drawHistogram();
        end

        % Value changed function: Slider
        function SliderValueChanged(app, event)
            value = round(app.Slider.Value);
            app.Slider.Value = value;
            app.HistogramNumber = value;
            app.drawHistogram();
        end

    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app, varargin)
            % pass the position if it is provided
            try
                position = varargin{2};
            catch
                position = [100, 100, 320, 400];
            end

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = position;
            app.UIFigure.Name = 'Intensity Histograms';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {50, 5, '1x', '1x', 10, '1x', '1x', 40, 15};
            app.GridLayout.RowHeight = {'1x', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 25};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 5;

            % Create UIAxes
            app.UIAxes = uiaxes(app.GridLayout);
            app.UIAxes.Box = 'on';
            app.UIAxes.Layout.Row = 1;
            app.UIAxes.Layout.Column = [1 8];

            % Create RedSliderLabel
            app.RedSliderLabel = uilabel(app.GridLayout);
            app.RedSliderLabel.HorizontalAlignment = 'right';
            app.RedSliderLabel.Layout.Row = 3;
            app.RedSliderLabel.Layout.Column = 1;
            app.RedSliderLabel.Text = 'Red';

            % Create RedSlider
            app.RedSlider = uislider(app.GridLayout, 'range');
            app.RedSlider.MajorTicks = [];
            app.RedSlider.MinorTicks = [];
            app.RedSlider.Layout.Row = 3;
            app.RedSlider.Layout.Column = [3 8];

            % Create GreenSliderLabel
            app.GreenSliderLabel = uilabel(app.GridLayout);
            app.GreenSliderLabel.HorizontalAlignment = 'right';
            app.GreenSliderLabel.Layout.Row = 4;
            app.GreenSliderLabel.Layout.Column = 1;
            app.GreenSliderLabel.Text = 'Green';

            % Create GreenSlider
            app.GreenSlider = uislider(app.GridLayout, 'range');
            app.GreenSlider.MajorTicks = [];
            app.GreenSlider.MinorTicks = [];
            app.GreenSlider.Layout.Row = 4;
            app.GreenSlider.Layout.Column = [3 8];

            % Create BlueSliderLabel
            app.BlueSliderLabel = uilabel(app.GridLayout);
            app.BlueSliderLabel.HorizontalAlignment = 'right';
            app.BlueSliderLabel.Layout.Row = 5;
            app.BlueSliderLabel.Layout.Column = 1;
            app.BlueSliderLabel.Text = 'Blue';

            % Create BlueSlider
            app.BlueSlider = uislider(app.GridLayout, 'range');
            app.BlueSlider.MajorTicks = [];
            app.BlueSlider.MinorTicks = [];
            app.BlueSlider.Layout.Row = 5;
            app.BlueSlider.Layout.Column = [3 8];

            % Create CyanSliderLabel
            app.CyanSliderLabel = uilabel(app.GridLayout);
            app.CyanSliderLabel.HorizontalAlignment = 'right';
            app.CyanSliderLabel.Layout.Row = 6;
            app.CyanSliderLabel.Layout.Column = 1;
            app.CyanSliderLabel.Text = 'Cyan';

            % Create CyanSlider
            app.CyanSlider = uislider(app.GridLayout, 'range');
            app.CyanSlider.MajorTicks = [];
            app.CyanSlider.MinorTicks = [];
            app.CyanSlider.Layout.Row = 6;
            app.CyanSlider.Layout.Column = [3 8];

            % Create MagentaSliderLabel
            app.MagentaSliderLabel = uilabel(app.GridLayout);
            app.MagentaSliderLabel.HorizontalAlignment = 'right';
            app.MagentaSliderLabel.Layout.Row = 7;
            app.MagentaSliderLabel.Layout.Column = 1;
            app.MagentaSliderLabel.Text = 'Magenta';

            % Create MagentaSlider
            app.MagentaSlider = uislider(app.GridLayout, 'range');
            app.MagentaSlider.MajorTicks = [];
            app.MagentaSlider.MinorTicks = [];
            app.MagentaSlider.Layout.Row = 7;
            app.MagentaSlider.Layout.Column = [3 8];

            % Create YellowSliderLabel
            app.YellowSliderLabel = uilabel(app.GridLayout);
            app.YellowSliderLabel.HorizontalAlignment = 'right';
            app.YellowSliderLabel.Layout.Row = 8;
            app.YellowSliderLabel.Layout.Column = 1;
            app.YellowSliderLabel.Text = 'Yellow';

            % Create YellowSlider
            app.YellowSlider = uislider(app.GridLayout, 'range');
            app.YellowSlider.MajorTicks = [];
            app.YellowSlider.MinorTicks = [];
            app.YellowSlider.Layout.Row = 8;
            app.YellowSlider.Layout.Column = [3 8];

            % Create SaveImageButton
            app.SaveImageButton = uibutton(app.GridLayout, 'push');
            app.SaveImageButton.Layout.Row = 9;
            app.SaveImageButton.Layout.Column = [3 7];
            app.SaveImageButton.Text = 'Save Image';

            % Create Slider
            app.Slider = uislider(app.GridLayout);
            app.Slider.Limits = [0 5];
            app.Slider.MajorTicks = 1:6;
            app.Slider.MajorTickLabels = {''};
            app.Slider.MinorTicks = 0;
            app.Slider.Layout.Row = 2;
            app.Slider.Layout.Column = [1 9];
            app.Slider.ValueChangedFcn = createCallbackFcn(app, @SliderValueChanged, true);

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = IntensityHistogram(varargin)

            % Create UIFigure and components
            createComponents(app, varargin{:})

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

    % Event handling
    events
        ColorRangesChanged
    end
end