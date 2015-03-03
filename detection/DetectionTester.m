classdef DetectionTester < handle
    %DETECTIONTESTER Class for testing detection against labeled dataset.
    
    properties
        % inputs
        dataset
        detector
        viz = true;
        % current state
        curImage = 1;
        errors = [];
        % gui stuff
        hFig
        hPlots
        hMask
        hImage
        hSelections
        hDetections
    end
    
    methods(Access=private)
        function plotImage(self, image, mask)
            if isempty(self.hFig)
                % create new UI
                self.hFig = figure;
                set(self.hFig, 'Name', 'Detection Tester');
                self.hPlots(1) = subplot(1,2,1);
                self.hImage = imshow(image);
                hold on;
                self.hPlots(2) = subplot(1,2,2);
                self.hMask = imshow(mask);
                hold on;
            else
                % update old plots
                set(0,'CurrentFigure', self.hFig);
                set(self.hImage, 'CData', image);
                set(self.hMask, 'CData', mask);
            end
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
        
        function plotDetections(self, detections, valid)
            if ~isempty(self.hDetections)
                delete(self.hDetections);
                self.hDetections = [];
            end
            for i=1:size(detections,1)
                pts = bboxToLinePoints(detections(i,:));
                pts_x = squeeze(pts(:,1,:));
                pts_y = squeeze(pts(:,2,:));
                self.hDetections(i) = plot(pts_x,pts_y);
                set(self.hDetections(i),'LineWidth',2);
                if valid(i)
                    color = [0 1 0];
                else
                    color = [0 0 1];
                end
                set(self.hDetections(i),'Color',color);
            end
        end
        
        function [valid] = updateStats(self, selections, detections)
            % pull out the selections that are fruit
            selections = cell2mat(selections);
            idx_fruit = (selections(:,4) == 1) | (selections(:,4) == 3);
            selections = selections(idx_fruit,:);
            % get centers and radii
            centers_sel = selections(:,1:2);
            radii = selections(:,3);
            
            % find the detections which include the center of a selection
            inside = pointsInBoxes(detections, centers_sel);
            valid = sum(inside, 2);
            % get centers of boxes
            centers_box = bsxfun(@plus, detections(:,1:2),...
                detections(:,3:4) * 0.5);
            % find the boxes which are inside
            
            
            % determine some important numbers...
            total_positive = numel(valid);
            tp = nnz(valid);
            fp = total_positive - tp;
            total_fruit = nnz(idx_fruit);
            
            fprintf('Counted %i of %i labelled fruit\n',...
                nnz(valid), nnz(idx_fruit));
            
            fprintf('%i of %i detections are false positives\n',...
                numel(valid) - nnz(valid), numel(valid));
           
            
            
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
            self.curImage = self.curImage+1;
            idx = self.curImage;
            image = self.dataset.images{idx};
            % user selections for this image
            selections = self.dataset.selections{idx};
            % run detector on next image
            [mask, bbox] = self.detector(image);
            valid = self.updateStats(selections, bbox);
            if self.viz
                self.plotImage(image, mask);
                self.plotSelections(selections);
                self.plotDetections(bbox, valid);
            end
        end
        
        function setCurrentImage(self, curImage)
            if curImage > self.dataset.size() || curImage < 1
                error('curImage index invalid');
            end
            self.curImage = curImage;
        end
    end
end
