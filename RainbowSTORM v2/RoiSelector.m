classdef RoiSelector < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                matlab.ui.Figure
        GridLayout              matlab.ui.container.GridLayout

        InputsPanel             matlab.ui.container.Panel
            InputsGridLayout        matlab.ui.container.GridLayout
            hEditField              matlab.ui.control.NumericEditField
            hEditFieldLabel         matlab.ui.control.Label
            wEditField              matlab.ui.control.NumericEditField
            wEditFieldLabel         matlab.ui.control.Label
            yEditField              matlab.ui.control.NumericEditField
            yEditFieldLabel         matlab.ui.control.Label
            xEditField              matlab.ui.control.NumericEditField
            xEditFieldLabel         matlab.ui.control.Label
        
        InputModeButtonGroup    matlab.ui.container.ButtonGroup
            TwoPointButton          matlab.ui.control.RadioButton
            BoundingBoxButton       matlab.ui.control.RadioButton
        
        SaveButton              matlab.ui.control.Button
    end

    properties (Access = private)
        % variables to store the coordinates
        x = 0
        y = 0
        w = 0
        h = 0
        x0 = 0
        y0 = 0
        x1 = 0
        y1 = 0
    end

    % Callbacks that handle component events
    methods (Access = private)

        % xEditField value changed function
        function xEditFieldValueChanged(app, ~)
            value = app.xEditField.Value;
            if value < 0
                app.xEditField.Value = 0;
            end
            if app.BoundingBoxButton.Value
                app.x = app.xEditField.Value;
            else
                app.x0 = app.xEditField.Value;
            end
        end

        % yEditField value changed function
        function yEditFieldValueChanged(app, ~)
            value = app.yEditField.Value;
            if value < 0
                app.yEditField.Value = 0;
            end
            if app.BoundingBoxButton.Value
                app.y = app.yEditField.Value;
            else
                app.y0 = app.yEditField.Value;
            end
        end

        % wEditField value changed function
        function wEditFieldValueChanged(app, ~)
            value = app.wEditField.Value;
            if value < 0
                app.wEditField.Value = 0;
            end
            if app.BoundingBoxButton.Value
                app.w = app.wEditField.Value;
            else
                app.x1 = app.wEditField.Value;
            end
        end

        % hEditField value changed function
        function hEditFieldValueChanged(app, ~)
            value = app.hEditField.Value;
            if value < 0
                app.hEditField.Value = 0;
            end
            if app.BoundingBoxButton.Value
                app.h = app.hEditField.Value;
            else
                app.y1 = app.hEditField.Value;
            end
        end

        % InputModeButtonGroup selection changed function
        function InputModeButtonGroupSelectionChanged(app, ~)
            selectedButton = app.InputModeButtonGroup.SelectedObject;

            if selectedButton == app.BoundingBoxButton
                % get the coordinates from the two-point
                app.x0 = app.xEditField.Value;
                app.y0 = app.yEditField.Value;
                app.x1 = app.wEditField.Value;
                app.y1 = app.hEditField.Value;

                % convert the text to bounding box
                app.xEditFieldLabel.Text = 'x';
                app.yEditFieldLabel.Text = 'y';
                app.wEditFieldLabel.Text = 'w';
                app.hEditFieldLabel.Text = 'h';

                % convert private variables to bounding box
                app.convertToBoundingBox();

                % update the edit fields
                app.xEditField.Value = app.x;
                app.yEditField.Value = app.y;
                app.wEditField.Value = app.w;
                app.hEditField.Value = app.h;
            else
                % get the coordinates from the bounding box
                app.x = app.xEditField.Value;
                app.y = app.yEditField.Value;
                app.w = app.wEditField.Value;
                app.h = app.hEditField.Value;

                % convert the text to two-point
                app.xEditFieldLabel.Text = 'x0';
                app.yEditFieldLabel.Text = 'y0';
                app.wEditFieldLabel.Text = 'x1';
                app.hEditFieldLabel.Text = 'y1';

                % convert private variables to two-point
                app.convertToTwoPoint();

                % update the edit fields
                app.xEditField.Value = app.x0;
                app.yEditField.Value = app.y0;
                app.wEditField.Value = app.x1;
                app.hEditField.Value = app.y1;
            end
        end

        % Button pushed function: SaveButton
        function SaveButtonPushed(app, ~)
            % change the coordinates to bounding box
            if app.TwoPointButton.Value
                app.convertToBoundingBox();
                % set the radio button to bounding box
                app.BoundingBoxButton.Value = true;
            end

            % send an event to the main app
            eventdata = eventsetcrops([app.x, app.y, app.w, app.h]);
            notify(app, 'SetCrops', eventdata);

            % close the app
            delete(app);
        end

        % convert from bounding box to two-point
        function convertToTwoPoint(app)
            app.x0 = app.x;
            app.y0 = app.y;
            app.x1 = app.x + app.w;
            app.y1 = app.y + app.h;
        end

        % convert from two-point to bounding box
        function convertToBoundingBox(app)
            app.x = min(app.x0, app.x1);
            app.y = min(app.y0, app.y1);
            app.w = abs(app.x1 - app.x0);
            app.h = abs(app.y1 - app.y0);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 150 190];
            app.UIFigure.Name = 'ROI Selector';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {5, '1x', 5};
            app.GridLayout.RowHeight = {'1x', '0.8x', 5, '0.3x'};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 5 0 0];

            % Create InputsPanel
            app.InputsPanel = uipanel(app.GridLayout);
            app.InputsPanel.BorderType = 'none';
            app.InputsPanel.Title = 'Inputs';
            app.InputsPanel.Layout.Row = 1;
            app.InputsPanel.Layout.Column = [1 3];
            app.InputsPanel.FontWeight = 'bold';

            % Create InputsGridLayout
            app.InputsGridLayout = uigridlayout(app.InputsPanel);
            app.InputsGridLayout.ColumnWidth = {20, '1x', 20, '1x'};
            app.InputsGridLayout.ColumnSpacing = 5;
            app.InputsGridLayout.RowSpacing = 5;

            % Create xEditFieldLabel
            app.xEditFieldLabel = uilabel(app.InputsGridLayout);
            app.xEditFieldLabel.HorizontalAlignment = 'right';
            app.xEditFieldLabel.Layout.Row = 1;
            app.xEditFieldLabel.Layout.Column = 1;
            app.xEditFieldLabel.Text = 'x';

            % Create xEditField
            app.xEditField = uieditfield(app.InputsGridLayout, 'numeric');
            app.xEditField.Layout.Row = 1;
            app.xEditField.Layout.Column = 2;
            app.xEditField.ValueChangedFcn = createCallbackFcn(app, @xEditFieldValueChanged, true);

            % Create yEditFieldLabel
            app.yEditFieldLabel = uilabel(app.InputsGridLayout);
            app.yEditFieldLabel.HorizontalAlignment = 'right';
            app.yEditFieldLabel.Layout.Row = 1;
            app.yEditFieldLabel.Layout.Column = 3;
            app.yEditFieldLabel.Text = 'y';

            % Create yEditField
            app.yEditField = uieditfield(app.InputsGridLayout, 'numeric');
            app.yEditField.Layout.Row = 1;
            app.yEditField.Layout.Column = 4;
            app.yEditField.ValueChangedFcn = createCallbackFcn(app, @yEditFieldValueChanged, true);

            % Create wEditFieldLabel
            app.wEditFieldLabel = uilabel(app.InputsGridLayout);
            app.wEditFieldLabel.HorizontalAlignment = 'right';
            app.wEditFieldLabel.Layout.Row = 2;
            app.wEditFieldLabel.Layout.Column = 1;
            app.wEditFieldLabel.Text = 'w';

            % Create wEditField
            app.wEditField = uieditfield(app.InputsGridLayout, 'numeric');
            app.wEditField.Layout.Row = 2;
            app.wEditField.Layout.Column = 2;
            app.wEditField.ValueChangedFcn = createCallbackFcn(app, @wEditFieldValueChanged, true);

            % Create hEditFieldLabel
            app.hEditFieldLabel = uilabel(app.InputsGridLayout);
            app.hEditFieldLabel.HorizontalAlignment = 'right';
            app.hEditFieldLabel.Layout.Row = 2;
            app.hEditFieldLabel.Layout.Column = 3;
            app.hEditFieldLabel.Text = 'h';

            % Create hEditField
            app.hEditField = uieditfield(app.InputsGridLayout, 'numeric');
            app.hEditField.Layout.Row = 2;
            app.hEditField.Layout.Column = 4;
            app.hEditField.ValueChangedFcn = createCallbackFcn(app, @hEditFieldValueChanged, true);

            
            % Create InputModeButtonGroup
            app.InputModeButtonGroup = uibuttongroup(app.GridLayout);
            app.InputModeButtonGroup.BorderType = 'none';
            app.InputModeButtonGroup.Title = 'Input Mode';
            app.InputModeButtonGroup.Layout.Row = 2;
            app.InputModeButtonGroup.Layout.Column = [1 3];
            app.InputModeButtonGroup.FontWeight = 'bold';
            app.InputModeButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @InputModeButtonGroupSelectionChanged, true);

            % Create BoundingBoxButton
            app.BoundingBoxButton = uiradiobutton(app.InputModeButtonGroup);
            app.BoundingBoxButton.Text = 'Bounding Box';
            app.BoundingBoxButton.Position = [14 27 97 22];
            app.BoundingBoxButton.Value = true;
            
            % Create TwoPointButton
            app.TwoPointButton = uiradiobutton(app.InputModeButtonGroup);
            app.TwoPointButton.Text = 'Two-Point';
            app.TwoPointButton.Position = [14 6 75 22];
            
            % Create SaveButton
            app.SaveButton = uibutton(app.GridLayout, 'push');
            app.SaveButton.Layout.Row = 4;
            app.SaveButton.Layout.Column = 2;
            app.SaveButton.Text = 'Save';
            app.SaveButton.ButtonPushedFcn = createCallbackFcn(app, @SaveButtonPushed, true);

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = RoiSelector

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

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
        SetCrops  % Event to send the crop coordinates to the main app
    end
end