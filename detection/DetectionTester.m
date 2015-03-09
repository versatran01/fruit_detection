classdef DetectionTester < handle
    %DETECTIONTESTER Class for testing detection against labeled dataset.
    % todo: sooooo much code duplication in these gui classes. fix this...
    
    properties(Access=private)
        dataset
        detector
        viz
        % current state
        curImage = 0;
        mode = 1;
        finished = false;
        validity = [];
        axesSize
        CC
        circles
        % plot stuff
        hFig
        hPlots
        hMask
        hImage
        hSelections
        hDetectionBoxes
        hDetectionCircles
        % buttons, etc..
        hToolMenu
        hButtons
    end
    
    properties
        rotate = false;
        metrics = [];
        components = {};
        labels = {};
        scale = 1;
    end
    
    methods(Access=private)
        function attachCallbacks(self)
           fig = self.hFig;
           %set(fig, 'WindowButtonMotionFcn',...
           %    @(object,eventdata)self.mouseMove(object,eventdata));
           %set(fig, 'WindowButtonDownFcn',...
           %    @(object,eventdata)self.mouseDown(object,eventdata));
           set(fig, 'WindowButtonUpFcn',...
               @(object,eventdata)self.mouseUp(object,eventdata));
           set(fig, 'KeyReleaseFcn',...
               @(object,eventdata)self.keyUp(object,eventdata));
           set(fig, 'CloseRequestFcn',...
               @(object,eventdata)self.closeRequest(object,eventdata));
        end
        
        function configureInterface(self)
            cb = @(obj,callbackdata)handleButton(self,obj,callbackdata); 
            self.hToolMenu = uicontrol('Style','popupmenu',...
                'String',{'Select','Zoom'},...
                'Position',[20,16,120,25],'Callback',cb);
            self.hButtons{1} = uicontrol('Style', 'pushbutton',...
                                         'String', 'Zoom Reset',...
                                         'Position', [300 20 80 25],...
                                         'Callback', cb);
        end
        
        function handleButton(self, object, callbackdata)
            set(0,'CurrentFigure',self.hFig);
            if self.hButtons{1} == object
                % zoom reset button
                sz = self.axesSize;
                axis([0 sz(2) 0 sz(1)]);
            elseif object == self.hToolMenu
                % tool menu
                self.switchMode(get(object, 'Value'));
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
            end
            set(self.hToolMenu, 'Value', mode);
        end
        
        function selectBox(self, pos, accept)
            % find bounding box we are clicking
            bbox = self.CC.BoundingBox();
            inside = bsxfun(@le, bbox(:,1:2), pos) & ...
                     bsxfun(@le, pos, bbox(:,1:2)+bbox(:,3:4));
            inside = inside(:,1) & inside(:,2);
            if any(inside)
                % only take the first for now
                % todo: determine the 'best' selection
                idx = find(inside,1,'first');
                self.validity(idx) = accept;
                self.plotDetections();  % re-plot...
            end
        end
        
        function mouseUp(self, object, eventdata)
            selType = get(self.hFig,'SelectionType');
            if self.mode ~= 1
                return; % ignore all clicks in zoom mode...
            end
            pos = getMousePosition();
            if strcmp(selType, 'normal')
                % normal click
                self.selectBox(pos,true);
            elseif strcmp(selType, 'alt')
                % right click
                self.selectBox(pos,false);
            end
        end
        
        function keyUp(self, object, eventdata)
            char = int32(eventdata.Character);
            if char == 13
                % enter: exit this image
                self.finished = true;
            end
        end
        
        function closeRequest(self, object, eventdata)
            delete(self.hFig);
        end
        
        function plotImage(self, image, mask)
            if isempty(self.hFig)
                % create new UI
                self.hFig = figure;
                clf(self.hFig,'reset');
                set(self.hFig, 'MenuBar', 'None');
                % attach callbacks to mouse, etc
                self.configureInterface();
                self.attachCallbacks();
                % create plots
                self.hPlots(1) = subplot(1,2,1);
                self.hImage = imshow(image);
                hold on;
                self.hPlots(2) = subplot(1,2,2);
                self.hMask = imshow(mask);
                self.axesSize = size(image);
                hold on;
                linkaxes(self.hPlots);
            else
                % update old plots
                set(0,'CurrentFigure', self.hFig);
                set(self.hImage, 'CData', image);
                set(self.hMask, 'CData', mask);
            end
            set(self.hFig, 'Name', ...
                sprintf('Current image: %i', self.curImage));
        end
        
        function plotSelections(self, selections)
            if ~isempty(self.hSelections)
                delete(self.hSelections);
                self.hSelections = [];
            end
            for i=1:numel(selections)
                sel = selections{i};
                if ~any(sel(4) == [1 3])
                    % only plot fruit selections
                    continue;
                end
                points = createCirclePoints(sel(1:2), sel(3));
                self.hSelections(i) = plot(points(:,1),points(:,2));
                set(self.hSelections(i),'LineWidth',2);
                set(self.hSelections(i),'Color',[1 0 0]);
            end
        end
        
        function plotDetections(self)
            CC = self.CC;
            valid = self.validity;
            detections = CC.BoundingBox();
            if ~isempty(self.hDetectionBoxes)
                delete(self.hDetectionBoxes);
                self.hDetectionBoxes = [];
            end
            if ~isempty(self.hDetectionCircles)
                delete(cell2mat(self.hDetectionCircles));
                self.hDetectionCircles = {};
            end
            axes(self.hPlots(2));
            for i=1:CC.size()
                % draw the bounding box
                pts = bboxToLinePoints(detections(i,:));
                pts_x = squeeze(pts(:,1,:));
                pts_y = squeeze(pts(:,2,:));
                h = plot(pts_x,pts_y);
                set(h,'LineWidth',2);
                if valid(i)
                    color = [0 1 0];
                else
                    color = [0 0 1];
                end
                set(h,'Color',color);
                self.hDetectionBoxes(i) = h;
                
                % now draw circles for individual fruit
                circ = self.circles{i};
                if ~isempty(circ)
                    plots = [];
                    for j=1:size(circ,1)
                        pts = createCirclePoints(circ(j,1:2),...
                            circ(j,3), 20);
                        h = plot(pts(:,1), pts(:,2));
                        set(h,'LineWidth',2);
                        set(h,'Color',[1 0.1 0.75]);
                        plots(end+1,:) = h;
                    end
                    self.hDetectionCircles{i} = plots;
                end
            end
            % must be in a column format...
            self.hDetectionCircles = reshape(self.hDetectionCircles,...
                numel(self.hDetectionCircles), 1);
        end
        
        function [valid] = updateStats(self, selections, CC, circles)
            if isempty(selections)
                % simple hack so we can run unlabeled dataset
                valid = false(CC.size(), 1);
                return;
            end
            detections = CC.BoundingBox();
            
            % pull out the selections that are fruit
            selections = cell2mat(selections);
            idx_fruit = (selections(:,4) == 1) | (selections(:,4) == 3);
            selections = selections(idx_fruit,:);
            % get centers and radii
            centers_sel = selections(:,1:2);
            %radii = selections(:,3);
            
            % find the detections which include the center of a selection
            inside = pointsInBoxes(detections, centers_sel);
            inside_total = sum(inside, 2);
            
            tp = 0;
            fp = 0;
            for i=1:numel(inside_total)
                expected = inside_total(i);
                predicted = size(circles{i}, 1);
                predicted = max(predicted, 1);  % empty should be counted as 1
                
                tp = tp + min(expected,predicted);
                fp = fp + max(predicted - expected, 0);
            end
            
            total_fruit = size(centers_sel,1);  % total labeled fruit
            fn = total_fruit - tp;
            
            self.metrics(self.curImage,:) = [tp fp fn];
            
            fprintf('Counted %i of %i labelled fruit\n',...
                tp, total_fruit);
            fprintf('%i of %i detections are false positives\n',...
                fp, fp+tp);
            valid = inside_total;
        end
    end
    
    methods
        function [self] = DetectionTester(dataset, detector, viz)
            self.dataset = dataset;
            self.detector = detector;
            if nargin < 3
                viz = true;
            end
            self.viz = viz;
        end
        
        function [next] = hasNext(self)
            next = self.curImage < self.dataset.size();
        end
        
        function processNext(self)
            self.curImage = self.curImage + 1;
            if self.curImage > 1
                % save results from last image...
                self.components{end+1} = self.CC;
                self.labels{end+1} = self.validity;
            end
            idx = self.curImage;
            image = self.dataset.images{idx};
            if self.rotate
                image = rot90(image,1);
            end
            image = imresize(image, self.scale);
            % user selections for this image
            selections = self.dataset.selections{idx};
            % run detector on next image
            [self.CC,~,self.circles] = self.detector(image,self.scale);
            self.validity = self.updateStats(selections, self.CC,...
                self.circles);
            self.finished = false;
            if self.viz
                self.plotImage(image, self.CC.image);
                self.plotSelections(selections);
                self.plotDetections();
            else
                self.finished = true;
            end
            while ~self.isFinished()
                drawnow;    % update UI
            end
        end
        
        function value = isFinished(self)
            value = self.finished;
        end
        
        function setCurrentImage(self, curImage)
            % todo: change this method so it can be called anytime
            if curImage > self.dataset.size() || curImage < 1
                error('curImage index invalid');
            end
            self.curImage = curImage;
        end
    end
end
