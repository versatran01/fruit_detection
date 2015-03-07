classdef DetectionTester < handle
    %DETECTIONTESTER Class for testing detection against labeled dataset.
    
    properties
        % inputs
        dataset
        detector
        viz = true;
        % current state
        curImage = 1;
        metrics = [];
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
                linkaxes(self.hPlots);
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
        
        function plotDetections(self, CC, valid)
            detections = CC.BoundingBox();
            if ~isempty(self.hDetections)
                delete(self.hDetections);
                self.hDetections = [];
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
                self.hDetections(end+1) = h;
                
                % now draw circles for individual fruit
                circ = CC.circles{i};
                if ~isempty(circ)
                    for j=1:size(circ,1)
                        pts = createCirclePoints(circ(j,1:2),...
                            circ(j,3), 20);
                        h = plot(pts(:,1), pts(:,2));
                        set(h,'LineWidth',2);
                        set(h,'Color',[1 0.1 0.75]);
                        self.hDetections(end+1) = h;
                    end
                end
            end
        end
        
        function [valid] = updateStats(self, selections, CC)
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
                predicted = size(CC.circles{i}, 1);
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
            self.curImage = self.curImage+1;
            idx = self.curImage;
            image = self.dataset.images{idx};
            % user selections for this image
            selections = self.dataset.selections{idx};
            % run detector on next image
            CC = self.detector(image);
            valid = self.updateStats(selections, CC);
            if self.viz
                self.plotImage(image, CC.image);
                self.plotSelections(selections);
                self.plotDetections(CC, valid);
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
