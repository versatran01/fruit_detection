classdef DetectionTester < handle
    %DETECTIONTESTER Class for testing detection against labeled dataset.
    
    properties
        % inputs
        dataset
        detector
        viz = true;
        % current state
        curImage = 1;
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
                if sel(4) ~= 1
                    % only plot fruit selections
                    continue;
                end
                points = createCirclePoints(sel(1:2), sel(3));
                self.hSelections(i) = plot(points(:,1),points(:,2));
                set(self.hSelections(i),'LineWidth',2);
                set(self.hSelections(i),'Color',[1 0 0]);
            end
        end
        
        function plotDetections(self, detections)
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
                set(self.hDetections(i),'Color',[0 0 1]);
            end
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
            
            if self.viz
                self.plotImage(image, mask);
                self.plotSelections(selections);
                self.plotDetections(bbox);
            end
        end
    end
end
