classdef AxialCalibration < matlab.apps.AppBase
    
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

        % New sliders for R2023b, commented out for compatibility with earlier versions
        Z0RangeSlider               % matlab.ui.control.RangeSlider
        Z1RangeSlider               % matlab.ui.control.RangeSlider

        ExportCsvButton             matlab.ui.control.Button
        SaveFileButton              matlab.ui.control.Button

        UIAxesImageOrder0           matlab.ui.control.UIAxes
        UIAxesImageOrder1           matlab.ui.control.UIAxes
        UIAxesFWHMvsZ               matlab.ui.control.UIAxes
        UIAxesCaliCurve             matlab.ui.control.UIAxes
    end
    
    % Properties that correspond to app components
    properties (Access = private)
        MATLAB_VERSION_OLDER_THAN_2023B

        image0
        image1
        image0_mean
        image1_mean

        roi_height = 13
        roi_width = 21

        localizations
        localization_selected = 1
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
            % Check MATLAB version
            if isMATLABReleaseOlderThan('R2023a')
                app.MATLAB_VERSION_OLDER_THAN_2023B = true;
            end

            app.px_size = 110;
            app.z_step = 20;
            app.global_z_num = 200;
            app.global_z_min = - app.global_z_num / 2 * app.z_step;
            app.global_z_max = app.global_z_num / 2 * app.z_step;
        end
        
        function LoadButtonPushed(app, ~)
            [file,path] = uigetfile({'*.nd2;*.tif;*.tiff','Supported Filetypes (*.nd2, *.tif)'}, 'Select the .nd2 or .tif file');

            % check if the user canceled the file selection
            if file == 0
                return
            end

            figure(app.UIFigure);
            app.dir_inputpath = fullfile(path,file);
            app.LoadImage(app);
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
            if app.MATLAB_VERSION_OLDER_THAN_2023B
                app.MinZ0Slider.Enable = 'on';
                app.MaxZ0Slider.Enable = 'on';
                app.MinZ1Slider.Enable = 'on';
                app.MaxZ1Slider.Enable = 'on';
            else
                app.Z0RangeSlider.Enable = 'on';
                app.Z1RangeSlider.Enable = 'on';
            end
        end

        function MoleculeDropDownValueChanged(app, ~)
            app.localization_selected = str2double(app.MoleculeDropDown.Value);
            app.PreviewImage(app);
            app.ProcessFile(app);
            app.UpdateUIAxesFWHMvsZ(app);
        end

        function ZFieldValueChanged(app, event)
            CopyZFieldsToZSliders(app, event);
            UpdateUIAxesFWHMvsZ(app);
            UpdateUIAxesCaliCurve(app);
        end
        
        function PixelSizeFieldValueChanged(app, ~)
            app.px_size = app.PixelSizeField.Value;
            UpdateUIAxesFWHMvsZ(app);
            UpdateUIAxesCaliCurve(app);
        end

        function ZStepFieldValueChanged(app, ~)
            old_z_step = app.z_step;
            app.z_step = app.ZStepField.Value;

            % update the global z_min and z_max
            app.global_z_min = -app.global_z_num / 2 * app.z_step;
            app.global_z_max = app.global_z_num / 2 * app.z_step;

            % update the z0 and z1 sliders
            app.Z0RangeSlider.Value = app.Z0RangeSlider.Value .* (app.z_step / old_z_step);
            app.Z1RangeSlider.Value = app.Z1RangeSlider.Value .* (app.z_step / old_z_step);

            % update the range of the z0 and z1 sliders
            app.Z0RangeSlider.Limits = [app.global_z_min app.global_z_max];
            app.Z1RangeSlider.Limits = [app.global_z_min app.global_z_max];

            % update the value of the z0 and z1 sliders
            CopyZSlidersToZFields(app, []);
            UpdateUIAxesFWHMvsZ(app);
            UpdateUIAxesCaliCurve(app);

            xlim(app.UIAxesFWHMvsZ, [app.global_z_min app.global_z_max]);
        end
        
        function CopyZSlidersToZFields(app, event)
            if app.MATLAB_VERSION_OLDER_THAN_2023B
                if isempty(event)
                    app.MinZ0Field.Value = round(app.MinZ0Slider.Value);
                    app.MaxZ0Field.Value = round(app.MaxZ0Slider.Value);
                    app.MinZ1Field.Value = round(app.MinZ1Slider.Value);
                    app.MaxZ1Field.Value = round(app.MaxZ1Slider.Value);
                elseif event.Source.Tag == "MinZ0Slider"
                    app.MinZ0Field.Value = round(app.MinZ0Slider.Value);
                elseif event.Source.Tag == "MaxZ0Slider"
                    app.MaxZ0Field.Value = round(app.MaxZ0Slider.Value);
                elseif event.Source.Tag == "MinZ1Slider"
                    app.MinZ1Field.Value = round(app.MinZ1Slider.Value);
                elseif event.Source.Tag == "MaxZ1Slider"
                    app.MaxZ1Field.Value = round(app.MaxZ1Slider.Value);
                end
            else
                if isempty(event)
                    app.MinZ0Field.Value = round(app.Z0RangeSlider.Value(1));
                    app.MaxZ0Field.Value = round(app.Z0RangeSlider.Value(2));
                    app.MinZ1Field.Value = round(app.Z1RangeSlider.Value(1));
                    app.MaxZ1Field.Value = round(app.Z1RangeSlider.Value(2));
                elseif event.Source.Tag == "Z0RangeSlider"
                    app.MinZ0Field.Value = round(app.Z0RangeSlider.Value(1));
                    app.MaxZ0Field.Value = round(app.Z0RangeSlider.Value(2));
                elseif event.Source.Tag == "Z1RangeSlider"
                    app.MinZ1Field.Value = round(app.Z1RangeSlider.Value(1));
                    app.MaxZ1Field.Value = round(app.Z1RangeSlider.Value(2));
                end
            end
        end

        function CopyZFieldsToZSliders(app, event)
            app.MinZ0Field.Value = round(app.MinZ0Field.Value);
            app.MaxZ0Field.Value = round(app.MaxZ0Field.Value);
            app.MinZ1Field.Value = round(app.MinZ1Field.Value);
            app.MaxZ1Field.Value = round(app.MaxZ1Field.Value);

            if app.MATLAB_VERSION_OLDER_THAN_2023B
                if isempty(event)
                    app.MinZ0Slider.Value = app.MinZ0Field.Value;
                    app.MaxZ0Slider.Value = app.MaxZ0Field.Value;
                    app.MinZ1Slider.Value = app.MinZ1Field.Value;
                    app.MaxZ1Slider.Value = app.MaxZ1Field.Value;
                elseif event.Source.Tag == "MinZ0Field"
                    app.MinZ0Slider.Value = app.MinZ0Field.Value;
                elseif event.Source.Tag == "MaxZ0Field"
                    app.MaxZ0Slider.Value = app.MaxZ0Field.Value;
                elseif event.Source.Tag == "MinZ1Field"
                    app.MinZ1Slider.Value = app.MinZ1Field.Value;
                elseif event.Source.Tag == "MaxZ1Field"
                    app.MaxZ1Slider.Value = app.MaxZ1Field.Value;
                end
            else
                if isempty(event)
                    app.Z0RangeSlider.Value = [app.MinZ0Field.Value app.MaxZ0Field.Value];
                    app.Z1RangeSlider.Value = [app.MinZ1Field.Value app.MaxZ1Field.Value];
                elseif event.Source.Tag == "MinZ0Field" || event.Source.Tag == "MaxZ0Field"
                    app.Z0RangeSlider.Value = [app.MinZ0Field.Value app.MaxZ0Field.Value];
                elseif event.Source.Tag == "MinZ1Field" || event.Source.Tag == "MaxZ1Field"
                    app.Z1RangeSlider.Value = [app.MinZ1Field.Value app.MaxZ1Field.Value];
                end
            end
        end

        function ZSliderValueChanging(app, event)
            changingValue = event.Value;
            if app.MATLAB_VERSION_OLDER_THAN_2023B
                if event.Source.Tag == "MinZ0Slider"
                    app.MinZ0Field.Value = round(changingValue);
                elseif event.Source.Tag == "MaxZ0Slider"
                    app.MaxZ0Field.Value = round(changingValue);
                elseif event.Source.Tag == "MinZ1Slider"
                    app.MinZ1Field.Value = round(changingValue);
                elseif event.Source.Tag == "MaxZ1Slider"
                    app.MaxZ1Field.Value = round(changingValue);
                end
            else
                if event.Source.Tag == "Z0RangeSlider"
                    app.MinZ0Field.Value = round(changingValue(1));
                    app.MaxZ0Field.Value = round(changingValue(2));
                elseif event.Source.Tag == "Z1RangeSlider"
                    app.MinZ1Field.Value = round(changingValue(1));
                    app.MaxZ1Field.Value = round(changingValue(2));
                end
            end
            UpdateUIAxesFWHMvsZ(app);
            UpdateUIAxesCaliCurve(app);
        end

        function FlipImagesButtonPushed(app, ~)
            image0_temp = app.image0;
            image0_mean_temp = app.image0_mean;

            app.image0 = flip(app.image1,2);
            app.image1 = flip(image0_temp,2);
            app.image0_mean = flip(app.image1_mean,2);
            app.image1_mean = flip(image0_mean_temp,2);

            app.PreviewImage(app);
            app.ProcessFile(app);
            app.UpdateUIAxesFWHMvsZ(app);
        end
        
        function ExportButtonPushed(app, ~)
            % let the user pick where to put the file
            [file,path] = uiputfile({'*.csv','Comma-separated files (*.csv)'}, ...
                'Save the calibration file as', 'axialcali.csv');
            app.dir_csvfile = fullfile(path,file);
            
            if path == 0
                return
            end

            cali_array = [app.z_simulated;app.ratio];
            cali_array = cali_array';
            dlmwrite(app.dir_csvfile,cali_array);
        end

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

    % main functions that the code uses
    methods (Access = private)

        function LoadImage(app, ~)
            % parse the type of file extension
            % [~,~,ext] = fileparts(app.dir_inputpath);

            img = bfOpen3DVolume(app.dir_inputpath);
            if isnumeric(img{1}{1})
                img = img{1}{1};
            end

            img = squeeze(img);
            app.global_z_num = size(img,3);

            [~, im_width, im_depth] = size(img);
            
            % split the image into two parts
            im_left = mean(img(:,1:round(im_width/2),:),3);
            im_right = mean(img(:,(round(im_width/2)+1):end,:),3);
            im_left_raw = img(:,1:round(im_width/2),:);
            im_right_raw = img(:,(round(im_width/2)+1):end,:);

            % perform baseline subtraction
            im_left = im_left - min(im_left(:));
            im_right = im_right - min(im_right(:));

            % align the two images using the cross-correlation method
            im_corr = normxcorr2(im_left, im_right);
            [~, im_shift] = max(im_corr(:));
            [im_shift_row, im_shift_col] = ind2sub(size(im_corr), im_shift);
    
            % calculate the shift between the two images
            im_shift_row = size(im_left, 1) - im_shift_row;
            im_shift_col = size(im_left, 2) - im_shift_col;

            % shift the right image
            im_right_shift = circshift(im_right, [im_shift_row, im_shift_col]);
            im_right_shift_raw = zeros(size(im_right_raw));
            for i_z = 1:im_depth
                im_right_shift_raw(:,:,i_z) = circshift(im_right_raw(:,:,i_z), [im_shift_row, im_shift_col]);
            end

            % compute the roi
            if im_shift_row < 0
                roi_y = 1;
                roi_h = size(im_left, 1) + im_shift_row;
            elseif im_shift_row > 0
                roi_y = im_shift_row + 1;
                roi_h = size(im_left, 1) - im_shift_row;
            else
                roi_y = 1;
                roi_h = size(im_left, 1);
            end
            
            if im_shift_col < 0
                roi_x = 1;
                roi_w = size(im_left, 2) + im_shift_col;
            elseif im_shift_col > 0
                roi_x = im_shift_col + 1;
                roi_w = size(im_left, 2) - im_shift_col;
            else
                roi_x = 1;
                roi_w = size(im_left, 2);
            end

            % crop the region of interest to the region that overlaps
            im_left_crop = im_left(roi_y:roi_y+roi_h-1, roi_x:roi_x+roi_w-1);
            im_right_crop = im_right_shift(roi_y:roi_y+roi_h-1, roi_x:roi_x+roi_w-1);
            im_left_crop_raw = im_left_raw(roi_y:roi_y+roi_h-1, roi_x:roi_x+roi_w-1, :);
            im_right_crop_raw = im_right_shift_raw(roi_y:roi_y+roi_h-1, roi_x:roi_x+roi_w-1, :);

            % update the image properties to the cropped images
            app.image0 = im_left_crop_raw;
            app.image1 = im_right_crop_raw;
            app.image0_mean = im_left_crop;
            app.image1_mean = im_right_crop;
        end

        function PreviewImage(app, ~)
            img0 = app.image0_mean;
            img1 = app.image1_mean;

            pks0 = fastPeakFind(img0, 50);
            pks0 = [pks0(1:2:end), pks0(2:2:end)];
            pks1 = fastPeakFind(img1, 50);
            pks1 = [pks1(1:2:end), pks1(2:2:end)];

            cla(app.UIAxesImageOrder0);
            imagesc(app.UIAxesImageOrder0, img0);
            axis(app.UIAxesImageOrder0, 'image');
            hold(app.UIAxesImageOrder0, 'on');
            sel = app.localization_selected;
            notsel = setdiff(1:size(pks1,1),sel);
            plot(app.UIAxesImageOrder0, pks0(notsel,1), pks0(notsel,2), '*r');
            plot(app.UIAxesImageOrder0, pks0(sel,1), pks0(sel,2),'*g');
            for ii = 1:size(pks0,1)
                if ii == app.localization_selected
                    col = 'g';
                else
                    col = 'r';
                end
                rectangle(app.UIAxesImageOrder0, 'Position', ...
                    [pks0(ii,1)-app.roi_height/2, pks0(ii,2)-app.roi_height/2, ...
                    app.roi_height, app.roi_height], 'EdgeColor', col);
            end
            hold(app.UIAxesImageOrder0, 'off');

            cla(app.UIAxesImageOrder1);
            imagesc(app.UIAxesImageOrder1, img1);
            axis(app.UIAxesImageOrder1, 'image');
            hold(app.UIAxesImageOrder1, 'on');
            sel = app.localization_selected;
            notsel = setdiff(1:size(pks1,1),sel);
            plot(app.UIAxesImageOrder1, pks1(notsel,1), pks1(notsel,2), '*r');
            plot(app.UIAxesImageOrder1, pks1(sel,1), pks1(sel,2),'*g');
            for ii = 1:size(pks1,1)
                if ii == app.localization_selected
                    col = 'g';
                else
                    col = 'r';
                end
                rectangle(app.UIAxesImageOrder1,'Position',...
                    [pks1(ii,1)-app.roi_width/2, pks1(ii,2)-app.roi_height/2, ...
                    app.roi_width, app.roi_height],'EdgeColor',col);
                text(app.UIAxesImageOrder1,...
                    pks1(ii,1)+app.roi_width, pks1(ii,2)-app.roi_height/2, ...
                    sprintf('%d',ii), 'Color', col, 'FontSize', 12);
            end
            hold(app.UIAxesImageOrder1, 'off');

            if size(pks0) ~= size(pks1)
                app.localizations = nan(1,4);
            else
                app.localizations = [pks0, pks1];
            end

            if size(app.localizations,1) > 1
                % enable the select molecule dropdown
                app.MoleculeDropDown.Enable = 'on';
                app.MoleculeDropDownLabel.Enable = 'on';
                % update the dropdown items
                app.MoleculeDropDown.Items = cellstr(num2str((1:size(app.localizations,1))'));
            end
        end

        function ProcessFile(app, ~)
            if any(isnan(app.localizations))
                return
            end
            
            num_frames = app.global_z_num;
            locs = app.localizations;
            px0 = locs(app.localization_selected,1);
            py0 = locs(app.localization_selected,2);
            px1 = locs(app.localization_selected,3);
            py1 = locs(app.localization_selected,4);
            w0 = floor(app.roi_height / 2);
            w1 = floor(app.roi_width / 2);
            
            fwhm0_ = zeros(num_frames,1);
            fwhm1_ = zeros(num_frames,1);

            options = optimset('display','off','TolFun',1e-10,'LargeScale','off');

            for i_frame = 1:num_frames
                im0_roi = app.image0((-w0:w0)+py0,(-w0:w0)+px0,i_frame);
                im0_sum = sum(im0_roi,2);
                im0_sum = im0_sum - min(im0_sum);
                y0 = (1:size(im0_sum,1))';
                cy0 = sum(im0_sum.*y0)/sum(im0_sum); % center of mass
                sy0 = sqrt(sum(im0_sum.*(abs(y0-cy0).^2))/sum(im0_sum)); % standard deviation
                amp0 = max(im0_sum); % amplitude
                p0 = [cy0,sy0,amp0];
                fp0 = fminunc(@fitgaussian1D,p0,options,im0_sum,y0);
                fwhm0_(i_frame) = fp0(2)*2.355;

                im1_roi = app.image1((-w0:w0)+py1,(-w1:w1)+px1,i_frame);
                im1_sum = sum(im1_roi,2);
                im1_sum = im1_sum - min(im1_sum);
                y1 = (1:size(im1_sum,1))';
                cy1 = sum(im1_sum.*y1)/sum(im1_sum); % center of mass
                sy1 = sqrt(sum(im1_sum.*(abs(y1-cy1).^2))/sum(im1_sum)); % standard deviation
                amp1 = max(im1_sum); % amplitude
                p1 = [cy1,sy1,amp1];
                fp1 = fminunc(@fitgaussian1D,p1,options,im1_sum,y1);
                fwhm1_(i_frame) = fp1(2)*2.355;
            end

            app.z = -((num_frames-1)/2):((num_frames-1)/2);
            app.fwhm0 = fwhm0_;
            app.fwhm1 = fwhm1_;
        end

        function UpdateUIAxesFWHMvsZ(app, ~)
            z_ = app.z * app.z_step;
            idx_minz0 = find(z_ >= app.MinZ0Field.Value,1,'first');
            idx_maxz0 = find(z_ <= app.MaxZ0Field.Value,1,'last');
            idx_minz1 = find(z_ >= app.MinZ1Field.Value,1,'first');
            idx_maxz1 = find(z_ <= app.MaxZ1Field.Value,1,'last');

            z0 = app.z(idx_minz0:idx_maxz0)*app.z_step;
            z1 = app.z(idx_minz1:idx_maxz1)*app.z_step;
            fwhm0_ = app.fwhm0(idx_minz0:idx_maxz0)*app.px_size;
            fwhm1_ = app.fwhm1(idx_minz1:idx_maxz1)*app.px_size;

            cla(app.UIAxesFWHMvsZ);
            hold(app.UIAxesFWHMvsZ,'on');
            plot(app.UIAxesFWHMvsZ,z0,fwhm0_,'ob','MarkerSize',4);
            plot(app.UIAxesFWHMvsZ,z1,fwhm1_,'or','MarkerSize',4);
            hold(app.UIAxesFWHMvsZ,'off');
            ylim(app.UIAxesFWHMvsZ,[300,1200]);

            app.z_simulated = app.global_z_min:app.global_z_max;
            if length(z1) < 3
                app.simulated1 = nan;
            else
                f1 = polyfit(z1,fwhm1_',2);
                app.simulated1 = f1(1).*app.z_simulated.^2+f1(2)*app.z_simulated+f1(3);
                hold(app.UIAxesFWHMvsZ,'on');
                plot(app.UIAxesFWHMvsZ,app.z_simulated,app.simulated1,'r');
                hold(app.UIAxesFWHMvsZ,'off');
            end

            if length(z0) < 3
                app.simulated0 = nan;
            else
                f0 = polyfit(z0,fwhm0_',2);
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

            % ratio = app.simulated1./app.simulated0;
            ratio_ = axialf(app,app.simulated0,app.simulated1);

            max_ratio = find(islocalmax(ratio_));
            min_ratio = find(islocalmin(ratio_));
            ratio_ = ratio_(max_ratio:min_ratio);
            z_simulated_ = app.z_simulated(max_ratio:min_ratio);

            plot(app.UIAxesCaliCurve,z_simulated_,ratio_,'k');
            app.ratio = ratio_;
            app.z_simulated = z_simulated_;

            app.ExportCsvButton.Enable = 'on';
            app.SaveFileButton.Enable = 'on';
        end
        
        function F = axialf(~,wn,wp)
            F = (wp.*wp-wn.*wn)./(wp.*wp+wn.*wn);
        end


    end
    
    % Component initialization
    methods (Access = private)
        
        % Create UIFigure and components
        function createComponents(app)
            
            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 720 600];
            app.UIFigure.Name = 'Axial Calibration';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {50, '1x', '1x', '1x', '1x', '1x', 50, 50, '1x', '1x', '1x', '1x', '1x', 50};
            if app.MATLAB_VERSION_OLDER_THAN_2023B
                app.GridLayout.RowHeight = {25, 25, '1x', '1x', 25, 25, 25, 25};
            else
                app.GridLayout.RowHeight = {25, 25, '1x', '1x', 'fit', 22, 'fit', 22};
            end
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
            app.FlipImagesButton.ButtonPushedFcn = createCallbackFcn(app, @FlipImagesButtonPushed, true);

            % Create MoleculeDropDownLabel
            app.MoleculeDropDownLabel = uilabel(app.GridLayout);
            app.MoleculeDropDownLabel.HorizontalAlignment = 'right';
            app.MoleculeDropDownLabel.Layout.Row = 2;
            app.MoleculeDropDownLabel.Layout.Column = [8 9];
            app.MoleculeDropDownLabel.Text = 'Molecule #';
            app.MoleculeDropDownLabel.Enable = 'off';
            
            % Create MoleculeDropDown
            app.MoleculeDropDown = uidropdown(app.GridLayout);
            app.MoleculeDropDown.Items = {'1'};
            app.MoleculeDropDown.Layout.Row = 2;
            app.MoleculeDropDown.Layout.Column = 10;
            app.MoleculeDropDown.Value = '1';
            app.MoleculeDropDown.Enable = 'off';
            app.MoleculeDropDown.ValueChangedFcn = createCallbackFcn(app, @MoleculeDropDownValueChanged, true);

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
            if app.MATLAB_VERSION_OLDER_THAN_2023B
                app.MinZ0Field.Layout.Row = 5;
                app.MinZ0Field.Layout.Column = 7;
            else
                app.MinZ0Field.Layout.Row = 6;
                app.MinZ0Field.Layout.Column = 1;
            end
            app.MinZ0Field.Tag = 'MinZ0Field';
            app.MinZ0Field.Value = app.global_z_min;
            app.MinZ0Field.ValueChangedFcn = createCallbackFcn(app, @ZFieldValueChanged, true);

            % Create MaxZ0Label
            app.MaxZ0Label = uilabel(app.GridLayout);
            app.MaxZ0Label.HorizontalAlignment = 'right';
            app.MaxZ0Label.VerticalAlignment = 'center';
            app.MaxZ0Label.FontColor = [0 0 1];
            app.MaxZ0Label.Enable = 'off';
            if app.MATLAB_VERSION_OLDER_THAN_2023B
                app.MaxZ0Label.Layout.Row = 6;
                app.MaxZ0Label.Layout.Column = 1;
            else
                app.MaxZ0Label.Layout.Row = 5;
                app.MaxZ0Label.Layout.Column = 7;
            end
            app.MaxZ0Label.Text = 'Max Z0';
            
            % Create MaxZ0Field
            app.MaxZ0Field = uieditfield(app.GridLayout, 'numeric');
            app.MaxZ0Field.FontColor = [0 0 1];
            app.MaxZ0Field.Enable = 'off';
            app.MaxZ0Field.Layout.Row = 6;
            app.MaxZ0Field.Layout.Column = 7;
            app.MaxZ0Field.Tag = 'MaxZ0Field';
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
            if app.MATLAB_VERSION_OLDER_THAN_2023B
                app.MinZ1Field.Layout.Row = 7;
                app.MinZ1Field.Layout.Column = 7;
            else
                app.MinZ1Field.Layout.Row = 8;
                app.MinZ1Field.Layout.Column = 1;
            end
            app.MinZ1Field.Tag = 'MinZ1Field';
            app.MinZ1Field.Value = app.global_z_min;
            app.MinZ1Field.ValueChangedFcn = createCallbackFcn(app, @ZFieldValueChanged, true);

            % Create MaxZ1Label
            app.MaxZ1Label = uilabel(app.GridLayout);
            app.MaxZ1Label.HorizontalAlignment = 'right';
            app.MaxZ1Label.VerticalAlignment = 'center';
            app.MaxZ1Label.FontColor = [1 0 0];
            app.MaxZ1Label.Enable = 'off';
            if app.MATLAB_VERSION_OLDER_THAN_2023B
                app.MaxZ1Label.Layout.Row = 8;
                app.MaxZ1Label.Layout.Column = 1;
            else
                app.MaxZ1Label.Layout.Row = 7;
                app.MaxZ1Label.Layout.Column = 7;
            end
            app.MaxZ1Label.Text = 'Max Z1';

            % Create MaxZ1Field
            app.MaxZ1Field = uieditfield(app.GridLayout, 'numeric');
            app.MaxZ1Field.FontColor = [1 0 0];
            app.MaxZ1Field.Enable = 'off';
            app.MaxZ1Field.Layout.Row = 8;
            app.MaxZ1Field.Layout.Column = 7;
            app.MaxZ1Field.Tag = 'MaxZ1Field';
            app.MaxZ1Field.Value = app.global_z_max;
            app.MaxZ1Field.ValueChangedFcn = createCallbackFcn(app, @ZFieldValueChanged, true);

            if app.MATLAB_VERSION_OLDER_THAN_2023B
                % Create MaxZ1Slider
                app.MaxZ1Slider = uislider(app.GridLayout);
                app.MaxZ1Slider.MajorTicks = [];
                app.MaxZ1Slider.MinorTicks = [];
                app.MaxZ1Slider.Enable = 'off';
                app.MaxZ1Slider.Layout.Row = 8;
                app.MaxZ1Slider.Layout.Column = [2 6];
                app.MaxZ1Slider.Limits = [app.global_z_min app.global_z_max];
                app.MaxZ1Slider.Tag = 'MaxZ1Slider';
                app.MaxZ1Slider.Value = app.global_z_max;
                app.MaxZ1Slider.ValueChangingFcn = createCallbackFcn(app, @ZSliderValueChanging, true);

                % Create MinZ1Slider
                app.MinZ1Slider = uislider(app.GridLayout);
                app.MinZ1Slider.MajorTicks = [];
                app.MinZ1Slider.MinorTicks = [];
                app.MinZ1Slider.Enable = 'off';
                app.MinZ1Slider.Layout.Row = 7;
                app.MinZ1Slider.Layout.Column = [2 6];
                app.MinZ1Slider.Limits = [app.global_z_min app.global_z_max];
                app.MinZ1Slider.Tag = 'MinZ1Slider';
                app.MinZ1Slider.Value = app.global_z_min;
                app.MinZ1Slider.ValueChangingFcn = createCallbackFcn(app, @ZSliderValueChanging, true);

                % Create MaxZ0Slider
                app.MaxZ0Slider = uislider(app.GridLayout);
                app.MaxZ0Slider.MajorTicks = [];
                app.MaxZ0Slider.MinorTicks = [];
                app.MaxZ0Slider.Enable = 'off';
                app.MaxZ0Slider.Layout.Row = 6;
                app.MaxZ0Slider.Layout.Column = [2 6];
                app.MaxZ0Slider.Limits = [app.global_z_min app.global_z_max];
                app.MaxZ0Slider.Tag = 'MaxZ0Slider';
                app.MaxZ0Slider.Value = app.global_z_max;
                app.MaxZ0Slider.ValueChangingFcn = createCallbackFcn(app, @ZSliderValueChanging, true);

                % Create MinZ0Slider
                app.MinZ0Slider = uislider(app.GridLayout);
                app.MinZ0Slider.MajorTicks = [];
                app.MinZ0Slider.MinorTicks = [];
                app.MinZ0Slider.Enable = 'off';
                app.MinZ0Slider.Layout.Row = 5;
                app.MinZ0Slider.Layout.Column = [2 6];
                app.MinZ0Slider.Limits = [app.global_z_min app.global_z_max];
                app.MinZ0Slider.Tag = 'MinZ0Slider';
                app.MinZ0Slider.Value = app.global_z_min;
                app.MinZ0Slider.ValueChangingFcn = createCallbackFcn(app, @ZSliderValueChanging, true);

            else
                % Create Z0RangeSlider
                app.Z0RangeSlider = uislider(app.GridLayout, 'range');
                app.Z0RangeSlider.MajorTicks = [];
                app.Z0RangeSlider.MinorTicks = [];
                app.Z0RangeSlider.Enable = 'off';
                app.Z0RangeSlider.Layout.Row = [5 6];
                app.Z0RangeSlider.Layout.Column = [2 6];
                app.Z0RangeSlider.Limits = [app.global_z_min app.global_z_max];
                app.Z0RangeSlider.Tag = 'Z0RangeSlider';
                app.Z0RangeSlider.Value = [app.global_z_min app.global_z_max];
                app.Z0RangeSlider.ValueChangingFcn = createCallbackFcn(app, @ZSliderValueChanging, true);

                % Create Z1RangeSlider
                app.Z1RangeSlider = uislider(app.GridLayout, 'range');
                app.Z1RangeSlider.MajorTicks = [];
                app.Z1RangeSlider.MinorTicks = [];
                app.Z1RangeSlider.Enable = 'off';
                app.Z1RangeSlider.Layout.Row = [7 8];
                app.Z1RangeSlider.Layout.Column = [2 6];
                app.Z1RangeSlider.Limits = [app.global_z_min app.global_z_max];
                app.Z1RangeSlider.Tag = 'Z1RangeSlider';
                app.Z1RangeSlider.Value = [app.global_z_min app.global_z_max];
                app.Z1RangeSlider.ValueChangingFcn = createCallbackFcn(app, @ZSliderValueChanging, true);
            end

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
        function app = AxialCalibration

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