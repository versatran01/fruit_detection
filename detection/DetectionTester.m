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
                set(self.hFig,'Name','Detection Tester');
                self.hPlots(1) = subplot(1,2,1);
                self.hImage = imshow(image);
                self.hPlots(2) = subplot(1,2,2);
                self.hMask = imshow(mask);
            else
                % update old plots
                set(0,'CurrentFigure', self.hFig);
                set(self.hImage, 'CData', image);
                set(self.hMask, 'CData', mask);
            end
        end
        function plotSelections(self, selections)
        end
        function plotDetections(self, detections)
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
                
            end
        end
    end
end
