classdef ImageEnhancementApp < handle
    % ImageEnhancementApp - Aplikasi MATLAB berbasis GUI untuk Image Enhancement
    % IF4073 Pemrosesan Citra Digital - Tugas 1
    %
    % Teknik yang diimplementasikan:
    %   1. Intensity Transformation (Negative, Gamma/Power-law, Log, Linear Stretch)
    %   2. Histogram Equalization  (custom, tanpa histeq)
    %   3. Histogram Specification / Matching  (custom, tanpa imhistmatch)
    %   4. Image Filtering dengan Masking (Averaging, Gaussian, Sharpening, Median)
    %      - semua diimplementasikan sendiri, tanpa imfilter/medfilt2
    %
    % Fungsi custom yang digunakan:  myHist.m, imgFeatures.m

    properties (Access = private)
        Fig; MainGrid
        InputImage; EnhancedImage; ReferenceImage
        FolderDropdown; FileDropdown; LoadBtn; LoadRefBtn
        MethodDropdown; ParamPanel; ParamGrid
        ITTypeDropdown; GammaField; CField
        LowInField; HighInField; LowOutField; HighOutField
        HistSpecTypeDropdown; HSMeanField; HSStdField; HSLowField; HSHighField
        FilterTypeDropdown; KernelSizeField; SigmaField; SharpenAlphaField
        ApplyBtn; SaveBtn
        AxInputImg; AxInputHist; AxEnhImg; AxEnhHist
        FeatInputLabel; FeatEnhLabel
        StatusLabel
        DataRoot
        CurrentFolderPath   % resolved absolute path of selected folder
    end

    methods (Access = public)
        function app = ImageEnhancementApp()
            % Inisialisasi aplikasi
            app.DataRoot = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'data');
            app.buildUI();
            app.updateFolderList();
            app.Fig.Visible = 'on';
        end
    end

    %% ---- UI Construction -----------------------------------------------
    methods (Access = private)

        function buildUI(app)
            app.Fig = uifigure('Name', 'Image Enhancement - IF4073 PCD', ...
                'Position', [40 40 1400 830], ...
                'Color', [0.11 0.11 0.14], ...
                'Visible', 'off', ...
                'CloseRequestFcn', @(~,~) app.onClose());
            app.MainGrid = uigridlayout(app.Fig, [1 3]);
            app.MainGrid.ColumnWidth   = {'1.2x','0.8x','2x'};
            app.MainGrid.RowHeight     = {'1x'};
            app.MainGrid.Padding       = [10 10 10 10];
            app.MainGrid.ColumnSpacing = 10;
            app.MainGrid.BackgroundColor = [0.11 0.11 0.14];
            app.buildLeftPanel();
            app.buildMiddlePanel();
            app.buildRightPanel();
        end

        % ---- Left panel -------------------------------------------------
        function buildLeftPanel(app)
            p = uipanel(app.MainGrid, 'Title', 'Kontrol', ...
                'FontSize', 13, 'FontWeight', 'bold', ...
                'ForegroundColor', [0.9 0.9 0.9], ...
                'BackgroundColor', [0.16 0.16 0.20], 'BorderType', 'line');
            p.Layout.Column = 1;

            g = uigridlayout(p, [16 2]);
            g.RowHeight = {22,22,22,22,22,8,22,22,'1x',22,22,22,22,22,22,22};
            g.ColumnWidth = {'1x','1x'};
            g.Padding = [10 10 10 10];
            g.RowSpacing = 6;
            g.BackgroundColor = [0.16 0.16 0.20];

            % -- Folder selection --
            lb1 = uilabel(g,'Text','Folder Dataset:','FontColor',[0.75 0.75 0.75],'FontSize',10);
            lb1.Layout.Row=1; lb1.Layout.Column=[1 2];
            app.FolderDropdown = uidropdown(g,'Items',{}, ...
                'ValueChangedFcn',@(~,~)app.onFolderChanged(), ...
                'BackgroundColor',[0.22 0.22 0.28],'FontColor',[0.95 0.95 0.95]);
            app.FolderDropdown.Layout.Row=2; app.FolderDropdown.Layout.Column=[1 2];

            % -- File selection --
            lb2 = uilabel(g,'Text','File Citra:','FontColor',[0.75 0.75 0.75],'FontSize',10);
            lb2.Layout.Row=3; lb2.Layout.Column=[1 2];
            app.FileDropdown = uidropdown(g,'Items',{}, ...
                'BackgroundColor',[0.22 0.22 0.28],'FontColor',[0.95 0.95 0.95]);
            app.FileDropdown.Layout.Row=4; app.FileDropdown.Layout.Column=[1 2];

            % -- Load buttons --
            app.LoadBtn = uibutton(g,'Text','Muat Citra', ...
                'ButtonPushedFcn',@(~,~)app.onLoadImage(), ...
                'BackgroundColor',[0.18 0.48 0.78],'FontColor',[1 1 1],'FontWeight','bold');
            app.LoadBtn.Layout.Row=5; app.LoadBtn.Layout.Column=1;

            app.LoadRefBtn = uibutton(g,'Text','Muat Referensi', ...
                'ButtonPushedFcn',@(~,~)app.onLoadReference(), ...
                'BackgroundColor',[0.30 0.30 0.40],'FontColor',[1 1 1]);
            app.LoadRefBtn.Layout.Row=5; app.LoadRefBtn.Layout.Column=2;

            % Divider
            sep = uilabel(g,'Text','','BackgroundColor',[0.32 0.32 0.42]);
            sep.Layout.Row=6; sep.Layout.Column=[1 2];

            % -- Method --
            lb3 = uilabel(g,'Text','Metode Enhancement:','FontColor',[0.75 0.75 0.75],'FontSize',10);
            lb3.Layout.Row=7; lb3.Layout.Column=[1 2];
            app.MethodDropdown = uidropdown(g, ...
                'Items',{'Intensity Transformation','Histogram Equalization', ...
                         'Histogram Specification','Image Filtering'}, ...
                'ValueChangedFcn',@(~,~)app.onMethodChanged(), ...
                'BackgroundColor',[0.22 0.22 0.28],'FontColor',[0.95 0.95 0.95]);
            app.MethodDropdown.Layout.Row=8; app.MethodDropdown.Layout.Column=[1 2];

            % -- Parameter panel --
            app.ParamPanel = uipanel(g,'Title','Parameter', ...
                'FontSize',11,'FontWeight','bold', ...
                'ForegroundColor',[0.85 0.85 0.85], ...
                'BackgroundColor',[0.18 0.18 0.24],'BorderType','line');
            app.ParamPanel.Layout.Row=[9 15]; app.ParamPanel.Layout.Column=[1 2];

            app.ParamGrid = uigridlayout(app.ParamPanel,[8 2]);
            app.ParamGrid.RowHeight   = repmat({22},1,8);
            app.ParamGrid.ColumnWidth = {'1x','1x'};
            app.ParamGrid.Padding     = [8 8 8 8];
            app.ParamGrid.RowSpacing  = 5;
            app.ParamGrid.BackgroundColor = [0.18 0.18 0.24];

            app.buildITParams();

            % -- Action buttons --
            app.ApplyBtn = uibutton(g,'Text','Terapkan', ...
                'ButtonPushedFcn',@(~,~)app.onApply(), ...
                'BackgroundColor',[0.10 0.58 0.32],'FontColor',[1 1 1], ...
                'FontWeight','bold','FontSize',13);
            app.ApplyBtn.Layout.Row=16; app.ApplyBtn.Layout.Column=1;

            app.SaveBtn = uibutton(g,'Text','Simpan Hasil', ...
                'ButtonPushedFcn',@(~,~)app.onSave(), ...
                'BackgroundColor',[0.52 0.28 0.08],'FontColor',[1 1 1], ...
                'FontWeight','bold','FontSize',12);
            app.SaveBtn.Layout.Row=16; app.SaveBtn.Layout.Column=2;
        end

        % ---- Middle panel -----------------------------------------------
        function buildMiddlePanel(app)
            p = uipanel(app.MainGrid,'Title','Fitur Citra', ...
                'FontSize',13,'FontWeight','bold', ...
                'ForegroundColor',[0.9 0.9 0.9], ...
                'BackgroundColor',[0.16 0.16 0.20],'BorderType','line');
            p.Layout.Column = 2;

            g = uigridlayout(p,[3 1]);
            g.RowHeight = {24,'1x','1x'};
            g.Padding   = [8 8 8 8];
            g.BackgroundColor = [0.16 0.16 0.20];

            app.StatusLabel = uilabel(g,'Text','Belum ada citra dimuat.', ...
                'FontSize',11,'FontColor',[0.70 0.70 0.80],'HorizontalAlignment','center');
            app.StatusLabel.Layout.Row = 1;

            ip = uipanel(g,'Title','Input','FontSize',11,'FontWeight','bold', ...
                'ForegroundColor',[0.80 0.90 1.0], ...
                'BackgroundColor',[0.14 0.14 0.18],'BorderType','line');
            ip.Layout.Row = 2;
            app.FeatInputLabel = uilabel(ip,'Text','-', ...
                'FontSize',10,'FontColor',[0.85 0.85 0.90], ...
                'VerticalAlignment','top','WordWrap','on', ...
                'Position',[6 6 200 280]);

            ep = uipanel(g,'Title','Enhanced','FontSize',11,'FontWeight','bold', ...
                'ForegroundColor',[0.70 1.0 0.80], ...
                'BackgroundColor',[0.14 0.14 0.18],'BorderType','line');
            ep.Layout.Row = 3;
            app.FeatEnhLabel = uilabel(ep,'Text','-', ...
                'FontSize',10,'FontColor',[0.85 0.85 0.90], ...
                'VerticalAlignment','top','WordWrap','on', ...
                'Position',[6 6 200 280]);
        end

        % ---- Right panel ------------------------------------------------
        function buildRightPanel(app)
            p = uipanel(app.MainGrid,'Title','Tampilan Citra & Histogram', ...
                'FontSize',13,'FontWeight','bold', ...
                'ForegroundColor',[0.9 0.9 0.9], ...
                'BackgroundColor',[0.16 0.16 0.20],'BorderType','line');
            p.Layout.Column = 3;

            g = uigridlayout(p,[2 2]);
            g.RowHeight    = {'1x','1x'};
            g.ColumnWidth  = {'1x','1x'};
            g.Padding      = [10 10 10 10];
            g.ColumnSpacing = 10;
            g.RowSpacing    = 10;
            g.BackgroundColor = [0.16 0.16 0.20];

            app.AxInputImg  = makeAxes(g, 1, 1, 'Citra Masukan');
            app.AxInputHist = makeAxes(g, 1, 2, 'Histogram Masukan');
            app.AxEnhImg    = makeAxes(g, 2, 1, 'Citra Hasil Enhancement');
            app.AxEnhHist   = makeAxes(g, 2, 2, 'Histogram Hasil Enhancement');
        end

        %% Parameter sub-panels

        function buildITParams(app)
            app.clearParamGrid();
            g = app.ParamGrid;

            lb1=uilabel(g,'Text','Tipe:','FontColor',[0.80 0.80 0.85],'FontSize',10);
            lb1.Layout.Row=1; lb1.Layout.Column=1;
            app.ITTypeDropdown = uidropdown(g, ...
                'Items',{'Negative','Gamma (Power-law)','Log Transform','Linear Stretch'}, ...
                'ValueChangedFcn',@(~,~)app.onITTypeChanged(), ...
                'BackgroundColor',[0.22 0.22 0.30],'FontColor',[0.95 0.95 0.95]);
            app.ITTypeDropdown.Layout.Row=1; app.ITTypeDropdown.Layout.Column=2;

            lb2=uilabel(g,'Text','Gamma:','FontColor',[0.80 0.80 0.85],'FontSize',10);
            lb2.Layout.Row=2; lb2.Layout.Column=1;
            app.GammaField=uieditfield(g,'numeric','Value',1.0,'Limits',[0.01 10], ...
                'BackgroundColor',[0.22 0.22 0.30],'FontColor',[0.95 0.95 0.95]);
            app.GammaField.Layout.Row=2; app.GammaField.Layout.Column=2;

            lb3=uilabel(g,'Text','Konstanta c:','FontColor',[0.80 0.80 0.85],'FontSize',10);
            lb3.Layout.Row=3; lb3.Layout.Column=1;
            app.CField=uieditfield(g,'numeric','Value',1.0,'Limits',[0.001 1000], ...
                'BackgroundColor',[0.22 0.22 0.30],'FontColor',[0.95 0.95 0.95]);
            app.CField.Layout.Row=3; app.CField.Layout.Column=2;

            lb4=uilabel(g,'Text','In Low:','FontColor',[0.80 0.80 0.85],'FontSize',10);
            lb4.Layout.Row=4; lb4.Layout.Column=1;
            app.LowInField=uieditfield(g,'numeric','Value',0,'Limits',[0 255], ...
                'BackgroundColor',[0.22 0.22 0.30],'FontColor',[0.95 0.95 0.95]);
            app.LowInField.Layout.Row=4; app.LowInField.Layout.Column=2;

            lb5=uilabel(g,'Text','In High:','FontColor',[0.80 0.80 0.85],'FontSize',10);
            lb5.Layout.Row=5; lb5.Layout.Column=1;
            app.HighInField=uieditfield(g,'numeric','Value',255,'Limits',[0 255], ...
                'BackgroundColor',[0.22 0.22 0.30],'FontColor',[0.95 0.95 0.95]);
            app.HighInField.Layout.Row=5; app.HighInField.Layout.Column=2;

            lb6=uilabel(g,'Text','Out Low:','FontColor',[0.80 0.80 0.85],'FontSize',10);
            lb6.Layout.Row=6; lb6.Layout.Column=1;
            app.LowOutField=uieditfield(g,'numeric','Value',0,'Limits',[0 255], ...
                'BackgroundColor',[0.22 0.22 0.30],'FontColor',[0.95 0.95 0.95]);
            app.LowOutField.Layout.Row=6; app.LowOutField.Layout.Column=2;

            lb7=uilabel(g,'Text','Out High:','FontColor',[0.80 0.80 0.85],'FontSize',10);
            lb7.Layout.Row=7; lb7.Layout.Column=1;
            app.HighOutField=uieditfield(g,'numeric','Value',255,'Limits',[0 255], ...
                'BackgroundColor',[0.22 0.22 0.30],'FontColor',[0.95 0.95 0.95]);
            app.HighOutField.Layout.Row=7; app.HighOutField.Layout.Column=2;

            app.onITTypeChanged();
        end

        function buildHEParams(app)
            app.clearParamGrid();
            lb=uilabel(app.ParamGrid,'Text','(Tidak ada parameter tambahan.)', ...
                'FontColor',[0.80 0.80 0.85],'FontSize',10);
            lb.Layout.Row=1; lb.Layout.Column=[1 2];
        end

        function buildHSParams(app)
            app.clearParamGrid();
            g = app.ParamGrid;

            lb1=uilabel(g,'Text','Target PDF:','FontColor',[0.80 0.80 0.85],'FontSize',10);
            lb1.Layout.Row=1; lb1.Layout.Column=1;
            app.HistSpecTypeDropdown = uidropdown(g, ...
                'Items',{'Gaussian','Uniform','Dari Citra Referensi'}, ...
                'ValueChangedFcn',@(~,~)app.onHSTypeChanged(), ...
                'BackgroundColor',[0.22 0.22 0.30],'FontColor',[0.95 0.95 0.95]);
            app.HistSpecTypeDropdown.Layout.Row=1; app.HistSpecTypeDropdown.Layout.Column=2;

            lb2=uilabel(g,'Text','Mean (Gauss):','FontColor',[0.80 0.80 0.85],'FontSize',10);
            lb2.Layout.Row=2; lb2.Layout.Column=1;
            app.HSMeanField=uieditfield(g,'numeric','Value',128,'Limits',[0 255], ...
                'BackgroundColor',[0.22 0.22 0.30],'FontColor',[0.95 0.95 0.95]);
            app.HSMeanField.Layout.Row=2; app.HSMeanField.Layout.Column=2;

            lb3=uilabel(g,'Text','Std (Gauss):','FontColor',[0.80 0.80 0.85],'FontSize',10);
            lb3.Layout.Row=3; lb3.Layout.Column=1;
            app.HSStdField=uieditfield(g,'numeric','Value',40,'Limits',[1 128], ...
                'BackgroundColor',[0.22 0.22 0.30],'FontColor',[0.95 0.95 0.95]);
            app.HSStdField.Layout.Row=3; app.HSStdField.Layout.Column=2;

            lb4=uilabel(g,'Text','Low (Uniform):','FontColor',[0.80 0.80 0.85],'FontSize',10);
            lb4.Layout.Row=4; lb4.Layout.Column=1;
            app.HSLowField=uieditfield(g,'numeric','Value',50,'Limits',[0 254], ...
                'BackgroundColor',[0.22 0.22 0.30],'FontColor',[0.95 0.95 0.95]);
            app.HSLowField.Layout.Row=4; app.HSLowField.Layout.Column=2;

            lb5=uilabel(g,'Text','High (Uniform):','FontColor',[0.80 0.80 0.85],'FontSize',10);
            lb5.Layout.Row=5; lb5.Layout.Column=1;
            app.HSHighField=uieditfield(g,'numeric','Value',200,'Limits',[1 255], ...
                'BackgroundColor',[0.22 0.22 0.30],'FontColor',[0.95 0.95 0.95]);
            app.HSHighField.Layout.Row=5; app.HSHighField.Layout.Column=2;

            lb6=uilabel(g,'Text','[Untuk referensi: klik Muat Referensi]', ...
                'FontColor',[0.60 0.60 0.68],'FontSize',9,'WordWrap','on');
            lb6.Layout.Row=6; lb6.Layout.Column=[1 2];

            app.onHSTypeChanged();
        end

        function buildFilterParams(app)
            app.clearParamGrid();
            g = app.ParamGrid;

            lb1=uilabel(g,'Text','Tipe Filter:','FontColor',[0.80 0.80 0.85],'FontSize',10);
            lb1.Layout.Row=1; lb1.Layout.Column=1;
            app.FilterTypeDropdown = uidropdown(g, ...
                'Items',{'Averaging','Gaussian','Sharpening (Laplacian)','Median'}, ...
                'BackgroundColor',[0.22 0.22 0.30],'FontColor',[0.95 0.95 0.95]);
            app.FilterTypeDropdown.Layout.Row=1; app.FilterTypeDropdown.Layout.Column=2;

            lb2=uilabel(g,'Text','Ukuran Kernel:','FontColor',[0.80 0.80 0.85],'FontSize',10);
            lb2.Layout.Row=2; lb2.Layout.Column=1;
            app.KernelSizeField=uieditfield(g,'numeric','Value',3,'Limits',[3 21], ...
                'BackgroundColor',[0.22 0.22 0.30],'FontColor',[0.95 0.95 0.95]);
            app.KernelSizeField.Layout.Row=2; app.KernelSizeField.Layout.Column=2;

            lb3=uilabel(g,'Text','Sigma (Gauss):','FontColor',[0.80 0.80 0.85],'FontSize',10);
            lb3.Layout.Row=3; lb3.Layout.Column=1;
            app.SigmaField=uieditfield(g,'numeric','Value',1.0,'Limits',[0.1 20], ...
                'BackgroundColor',[0.22 0.22 0.30],'FontColor',[0.95 0.95 0.95]);
            app.SigmaField.Layout.Row=3; app.SigmaField.Layout.Column=2;

            lb4=uilabel(g,'Text','Alpha (Sharp):','FontColor',[0.80 0.80 0.85],'FontSize',10);
            lb4.Layout.Row=4; lb4.Layout.Column=1;
            app.SharpenAlphaField=uieditfield(g,'numeric','Value',1.0,'Limits',[0.1 10], ...
                'BackgroundColor',[0.22 0.22 0.30],'FontColor',[0.95 0.95 0.95]);
            app.SharpenAlphaField.Layout.Row=4; app.SharpenAlphaField.Layout.Column=2;
        end

        function clearParamGrid(app)
            delete(app.ParamGrid.Children);
        end
    end

    %% ---- Callbacks -----------------------------------------------------
    methods (Access = private)

        function updateFolderList(app)
            if ~isfolder(app.DataRoot)
                app.FolderDropdown.Items = {'(folder data tidak ditemukan)'};
                return;
            end
            % Collect subfolders inside data/ (e.g. 1. Histogram Citra, 2. Kasus 1 ...)
            d = dir(app.DataRoot);
            d = d([d.isdir] & ~startsWith({d.name},'.'));
            subNames = {d.name};
            % Subfolders first (folder 1 is default), Browse at the end
            items = [subNames, {'[Browse...] Pilih folder lain'}];
            app.FolderDropdown.Items = items;
            app.onFolderChanged();
        end

        function onFolderChanged(app)
            sel = app.FolderDropdown.Value;
            if isempty(sel), return; end

            if strcmp(sel, '[Browse...] Pilih folder lain')
                % Open a folder-picker dialog
                chosen = uigetdir(app.DataRoot, 'Pilih Folder Citra');
                if isequal(chosen, 0)
                    % User cancelled – revert to first subfolder
                    app.FolderDropdown.Value = app.FolderDropdown.Items{1};
                    app.onFolderChanged();
                    return;
                end
                app.CurrentFolderPath = chosen;
            else
                % Normal subfolder inside data/
                app.CurrentFolderPath = fullfile(app.DataRoot, sel);
            end

            % Populate file list from resolved path
            exts  = {'*.png','*.jpg','*.jpeg','*.bmp','*.tif','*.tiff'};
            files = [];
            for i = 1:numel(exts)
                files = [files; dir(fullfile(app.CurrentFolderPath, exts{i}))]; %#ok<AGROW>
            end
            if isempty(files)
                app.FileDropdown.Items = {'(tidak ada citra)'};
            else
                app.FileDropdown.Items = {files.name};
            end
        end

        function onLoadImage(app)
            file = app.FileDropdown.Value;
            if isempty(app.CurrentFolderPath) || isempty(file) || contains(file,'tidak ada')
                app.setStatus('Pilih folder dan file terlebih dahulu.','warn');
                return;
            end
            fpath = fullfile(app.CurrentFolderPath, file);
            try
                img = imread(fpath);
                if ~isa(img,'uint8'), img = im2uint8(img); end
                app.InputImage    = img;
                app.EnhancedImage = [];
                app.displayInputImage();
                app.setStatus(['Citra dimuat: ' file],'ok');
            catch ME
                app.setStatus(['Gagal memuat: ' ME.message],'err');
            end
        end

        function onLoadReference(app)
            [f,p] = uigetfile( ...
                {'*.png;*.jpg;*.jpeg;*.bmp;*.tif;*.tiff','Citra'}, ...
                'Pilih Citra Referensi');
            if isequal(f,0), return; end
            try
                ref = imread(fullfile(p,f));
                if ~isa(ref,'uint8'), ref = im2uint8(ref); end
                app.ReferenceImage = ref;
                app.setStatus(['Referensi dimuat: ' f],'ok');
            catch ME
                app.setStatus(['Gagal memuat referensi: ' ME.message],'err');
            end
        end

        function onMethodChanged(app)
            switch app.MethodDropdown.Value
                case 'Intensity Transformation', app.buildITParams();
                case 'Histogram Equalization',   app.buildHEParams();
                case 'Histogram Specification',  app.buildHSParams();
                case 'Image Filtering',          app.buildFilterParams();
            end
        end

        function onITTypeChanged(app)
            if isempty(app.ITTypeDropdown), return; end
            t  = app.ITTypeDropdown.Value;
            isG = strcmp(t,'Gamma (Power-law)');
            isL = strcmp(t,'Log Transform');
            isS = strcmp(t,'Linear Stretch');
            app.GammaField.Enable   = iff(isG,'on','off');
            app.CField.Enable       = iff(isG||isL,'on','off');
            app.LowInField.Enable   = iff(isS,'on','off');
            app.HighInField.Enable  = iff(isS,'on','off');
            app.LowOutField.Enable  = iff(isS,'on','off');
            app.HighOutField.Enable = iff(isS,'on','off');
        end

        function onHSTypeChanged(app)
            if isempty(app.HistSpecTypeDropdown), return; end
            t  = app.HistSpecTypeDropdown.Value;
            isG = strcmp(t,'Gaussian');
            isU = strcmp(t,'Uniform');
            app.HSMeanField.Enable = iff(isG,'on','off');
            app.HSStdField.Enable  = iff(isG,'on','off');
            app.HSLowField.Enable  = iff(isU,'on','off');
            app.HSHighField.Enable = iff(isU,'on','off');
        end

        function onApply(app)
            if isempty(app.InputImage)
                app.setStatus('Muat citra terlebih dahulu.','warn');
                return;
            end
            try
                method = app.MethodDropdown.Value;
                switch method
                    case 'Intensity Transformation', app.EnhancedImage = app.applyIT();
                    case 'Histogram Equalization',   app.EnhancedImage = app.applyHE();
                    case 'Histogram Specification',  app.EnhancedImage = app.applyHS();
                    case 'Image Filtering',          app.EnhancedImage = app.applyFilter();
                end
                app.displayEnhancedImage();
                app.setStatus(['Enhancement selesai: ' method],'ok');
            catch ME
                app.setStatus(['Error: ' ME.message],'err');
            end
        end

        function onSave(app)
            if isempty(app.EnhancedImage)
                app.setStatus('Tidak ada citra hasil untuk disimpan.','warn');
                return;
            end
            [f,p] = uiputfile({'*.png','PNG';'*.jpg','JPEG';'*.bmp','BMP'}, ...
                'Simpan Citra Hasil','enhanced_result.png');
            if isequal(f,0), return; end
            try
                imwrite(app.EnhancedImage, fullfile(p,f));
                app.setStatus(['Tersimpan: ' f],'ok');
            catch ME
                app.setStatus(['Gagal simpan: ' ME.message],'err');
            end
        end

        function onClose(app)
            delete(app.Fig);
        end
    end

    %% ---- Enhancement Implementations ----------------------------------
    methods (Access = private)

        % -----------------------------------------------------------------
        % 1. INTENSITY TRANSFORMATION  ->  myIntensityTransform.m
        % -----------------------------------------------------------------
        function out = applyIT(app)
            out = myIntensityTransform( ...
                app.InputImage, ...
                app.ITTypeDropdown.Value, ...
                app.CField.Value, ...
                app.GammaField.Value, ...
                app.LowInField.Value, ...
                app.HighInField.Value, ...
                app.LowOutField.Value, ...
                app.HighOutField.Value);
        end

        % -----------------------------------------------------------------
        % 2. HISTOGRAM EQUALIZATION  ->  myHistEq.m
        % -----------------------------------------------------------------
        function out = applyHE(app)
            out = myHistEq(app.InputImage);
        end

        % -----------------------------------------------------------------
        % 3. HISTOGRAM SPECIFICATION  ->  myHistSpec.m
        % -----------------------------------------------------------------
        function out = applyHS(app)
            out = myHistSpec( ...
                app.InputImage, ...
                app.HistSpecTypeDropdown.Value, ...
                app.HSMeanField.Value, ...
                app.HSStdField.Value, ...
                app.HSLowField.Value, ...
                app.HSHighField.Value, ...
                app.ReferenceImage);
        end

        % -----------------------------------------------------------------
        % 4. IMAGE FILTERING  ->  myFilter.m
        % -----------------------------------------------------------------
        function out = applyFilter(app)
            out = myFilter( ...
                app.InputImage, ...
                app.FilterTypeDropdown.Value, ...
                app.KernelSizeField.Value, ...
                app.SigmaField.Value, ...
                app.SharpenAlphaField.Value);
        end
    end

    %% ---- Display Helpers ----------------------------------------------
    methods (Access = private)

        function displayInputImage(app)
            I = app.InputImage;
            cla(app.AxInputImg);
            imshow(I,'Parent',app.AxInputImg);
            title(app.AxInputImg,'Citra Masukan','Color','w','FontSize',10);
            app.plotHistogram(app.AxInputHist, I, 'Histogram Masukan');
            app.updateFeatLabel(app.FeatInputLabel, I);
        end

        function displayEnhancedImage(app)
            I = app.EnhancedImage;
            cla(app.AxEnhImg);
            imshow(I,'Parent',app.AxEnhImg);
            title(app.AxEnhImg,'Citra Hasil Enhancement','Color','w','FontSize',10);
            app.plotHistogram(app.AxEnhHist, I, 'Histogram Hasil');
            app.updateFeatLabel(app.FeatEnhLabel, I);
        end

        function plotHistogram(~, ax, I, ttl)
            % Gunakan myHist custom (256 bin, tanpa imhist)
            h     = myHist(I);
            numCh = size(I,3);
            cla(ax); hold(ax,'on');
            if numCh == 1
                bar(ax, 0:255, h(:,1), 1, ...
                    'FaceColor',[0.72 0.72 0.82],'EdgeColor','none','FaceAlpha',0.9);
            else
                clrs   = {[1 0.35 0.35],[0.35 1 0.35],[0.35 0.55 1]};
                labels = {'R','G','B'};
                for c = 1:numCh
                    plot(ax, 0:255, h(:,c), 'Color',clrs{c}, ...
                        'LineWidth',1.5,'DisplayName',labels{c});
                end
                legend(ax,'show','TextColor','w', ...
                    'Color',[0.12 0.12 0.16],'FontSize',8);
            end
            hold(ax,'off');
            ax.XLim      = [0 255];
            ax.Color     = [0.09 0.09 0.12];
            ax.XColor    = [0.70 0.70 0.80];
            ax.YColor    = [0.70 0.70 0.80];
            ax.GridColor = [0.28 0.28 0.38];
            ax.XGrid='on'; ax.YGrid='on';
            title(ax,ttl,'Color','w','FontSize',10);
            xlabel(ax,'Intensitas','Color',[0.7 0.7 0.8],'FontSize',8);
            ylabel(ax,'Jumlah Piksel','Color',[0.7 0.7 0.8],'FontSize',8);
        end

        function updateFeatLabel(~, lbl, I)
            % Gunakan imgFeatures custom
            f     = imgFeatures(I);
            numCh = size(I,3);
            chN   = {'R','G','B'};
            if numCh==1, chN={'Gray'}; end
            txt = '';
            for c = 1:numCh
                txt=[txt sprintf('[%s]\n',chN{c})];               %#ok<AGROW>
                txt=[txt sprintf('  Min    : %3.0f\n',f.min(c))]; %#ok<AGROW>
                txt=[txt sprintf('  Max    : %3.0f\n',f.max(c))]; %#ok<AGROW>
                txt=[txt sprintf('  Mean   : %6.2f\n',f.mean(c))]; %#ok<AGROW>
                txt=[txt sprintf('  Std    : %6.2f\n',f.std(c))];  %#ok<AGROW>
                txt=[txt sprintf('  Entropy: %.4f\n',f.entropy(c))]; %#ok<AGROW>
            end
            lbl.Text = txt;
        end

        function setStatus(app, msg, level)
            switch level
                case 'ok',   c=[0.3 0.9 0.5];
                case 'warn', c=[1.0 0.8 0.2];
                case 'err',  c=[1.0 0.4 0.3];
                otherwise,   c=[0.7 0.7 0.8];
            end
            app.StatusLabel.FontColor = c;
            app.StatusLabel.Text = msg;
        end
    end
end


%% ====== Module-level GUI helpers (bukan logika pemrosesan) ==============

function ax = makeAxes(parent, row, col, ttl)
    ax = uiaxes(parent);
    ax.Layout.Row    = row;
    ax.Layout.Column = col;
    ax.Color           = [0.09 0.09 0.12];
    ax.XColor          = [0.70 0.70 0.80];
    ax.YColor          = [0.70 0.70 0.80];
    ax.Title.Color     = [1 1 1];
    ax.BackgroundColor = [0.09 0.09 0.12];
    title(ax, ttl, 'Color','w','FontSize',10);
end

function s = iff(cond, a, b)
    % Ternary helper
    if cond, s=a; else, s=b; end
end
