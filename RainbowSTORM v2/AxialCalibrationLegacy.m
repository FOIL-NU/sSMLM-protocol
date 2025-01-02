classdef AxialCalibrationLegacy < matlab.apps.AppBase
    
    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                    matlab.ui.Figure
        GridLayout                  matlab.ui.container.GridLayout

        LoadFileButton              matlab.ui.control.Button
        PixelSizeField              matlab.ui.control.NumericEditField
        PixelSizeFieldLabel         matlab.ui.control.Label
        ZStepField                  matlab.ui.control.NumericEditField
        ZStepFieldLabel             matlab.ui.control.Label
        FlipImagesButton            matlab.ui.control.Button
        
        MoleculeDropDown            matlab.ui.control.DropDown
        MoleculeDropDownLabel       matlab.ui.control.Label

        MinZ0Field                  matlab.ui.control.NumericEditField
        MinZ0Label                  matlab.ui.control.Label
        MaxZ0Field                  matlab.ui.control.NumericEditField
        MaxZ0Label                  matlab.ui.control.Label
        MinZ1Field                  matlab.ui.control.NumericEditField
        MinZ1Label                  matlab.ui.control.Label
        MaxZ1Field                  matlab.ui.control.NumericEditField
        MaxZ1Label                  matlab.ui.control.Label
        MinZ0Slider                 matlab.ui.control.Slider
        MaxZ0Slider                 matlab.ui.control.Slider
        MinZ1Slider                 matlab.ui.control.Slider
        MaxZ1Slider                 matlab.ui.control.Slider

        ExportCsvButton             matlab.ui.control.Button
        SaveFileButton              matlab.ui.control.Button

        UIAxesImageOrder0           matlab.ui.control.UIAxes
        UIAxesImageOrder1           matlab.ui.control.UIAxes
        UIAxesFWHMvsZ               matlab.ui.control.UIAxes
        UIAxesCaliCurve             matlab.ui.control.UIAxes
    end
    
    % Properties that correspond to app components
    properties (Access = private)
        image
        localizations
        dir_inputpath
        dir_matfile
        dir_csvfile
        z
        fwhm0
        fwhm1
        simulated0
        simulated1
        z_simulated
        ratio
        px_size
        z_step
        target_molecule

        global_z_min
        global_z_max
        global_z_num
    end
    
    % Callbacks that handle component events
    methods (Access = private)
        % Code that executes after component creation
        function startupFcn(app, ~)
            app.px_size = 110;
            app.z_step = 20;
            app.global_z_num = 200;
            app.global_z_min = - app.global_z_num / 2 * app.z_step;
            app.global_z_max = app.global_z_num / 2 * app.z_step;
        end
        
        % Button pushed function: LoadButton
        function LoadButtonPushed(app, ~)
            [file,path] = uigetfile({'*.nd2;*.tif;*.tiff','Supported Filetypes (*.nd2, *.tif)'}, 'Select the .nd2 or .tif file');

            % check if the user canceled the file selection
            if file == 0
                return
            end

            figure(app.UIFigure);
            app.dir_inputpath = fullfile(path,file);
            app.PreviewImage(app);
            app.ProcessFile(app);
            app.UpdateUIAxesFWHMvsZ(app);

            % enable the pixel size and z step fields
            app.PixelSizeField.Enable = 'on';
            app.PixelSizeFieldLabel.Enable = 'on';
            app.ZStepField.Enable = 'on';
            app.ZStepFieldLabel.Enable = 'on';
            app.FlipImagesButton.Enable = 'on';

            % % enable the molecule dropdown (temporarily disabled for now)
            % app.MoleculeDropDown.Enable = 'on';
            % app.MoleculeDropDownLabel.Enable = 'on';

            % enable the min and max z fields and labels
            app.MinZ0Field.Enable = 'on';
            app.MaxZ0Field.Enable = 'on';
            app.MinZ1Field.Enable = 'on';
            app.MaxZ1Field.Enable = 'on';
            app.MinZ0Label.Enable = 'on';
            app.MaxZ0Label.Enable = 'on';
            app.MinZ1Label.Enable = 'on';
            app.MaxZ1Label.Enable = 'on';
            app.MinZ0Slider.Enable = 'on';
            app.MaxZ0Slider.Enable = 'on';
            app.MinZ1Slider.Enable = 'on';
            app.MaxZ1Slider.Enable = 'on';

            % enable the save buttons
            app.ExportCsvButton.Enable = 'on';
            app.SaveFileButton.Enable = 'on';
        end

        function PreviewImage(app, ~)
            % parse the type of file extension
            [~,~,ext] = fileparts(app.dir_inputpath);

            img = bfOpen3DVolume(app.dir_inputpath);
            if size(img) == [1,4]
                img = img{1}{1};
            end

            app.image = double(squeeze(img));

            % cla(app.UIAxesImagePreview);
            % imagesc(app.UIAxesImagePreview,squeeze(mean(app.image,3)));
            % % scale the x and y axis to fit the image
            % axis(app.UIAxesImagePreview,'image');

            Nf = size(app.image,3);
            img_width = size(app.image,2);
            img0 = img(:,1:round(img_width/2),:);
            img1 = img(:,(round(img_width/2)+1):end,:);
            p3 = round(Nf/2);

            [py0,px0] = find(img0(:,:,p3)==max(max(img0(:,:,p3))),1);
            [py1,px1] = find(img1(:,:,p3)==max(max(img1(:,:,p3))),1);
            app.localizations = [px0,py0,px1,py1];

            cla(app.UIAxesImageOrder0);
            imagesc(app.UIAxesImageOrder0,img0(1:end,1:end,p3));
            axis(app.UIAxesImageOrder0,'image');
            hold(app.UIAxesImageOrder0, 'on');
            scatter(app.UIAxesImageOrder0,px0,py0,'*g');
            hold(app.UIAxesImageOrder0, 'off');

            cla(app.UIAxesImageOrder1);
            imagesc(app.UIAxesImageOrder1,img1(1:end,1:end,p3));
            axis(app.UIAxesImageOrder1,'image');
            hold(app.UIAxesImageOrder1, 'on');
            scatter(app.UIAxesImageOrder1,px1,py1,'*g');
            hold(app.UIAxesImageOrder1, 'off');
        end

        function ProcessFile(app, ~)
            Nf = size(app.image,3);
            img_width = size(app.image,2);
            A0 = app.image(:,1:round(img_width/2),:);
            A1 = app.image(:,(round(img_width/2)+1):end,:);
            locs = app.localizations;
            px0 = locs(1);
            py0 = locs(2);
            px1 = locs(3);
            py1 = locs(4);

            aa=[];%Blinking image
            psf0 = [];
            spt= [];
            sptavg = [];
            psf1 = [];
            bw=5;
            w0=6;  % width of ROI in 0th order
            w1=6;  % width of ROI along x-axis in 1th order
            for i_frame = 1:Nf
                aa = A0((-w0:w0)+py0(1),(-w0:w0)+px0(1),i_frame) - 30;
                psf0(1,:,i_frame) = sum(aa((w0+1)-bw:(w0+1)+bw,:),2);
                spt = A1((-w0:w0)+py1(1),(-w1*1:w1*1)+px1(1),i_frame)-30;
                sptavg(1,:)=sum(spt,1);
                psf1(1,:,i_frame) = sum(spt((w0+1)-bw:(w0+1)+bw,:),2);
            end
            psfY0=[];
            psfY1=[];
            psf2D0 = [];
            psf2D1 = [];
            yfit0=[];
            yfit1=[];
            options = optimset('Display','off','TolFun',4e-16,'LargeScale','off');
            for i_frame = 1:Nf
                % fitting for spatial images
                psfY0(1,:) =  psf0(1,:,i_frame);
                psfY0(1,:) = psfY0(1,:) - min(psfY0(1,:));
                
                %         psfY0(n,:) = psfY0(n,:).*(psfY0(n,:)>0);
                y0 = [1:size(psfY0(1,:),2)];
                cy0(1,:) = sum(psfY0(1,:).*y0)/sum(psfY0(1,:));
                sy0(1,:) = sqrt(sum(psfY0(1,:).*(abs(y0-cy0(1,:)).^2))/sum(psfY0(1,:)));
                amp0(1,:) = max(psfY0(1,:));
                par0(1,:) = [cy0(1,:),sy0(1,:),amp0(1,:)];
                
                fp0D = fminunc(@fitgaussian1D,par0(1,:),options,psfY0(1,:),y0);
                
                cy0fit(1,i_frame) = fp0D(1);
                sy0fit(1,i_frame) = fp0D(2);
                amp0fit(1,i_frame) = fp0D(3);
                y0new = [1:0.1:size(psfY0(1,:),2)];
                yfit0(1,:) = amp0fit(1,i_frame)*(exp(-0.5*(y0new-cy0fit(1,i_frame)).^2./(sy0fit(1,i_frame)^2)));
                fwhm0(1,i_frame) = sy0fit(1,i_frame)*2.35*0.8906; % 0.8621 is the constant between Thunderstorm and fitting
                %         fwhm0px(n,Nf) = sy0fit(n,Nf);
                
                % fitting for spatial images
                psfY1(1,:) =  psf1(1,:,i_frame);
                psfY1(1,:) = psfY1(1,:) - min(psfY1(1,:));
                
                %         psfY1(n,:) = psfY1(n,:).*(psfY1(n,:)>0);
                y1 = [1:size(psfY1(1,:),2)];
                cy1(1,:) = sum(psfY1(1,:).*y1)/sum(psfY1(1,:));
                sy1(1,:) = sqrt(sum(psfY1(1,:).*(abs(y1-cy1(1,:)).^2))/sum(psfY1(1,:)));
                amp1(1,:) = max(psfY1(1,:));
                par1(1,:) = [cy1(1,:),sy1(1,:),amp1(1,:)];
                try
                    fp1D = fminunc(@fitgaussian1D,par1(1,:),options,psfY1(1,:),y1);
                end
                cy1fit(1,i_frame) = fp1D(1);
                sy1fit(1,i_frame) = fp1D(2);
                amp1fit(1,i_frame) = fp1D(3);
                y1new = [1:0.1:size(psfY1,2)];
                yfit1(1,:) = amp1fit(1,i_frame)*(exp(-0.5*(y1new-cy1fit(1,i_frame)).^2./(sy1fit(1,i_frame)^2)));
                fwhm1(1,i_frame) = sy1fit(1,i_frame)*2.35*0.8906;
            end

            app.global_z_num = Nf;
            app.z = -((Nf-1)/2):((Nf-1)/2);
            app.fwhm0 = fwhm0;
            app.fwhm1 = fwhm1;
        end

        function UpdateUIAxesFWHMvsZ(app, ~)
            z = app.z * app.z_step;
            idx_minz0 = find(z >= app.MinZ0Field.Value,1,'first');
            idx_maxz0 = find(z <= app.MaxZ0Field.Value,1,'last');
            idx_minz1 = find(z >= app.MinZ1Field.Value,1,'first');
            idx_maxz1 = find(z <= app.MaxZ1Field.Value,1,'last');

            z0 = app.z(idx_minz0:idx_maxz0)*app.z_step;
            z1 = app.z(idx_minz1:idx_maxz1)*app.z_step;
            fwhm0 = app.fwhm0(idx_minz0:idx_maxz0)*app.px_size;
            fwhm1 = app.fwhm1(idx_minz1:idx_maxz1)*app.px_size;

            cla(app.UIAxesFWHMvsZ);
            hold(app.UIAxesFWHMvsZ,'on');
            plot(app.UIAxesFWHMvsZ,z0,fwhm0,'ob','MarkerSize',4);
            plot(app.UIAxesFWHMvsZ,z1,fwhm1,'or','MarkerSize',4);
            hold(app.UIAxesFWHMvsZ,'off');
            ylim(app.UIAxesFWHMvsZ,[300,1000]);

            app.z_simulated = app.global_z_min:app.global_z_max;
            if length(z1) < 3
                app.simulated1 = nan;
            else
                f1 = polyfit(z1,fwhm1',2);
                app.simulated1 = f1(1).*app.z_simulated.^2+f1(2)*app.z_simulated+f1(3);
                hold(app.UIAxesFWHMvsZ,'on');
                plot(app.UIAxesFWHMvsZ,app.z_simulated,app.simulated1,'r');
                hold(app.UIAxesFWHMvsZ,'off');
            end

            if length(z0) < 3
                app.simulated0 = nan;
            else
                f0 = polyfit(z0,fwhm0',2);
                app.simulated0 = f0(1).*app.z_simulated.^2+f0(2)*app.z_simulated+f0(3);
                hold(app.UIAxesFWHMvsZ,'on');
                plot(app.UIAxesFWHMvsZ,app.z_simulated,app.simulated0,'b');
                hold(app.UIAxesFWHMvsZ,'off');
            end
        end

        function UpdateUIAxesCaliCurve(app, ~)
            cla(app.UIAxesCaliCurve);

            if any(isnan(app.simulated0)) || any(isnan(app.simulated1))
                app.ExportCsvButton.Enable = 'off';
                app.SaveFileButton.Enable = 'off';
                return
            end

             ratio = app.simulated1./app.simulated0;
            %ratio = axialf(app,app.simulated0,app.simulated1);

            max_ratio = find(islocalmax(ratio));
            min_ratio = find(islocalmin(ratio));
            ratio = ratio(max_ratio:min_ratio);
            z_simulated = app.z_simulated(max_ratio:min_ratio);
            simulated1 = app.simulated1(max_ratio:min_ratio);
            simulated0 = app.simulated0(max_ratio:min_ratio);
            plot(app.UIAxesCaliCurve,z_simulated,ratio,'k');
            app.ratio = ratio;
            app.z_simulated = z_simulated;
            app.simulated1 = simulated1;
            app.simulated0 = simulated0;
            app.ExportCsvButton.Enable = 'on';
            app.SaveFileButton.Enable = 'on';
        end

        function F = axialf(~,wn,wp)
            F = (wp.*wp-wn.*wn)./(wp.*wp+wn.*wn);
        end
        
        % Value changed function: MinZ0Field, MaxZ0Field, MinZ1Field,
        % ...and 1 other component
        function ZFieldValueChanged(app, ~)
            CopyZFieldsToZSliders(app);
            UpdateUIAxesFWHMvsZ(app);
            UpdateUIAxesCaliCurve(app);
        end
        
        % Value changed function: PixelSizeField
        function PixelSizeFieldValueChanged(app, ~)
            app.px_size = app.PixelSizeField.Value;
            UpdateUIAxesFWHMvsZ(app);
            UpdateUIAxesCaliCurve(app);
        end

        % Value changed function: ZstepField
        function ZStepFieldValueChanged(app, ~)
            old_z_step = app.z_step;
            app.z_step = app.ZStepField.Value;

            % update the global z_min and z_max
            app.global_z_min = -app.global_z_num / 2 * app.z_step;
            app.global_z_max = app.global_z_num / 2 * app.z_step;

            % update the z0 and z1 sliders
            app.MinZ0Slider.Value = app.MinZ0Slider.Value * app.z_step / old_z_step;
            app.MaxZ0Slider.Value = app.MaxZ0Slider.Value * app.z_step / old_z_step;
            app.MinZ1Slider.Value = app.MinZ1Slider.Value * app.z_step / old_z_step;
            app.MaxZ1Slider.Value = app.MaxZ1Slider.Value * app.z_step / old_z_step;

            % update the range of the z0 and z1 sliders
            app.MinZ0Slider.Limits = [app.global_z_min app.global_z_max];
            app.MaxZ0Slider.Limits = [app.global_z_min app.global_z_max];
            app.MinZ1Slider.Limits = [app.global_z_min app.global_z_max];
            app.MaxZ1Slider.Limits = [app.global_z_min app.global_z_max];

            % update the value of the z0 and z1 sliders
            CopyZSlidersToZFields(app);
            UpdateUIAxesFWHMvsZ(app);
            UpdateUIAxesCaliCurve(app);

            xlim(app.UIAxesFWHMvsZ, [app.global_z_min app.global_z_max]);
        end
        
        % Match the z0 and z1 sliders to the z0 and z1 fields
        function CopyZSlidersToZFields(app, ~)
            app.MinZ0Field.Value = round(app.MinZ0Slider.Value);
            app.MaxZ0Field.Value = round(app.MaxZ0Slider.Value);
            app.MinZ1Field.Value = round(app.MinZ1Slider.Value);
            app.MaxZ1Field.Value = round(app.MaxZ1Slider.Value);
        end

        function CopyZFieldsToZSliders(app, ~)
            app.MinZ0Field.Value = round(app.MinZ0Field.Value);
            app.MaxZ0Field.Value = round(app.MaxZ0Field.Value);
            app.MinZ1Field.Value = round(app.MinZ1Field.Value);
            app.MaxZ1Field.Value = round(app.MaxZ1Field.Value);
            app.MinZ0Slider.Value = app.MinZ0Field.Value;
            app.MaxZ0Slider.Value = app.MaxZ0Field.Value;
            app.MinZ1Slider.Value = app.MinZ1Field.Value;
            app.MaxZ1Slider.Value = app.MaxZ1Field.Value;
        end

        % Value changing function: MinZ0Slider
        function MinZ0SliderValueChanging(app, event)
            changingValue = event.Value;
            app.MinZ0Field.Value = round(changingValue);
            UpdateUIAxesFWHMvsZ(app);
            UpdateUIAxesCaliCurve(app);
        end

        % Value changing function: MaxZ0Slider
        function MaxZ0SliderValueChanging(app, event)
            changingValue = event.Value;
            app.MaxZ0Field.Value = round(changingValue);
            UpdateUIAxesFWHMvsZ(app);
            UpdateUIAxesCaliCurve(app);
        end

        % Value changing function: MinZ1Slider
        function MinZ1SliderValueChanging(app, event)
            changingValue = event.Value;
            app.MinZ1Field.Value = round(changingValue);
            UpdateUIAxesFWHMvsZ(app);
            UpdateUIAxesCaliCurve(app);
        end

        % Value changing function: MaxZ1Slider
        function MaxZ1SliderValueChanging(app, event)
            changingValue = event.Value;
            app.MaxZ1Field.Value = round(changingValue);
            UpdateUIAxesFWHMvsZ(app);
            UpdateUIAxesCaliCurve(app);
        end
        
        % Button pushed function: ExportCsvButton
        function ExportButtonPushed(app, ~)
            % let the user pick where to put the file
            [file,path] = uiputfile({'*.csv','Comma-separated files (*.csv)'}, ...
                'Save the calibration file as', 'axialcali.csv');
            app.dir_csvfile = fullfile(path,file);
            
            if path == 0
                return
            end

            cali_array=[app.z_simulated;app.ratio];
            cali_array=cali_array';
            dlmwrite(app.dir_csvfile,cali_array);
        end

        % Button pushed function: ExportButton
        function SaveButtonPushed(app, ~)
            % let the user pick where to put the file
            [file,path] = uiputfile({'*.mat', 'MAT-files (*.mat)'}, ...
                'Save the calibration file as','axialcali.mat');
            app.dir_matfile = fullfile(path,file);
            
            if path == 0
                return
            end

            zcali.sigma0_fitted = app.simulated0;
            zcali.sigma1_fitted = app.simulated1;
            zcali.z_values = app.z_simulated;

            save(app.dir_matfile,'zcali');

            % send an event to the app
            eventdata = eventsetfilename(app.dir_matfile);
            notify(app,'CalibrationFileSaved', eventdata);
        end
    end
    
    % Component initialization
    methods (Access = private)
        
        % Create UIFigure and components
        function createComponents(app)
            
            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 720 600];
            app.UIFigure.Name = 'sSMLM Axial Calibration App';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {50, '1x', '1x', '1x', '1x', '1x', 50, 50, '1x', '1x', '1x', '1x', '1x', 50};
            app.GridLayout.RowHeight = {25, 25, '1x', '1x', 25, 25, 25, 25};
            app.GridLayout.ColumnSpacing = 5;
            app.GridLayout.RowSpacing = 5;

            % Create LoadFileButton
            app.LoadFileButton = uibutton(app.GridLayout, 'push');
            app.LoadFileButton.Layout.Row = [1 2];
            app.LoadFileButton.Layout.Column = [2 6];
            app.LoadFileButton.Text = 'Load File';
            app.LoadFileButton.ButtonPushedFcn = createCallbackFcn(app, @LoadButtonPushed, true);
            
            % Create PixelSizeFieldLabel
            app.PixelSizeFieldLabel = uilabel(app.GridLayout);
            app.PixelSizeFieldLabel.HorizontalAlignment = 'right';
            app.PixelSizeFieldLabel.Layout.Row = 1;
            app.PixelSizeFieldLabel.Layout.Column = [8 9];
            app.PixelSizeFieldLabel.Text = 'Pixel Size (nm)';
            app.PixelSizeFieldLabel.Enable = 'off';
            
            % Create PixelSizeField
            app.PixelSizeField = uieditfield(app.GridLayout, 'numeric');
            app.PixelSizeField.Layout.Row = 1;
            app.PixelSizeField.Layout.Column = 10;
            app.PixelSizeField.Value = app.px_size;
            app.PixelSizeField.Enable = 'off';
            app.PixelSizeField.ValueChangedFcn = createCallbackFcn(app, @PixelSizeFieldValueChanged, true);


            % Create ZStepFieldLabel
            app.ZStepFieldLabel = uilabel(app.GridLayout);
            app.ZStepFieldLabel.HorizontalAlignment = 'right';
            app.ZStepFieldLabel.Layout.Row = 1;
            app.ZStepFieldLabel.Layout.Column = [11 12];
            app.ZStepFieldLabel.Text = 'Z Step (nm)';
            app.ZStepFieldLabel.Enable = 'off';

            % Create ZStepField
            app.ZStepField = uieditfield(app.GridLayout, 'numeric');
            app.ZStepField.Layout.Row = 1;
            app.ZStepField.Layout.Column = 13;
            app.ZStepField.Value = app.z_step;
            app.ZStepField.Enable = 'off';
            app.ZStepField.ValueChangedFcn = createCallbackFcn(app, @ZStepFieldValueChanged, true);

            % Create FlipImagesButton
            app.FlipImagesButton = uibutton(app.GridLayout, 'push');
            app.FlipImagesButton.Layout.Row = 2;
            app.FlipImagesButton.Layout.Column = [12 13];
            app.FlipImagesButton.Text = 'Flip Images';
            app.FlipImagesButton.Enable = 'off';

            % Create MoleculeDropDownLabel
            app.MoleculeDropDownLabel = uilabel(app.GridLayout);
            app.MoleculeDropDownLabel.HorizontalAlignment = 'right';
            app.MoleculeDropDownLabel.Layout.Row = 2;
            app.MoleculeDropDownLabel.Layout.Column = [8 9];
            app.MoleculeDropDownLabel.Text = 'Molecule #';
            app.MoleculeDropDownLabel.Enable = 'off';
            
            % Create MoleculeDropDown
            app.MoleculeDropDown = uidropdown(app.GridLayout);
            app.MoleculeDropDown.Items = {'1', '2', '3', '4'};
            app.MoleculeDropDown.Layout.Row = 2;
            app.MoleculeDropDown.Layout.Column = 10;
            app.MoleculeDropDown.Value = '1';
            app.MoleculeDropDown.Enable = 'off';

            % Create MinZ0Label
            app.MinZ0Label = uilabel(app.GridLayout);
            app.MinZ0Label.HorizontalAlignment = 'right';
            app.MinZ0Label.VerticalAlignment = 'center';
            app.MinZ0Label.FontColor = [0 0 1];
            app.MinZ0Label.Enable = 'off';
            app.MinZ0Label.Layout.Row = 5;
            app.MinZ0Label.Layout.Column = 1;
            app.MinZ0Label.Text = 'Min Z0';

            % Create MinZ0Field
            app.MinZ0Field = uieditfield(app.GridLayout, 'numeric');
            app.MinZ0Field.FontColor = [0 0 1];
            app.MinZ0Field.Enable = 'off';
            app.MinZ0Field.Layout.Row = 5;
            app.MinZ0Field.Layout.Column = 7;
            app.MinZ0Field.Value = app.global_z_min;
            app.MinZ0Field.ValueChangedFcn = createCallbackFcn(app, @ZFieldValueChanged, true);

            % Create MaxZ0Label
            app.MaxZ0Label = uilabel(app.GridLayout);
            app.MaxZ0Label.HorizontalAlignment = 'right';
            app.MaxZ0Label.VerticalAlignment = 'center';
            app.MaxZ0Label.FontColor = [0 0 1];
            app.MaxZ0Label.Enable = 'off';
            app.MaxZ0Label.Layout.Row = 6;
            app.MaxZ0Label.Layout.Column = 1;
            app.MaxZ0Label.Text = 'Max Z0';
            
            % Create MaxZ0Field
            app.MaxZ0Field = uieditfield(app.GridLayout, 'numeric');
            app.MaxZ0Field.FontColor = [0 0 1];
            app.MaxZ0Field.Enable = 'off';
            app.MaxZ0Field.Layout.Row = 6;
            app.MaxZ0Field.Layout.Column = 7;
            app.MaxZ0Field.Value = app.global_z_max;
            app.MaxZ0Field.ValueChangedFcn = createCallbackFcn(app, @ZFieldValueChanged, true);

            % Create MinZ1Label
            app.MinZ1Label = uilabel(app.GridLayout);
            app.MinZ1Label.HorizontalAlignment = 'right';
            app.MinZ1Label.VerticalAlignment = 'center';
            app.MinZ1Label.FontColor = [1 0 0];
            app.MinZ1Label.Enable = 'off';
            app.MinZ1Label.Layout.Row = 7;
            app.MinZ1Label.Layout.Column = 1;
            app.MinZ1Label.Text = 'Min Z1';

            % Create MinZ1Field
            app.MinZ1Field = uieditfield(app.GridLayout, 'numeric');
            app.MinZ1Field.FontColor = [1 0 0];
            app.MinZ1Field.Enable = 'off';
            app.MinZ1Field.Layout.Row = 7;
            app.MinZ1Field.Layout.Column = 7;
            app.MinZ1Field.Value = app.global_z_min;
            app.MinZ1Field.ValueChangedFcn = createCallbackFcn(app, @ZFieldValueChanged, true);

            % Create MaxZ1Label
            app.MaxZ1Label = uilabel(app.GridLayout);
            app.MaxZ1Label.HorizontalAlignment = 'right';
            app.MaxZ1Label.VerticalAlignment = 'center';
            app.MaxZ1Label.FontColor = [1 0 0];
            app.MaxZ1Label.Enable = 'off';
            app.MaxZ1Label.Layout.Row = 8;
            app.MaxZ1Label.Layout.Column = 1;
            app.MaxZ1Label.Text = 'Max Z1';

            % Create MaxZ1Field
            app.MaxZ1Field = uieditfield(app.GridLayout, 'numeric');
            app.MaxZ1Field.FontColor = [1 0 0];
            app.MaxZ1Field.Enable = 'off';
            app.MaxZ1Field.Layout.Row = 8;
            app.MaxZ1Field.Layout.Column = 7;
            app.MaxZ1Field.Value = app.global_z_max;
            app.MaxZ1Field.ValueChangedFcn = createCallbackFcn(app, @ZFieldValueChanged, true);

            % Create MaxZ1Slider
            app.MaxZ1Slider = uislider(app.GridLayout);
            app.MaxZ1Slider.MajorTicks = [];
            app.MaxZ1Slider.MinorTicks = [];
            app.MaxZ1Slider.Enable = 'off';
            app.MaxZ1Slider.Layout.Row = 8;
            app.MaxZ1Slider.Layout.Column = [2 6];
            app.MaxZ1Slider.Limits = [app.global_z_min app.global_z_max];
            app.MaxZ1Slider.Value = app.global_z_max;
            app.MaxZ1Slider.ValueChangingFcn = createCallbackFcn(app, @MaxZ1SliderValueChanging, true);

            % Create MinZ1Slider
            app.MinZ1Slider = uislider(app.GridLayout);
            app.MinZ1Slider.MajorTicks = [];
            app.MinZ1Slider.MinorTicks = [];
            app.MinZ1Slider.Enable = 'off';
            app.MinZ1Slider.Layout.Row = 7;
            app.MinZ1Slider.Layout.Column = [2 6];
            app.MinZ1Slider.Limits = [app.global_z_min app.global_z_max];
            app.MinZ1Slider.Value = app.global_z_min;
            app.MinZ1Slider.ValueChangingFcn = createCallbackFcn(app, @MinZ1SliderValueChanging, true);

            % Create MaxZ0Slider
            app.MaxZ0Slider = uislider(app.GridLayout);
            app.MaxZ0Slider.MajorTicks = [];
            app.MaxZ0Slider.MinorTicks = [];
            app.MaxZ0Slider.Enable = 'off';
            app.MaxZ0Slider.Layout.Row = 6;
            app.MaxZ0Slider.Layout.Column = [2 6];
            app.MaxZ0Slider.Limits = [app.global_z_min app.global_z_max];
            app.MaxZ0Slider.Value = app.global_z_max;
            app.MaxZ0Slider.ValueChangingFcn = createCallbackFcn(app, @MaxZ0SliderValueChanging, true);

            % Create MinZ0Slider
            app.MinZ0Slider = uislider(app.GridLayout);
            app.MinZ0Slider.MajorTicks = [];
            app.MinZ0Slider.MinorTicks = [];
            app.MinZ0Slider.Enable = 'off';
            app.MinZ0Slider.Layout.Row = 5;
            app.MinZ0Slider.Layout.Column = [2 6];
            app.MinZ0Slider.Limits = [app.global_z_min app.global_z_max];
            app.MinZ0Slider.Value = app.global_z_min;
            app.MinZ0Slider.ValueChangingFcn = createCallbackFcn(app, @MinZ0SliderValueChanging, true);

            % Create ExportCsvButton
            app.ExportCsvButton = uibutton(app.GridLayout, 'push');
            app.ExportCsvButton.Layout.Row = [5 6];
            app.ExportCsvButton.Layout.Column = [9 13];
            app.ExportCsvButton.Text = 'Export to .csv';
            app.ExportCsvButton.Enable = 'off';
            app.ExportCsvButton.ButtonPushedFcn = createCallbackFcn(app, @ExportButtonPushed, true);

            % Create SaveFileButton
            app.SaveFileButton = uibutton(app.GridLayout, 'push');
            app.SaveFileButton.Layout.Row = [7 8];
            app.SaveFileButton.Layout.Column = [9 13];
            app.SaveFileButton.Text = 'Save File';
            app.SaveFileButton.Enable = 'off';
            app.SaveFileButton.ButtonPushedFcn = createCallbackFcn(app, @SaveButtonPushed, true);
            
            % Create UIAxesImageOrder0
            app.UIAxesImageOrder0 = uiaxes(app.GridLayout);
            title(app.UIAxesImageOrder0, '0th Order Image')
            app.UIAxesImageOrder0.XTick = [];
            app.UIAxesImageOrder0.YTick = [];
            app.UIAxesImageOrder0.Box = 'on';
            app.UIAxesImageOrder0.Layout.Row = 3;
            app.UIAxesImageOrder0.Layout.Column = [1 7];
            
            % Create UIAxesImageOrder1
            app.UIAxesImageOrder1 = uiaxes(app.GridLayout);
            title(app.UIAxesImageOrder1, '1st Order Image')
            app.UIAxesImageOrder1.XTick = [];
            app.UIAxesImageOrder1.YTick = [];
            app.UIAxesImageOrder1.Box = 'on';
            app.UIAxesImageOrder1.Layout.Row = 3;
            app.UIAxesImageOrder1.Layout.Column = [8 14];
            
            % Create UIAxesFWHMvsZ
            app.UIAxesFWHMvsZ = uiaxes(app.GridLayout);
            title(app.UIAxesFWHMvsZ, 'FWHM vs Z')
            xlabel(app.UIAxesFWHMvsZ, 'Z Position (nm)')
            ylabel(app.UIAxesFWHMvsZ, 'FWHM (nm)')
            app.UIAxesFWHMvsZ.Box = 'on';
            app.UIAxesFWHMvsZ.Layout.Row = 4;
            app.UIAxesFWHMvsZ.Layout.Column = [1 7];
            xlim(app.UIAxesFWHMvsZ, [app.global_z_min app.global_z_max]);
            
            % Create UIAxesCaliCurve
            app.UIAxesCaliCurve = uiaxes(app.GridLayout);
            title(app.UIAxesCaliCurve, 'Calibration Curve')
            xlabel(app.UIAxesCaliCurve, 'Z Position (nm)')
            ylabel(app.UIAxesCaliCurve, 'FWHM Ratio')
            app.UIAxesCaliCurve.Box = 'on';
            app.UIAxesCaliCurve.Layout.Row = 4;
            app.UIAxesCaliCurve.Layout.Column = [8 14];
            
            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end
    
    % App creation and deletion
    methods (Access = public)
        
        % Construct app
        function app = AxialCalibrationLegacy

            startupFcn(app)

            % Create UIFigure and components
            createComponents(app)
            
            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            addpath(fullfile(pwd,'lib/bioformats_tools'));
            addpath(fullfile(pwd,'lib'));
            
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
        CalibrationFileSaved  % Event sent when the calibration file is saved
    end
end