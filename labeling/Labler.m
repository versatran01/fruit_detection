classdef Labler < handle
    
    properties(Access=private)
        % inputs
        image
        labelStrings
        % mode
        selecting = false;
        mode = 1;
        finished = false;
        quit = false;
        currentLabel = 1;
        % selections
        center
        radius
        selections = {};
        masks = {};
        maskLayer = [];
        % graphical UI objects
        maskColor = [0 0.75 1];
        maskAlpha = 0.4;
        hFig
        hSelection
        hLabels
        hImage
        hMask
        hButtons
        hToolMenu
        hLabelMenu
        hContextMenu
    end
    
    methods(Access=private)
        function attachCallbacks(self)
           fig = self.hFig;
           set(fig, 'WindowButtonMotionFcn',...
               @(object,eventdata)self.mouseMove(object,eventdata));
           set(fig, 'WindowButtonDownFcn',...
               @(object,eventdata)self.mouseDown(object,eventdata));
           set(fig, 'WindowButtonUpFcn',...
               @(object,eventdata)self.mouseUp(object,eventdata));
           set(fig, 'KeyReleaseFcn',...
               @(object,eventdata)self.keyUp(object,eventdata));
           set(fig, 'CloseRequestFcn',...
               @(object,eventdata)self.closeRequest(object,eventdata));
        end
        
        function mouseMove(self, object, eventdata)
            C = getMousePosition();
            if self.selecting
                self.radius = norm(C - self.center);
                if self.radius > 3
                    self.plotCircleSelection(self.radius, C);
                end
            end
        end
        
        function mouseDown(self, object, eventdata)
            selType = get(self.hFig,'SelectionType');
            if ~strcmp(selType,'normal')
                return; % ignore right clicks
            end
            pos = getMousePosition();
            if self.mode == 1
                % selecting circle
                if ~self.selecting
                    self.center = pos;
                    self.radius = 0;
                    self.selecting = true;
                end
            elseif self.mode == 3
                % find selected fruit
                selindex = self.getSelectionAtPosition(pos);
                if ~isempty(selindex)
                    % run the masker
                    self.launchMasker(selindex);
                end
            elseif self.mode == 4
                % delete current selection
                selindex = self.getSelectionAtPosition(pos);
                if ~isempty(selindex)
                    self.deleteSelection(selindex);
                end
            end
        end
        
        function mouseUp(self, object, eventdata)
            self.selecting = false;
        end
        
        function keyUp(self, object, eventdata)
            char = int32(eventdata.Character);
            if char == 13
                % newline/enter
                if self.mode == 1 && ~self.selecting
                    if ~isempty(self.radius)
                        self.captureSelection();
                    end
                end
            end
        end
        
        function closeRequest(self, object, eventdata)
            delete(self.hFig);
            self.finished = true;
        end
        
        function plotCircleSelection(self, radius, mousePoint)
            points = createCirclePoints(self.center, radius);
            line = [self.center; mousePoint];
            if isempty(self.hSelection)
                set(0,'CurrentFigure',self.hFig);
                self.hSelection{1} = plot(points(:,1),points(:,2));
                self.hSelection{2} = plot(line(:,1), line(:,2));
                for i=1:2
                    set(self.hSelection{i},'LineWidth',3);
                    set(self.hSelection{i},'Color',[1 0 1]);
                end
            end
            set(self.hSelection{1},'xdata',points(:,1),'ydata',points(:,2));
            set(self.hSelection{2},'xdata',line(:,1),'ydata',line(:,2));
        end
        
        function plotSelections(self)
            for i=1:length(self.selections)
                sel = self.selections{i};   % [x y radius]
                hasmask = ~isempty(self.masks{i});
                points = createCirclePoints(sel(1:2), sel(3));
                if length(self.hLabels) >= i
                    set(self.hLabels(i),'xdata',points(:,1),...
                        'ydata',points(:,2));
                else
                    self.hLabels(end+1) = plot(points(:,1),points(:,2));
                end 
                set(self.hLabels(i),'LineWidth',2);
                if ~hasmask
                    % todo: make this an option
                    color = [1 0 0];
                else
                    color = [0 0.5 1];
                end
                set(self.hLabels(i),'Color',color);
            end
        end
        
        function plotImage(self)
            set(0,'CurrentFigure',self.hFig);
            if isempty(self.hImage)
                hold off;
                self.hImage = imshow(self.image);
                hold on;
                % add solid top layer in color of mask
                sz = size(self.image);
                full = ones(sz(1:2));
                color(:,:,1) = self.maskColor(1)*full;
                color(:,:,2) = self.maskColor(2)*full;
                color(:,:,3) = self.maskColor(3)*full;
                self.hMask = imshow(uint8(color*255));
            else
                % update existing
                set(self.hImage,'CData',self.image);
            end
            self.rebuildMaskLayer();
            % update alpha of mask layer
            set(self.hMask, 'AlphaData', self.maskLayer * self.maskAlpha);
        end
        
        function configureInterface(self)
            clf(self.hFig,'reset');
            set(self.hFig,'MenuBar', 'None');
            set(self.hFig,'Name','Labeltron 9000');
            cb = @(obj,callbackdata)handleButton(self,obj,callbackdata);            
            self.hToolMenu = uicontrol('Style','popupmenu',...
                'String',{'Select','Zoom','Mask','Delete'},...
                'Position',[20,16,120,25],'Callback',cb);
            self.hLabelMenu = uicontrol('Style','popupmenu',...
                'String',self.labelStrings,...
                'Position',[150,16,120,25],'Callback',cb);
            set(self.hLabelMenu,'Value',self.currentLabel);
            self.hButtons{1} = uicontrol('Style', 'pushbutton',...
                                         'String', 'Zoom Reset',...
                                         'Position', [300 20 80 25],...
                                         'Callback', cb);
            self.hButtons{2} = uicontrol('Style', 'pushbutton',...
                                         'String', 'Done',...
                                         'Position', [400 20 80 25],...
                                         'Callback', cb);
            self.hButtons{3} = uicontrol('Style', 'pushbutton',...
                                         'String', 'Quit',...
                                         'Position', [500 20 80 25],...
                                         'Callback', cb);
            %set(self.hFig, 'Units', 'normalized', 'Position', [0,0,1,1]);
        end
        
        function handleButton(self, object, callbackdata)
            set(0,'CurrentFigure',self.hFig);
            if self.hButtons{1} == object
                % zoom reset button
                sz = size(self.image);
                axis([0 sz(2) 0 sz(1)]);
            elseif self.hButtons{2} == object
                close(self.hFig); % close window
            elseif self.hButtons{3} == object
                % quit
                self.quit = true;
                close(self.hFig);
            elseif object == self.hToolMenu
                % tool menu
                self.switchMode(get(object, 'Value'));
            elseif object == self.hLabelMenu
                % label menu
                self.currentLabel = get(object, 'Value');
            end
        end
        
        function switchMode(self, mode)
            if self.mode ~= mode
                if mode == 2
                    zoom on;
                else
                    zoom off;
                end
                self.mode = mode;
                if self.mode ~= 1
                    % not in selection mode, get rid of selection plot
                    self.selecting = false;
                    if ~isempty(self.hSelection)
                        delete(self.hSelection{1});
                        delete(self.hSelection{2});
                        self.hSelection = {};
                    end
                end
            end
            set(self.hToolMenu, 'Value', mode);
        end
        
        function captureSelection(self)
            self.selections{end+1} = [self.center self.radius... 
                                      self.currentLabel];
            self.masks{end+1} = []; % new empty mask
            self.plotSelections();
        end
        
        function [index] = getSelectionAtPosition(self, pos)
            % make sure dimensions are ok
            self.selections = reshape(self.selections,...
                numel(self.selections), 1);
            sel = cell2mat(self.selections);
            dists = bsxfun(@minus, sel(:,1:2), pos);
            dists = sqrt(sum(dists.^2, 2));
            valid = dists < sel(:,3);   % inside radius
            if ~any(valid)
                index = []; % no selection
                return;
            end
            % find closest selection
            [~,smallest] = min(dists(valid,:));
            indices = find(valid);
            index = indices(smallest);
        end
        
        function launchMasker(self, index)
            selection = self.selections{index};
            mask = self.masks{index};
            % pull the selection out of the image
            [sample,~] = sampleSelectionsFromImage(self.image,...
                {selection}); % don't need the region for this...
            sample = sample{1};
            % now launch and run the masker
            M = Masker(sample, mask);
            while ~M.isFinished()
                drawnow;
            end
            % copy back to masks
            self.masks{index} = M.getMask();
            % bring our figure back to foreground
            figure(self.hFig);
            % update plots
            self.plotImage();
            self.plotSelections();
        end
        
        function rebuildMaskLayer(self)
            % todo: this is kind of inefficient, maybe improve it later
            sz = size(self.image);
            self.maskLayer = zeros(sz(1:2));
            [~,regions] = sampleSelectionsFromImage(self.image,...
                self.selections);
            for i=1:numel(self.selections)
                region = regions{i};
                mask = self.masks{i};
                if ~isempty(mask)
                    % copy to larger mask
                    o = region([2 1]); % convert to row/col format
                    d = region([4 3]);
                    self.maskLayer(o(1):(o(1)+d(1)), o(2):(o(2)+d(2))) =...
                        mask;
                end
            end
        end
        
        function deleteSelection(self, index)
            % delete selection, mask, and plot, then re-plot image
            self.selections(index) = [];
            self.masks(index) = [];
            delete(self.hLabels(index));
            self.hLabels(index) = [];
            self.plotImage();
        end
    end
    
    methods(Access=public)
        function self = Labler(image, labelStrings, selections, masks)
            self.image = image;
            self.labelStrings = labelStrings;
            self.hFig = figure;
            self.selections = reshape(selections, numel(selections), 1);
            if ~isempty(masks)
                self.masks = reshape(masks, numel(masks), 1);
            else
                % start with cell array of empty masks
                self.masks = cell(numel(selections), 1);
            end
            self.configureInterface();           
            self.plotImage();
            self.plotSelections();
            self.attachCallbacks();
        end
        
        function value = isFinished(self)
            value = self.finished;
        end
        
        function value = didQuit(self)
            value = self.quit;
        end
        
        function value = getSelections(self)
            value = self.selections;
        end
        
        function value = getMasks(self)
            value = self.masks;
        end
        
        function delete(self)
            if ishandle(self.hFig)
                close(self.hFig);
            end
        end
    end
end
